// AZ-104 Lab 05: Storage Lifecycle, Versioning & Object Replication
// Domain: Implement and manage storage — Configure and manage storage accounts /
//         Configure Azure Files and Blob Storage
// Cost: near-$0 — two mostly-empty storage accounts and an unused 5 GiB file share quota.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az104-lab05 --template-file main.bicep

@description('Name for the source storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)')
@minLength(3)
@maxLength(24)
param sourceStorageAccountName string = 'az104l05src${uniqueString(resourceGroup().id)}'

@description('Name for the destination storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)')
@minLength(3)
@maxLength(24)
param destStorageAccountName string = 'az104l05dst${uniqueString(resourceGroup().id)}'

@description('Name of the blob container replicated from source to destination, and tiered/deleted by the lifecycle policy')
param containerName string = 'lab05data'

@description('Name of the Azure Files share created on the source account')
param fileShareName string = 'lab05share'

@description('Azure region')
param location string = resourceGroup().location

resource sourceStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: sourceStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    // Microsoft Entra Kerberos authentication for Azure Files SMB access.
    // 'AADKERB' is the ARM enum value for Entra-ID-based Kerberos (the option
    // that doesn't require a domain controller or Entra Domain Services, vs.
    // 'AD' for on-prem AD DS or 'AADDS' for Entra Domain Services) — this
    // matches what `az storage account update --enable-files-aadkerb true`
    // sets under the hood. This property alone only enables the capability on
    // the storage account side; it does NOT by itself grant any Entra user or
    // group permission to actually mount the share over SMB. That's a
    // separate RBAC step — assigning the built-in "Storage File Data SMB
    // Share Contributor" or "...Reader" role (at the file share or storage
    // account scope) to whichever Entra identities should connect, the same
    // role-assignment pattern used for the CMK identity in Lab 04. This lab
    // deliberately stops short of adding that role assignment — a specific
    // demo principal for it isn't something this template can default the
    // way Lab 01's `principalId` param does, since there's no natural
    // "whoever runs this lab" identity to assign it to without asking for
    // input the deploy command above doesn't currently require. A real
    // deployment would add a `Microsoft.Authorization/roleAssignments`
    // resource here, scoped to `fileShare`, once you know which identities
    // need SMB access.
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'AADKERB'
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab05-storage-lifecycle-protection'
    role: 'replication-source'
  }
}

resource destStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: destStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab05-storage-lifecycle-protection'
    role: 'replication-destination'
  }
}

// Versioning and change feed are prerequisites for object replication, not
// independent features — both accounts need both turned on before a
// replication policy between them will deploy successfully. Soft delete for
// blobs and containers rides along here too, since it's configured on the
// same blobServices resource.
resource sourceBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sourceStorageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource destBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: destStorageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource sourceContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: sourceBlobServices
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

resource destContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: destBlobServices
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

// Lifecycle management runs on Azure's own schedule (roughly once every 24
// hours), not instantly on a timer you control — nothing here will visibly
// fire during a short classroom demo. Scoped with a prefix filter so it only
// touches blobs under containerName/logs/, not the whole account.
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-05-01' = {
  parent: sourceStorageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'tier-cool-then-delete'
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                '${containerName}/logs/'
              ]
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
                delete: {
                  daysAfterModificationGreaterThan: 180
                }
              }
            }
          }
        }
      ]
    }
  }
  dependsOn: [
    sourceContainer
  ]
}

// Object replication's policy ID must be identical on both the source and
// destination account — Azure does not auto-match two differently-named
// policies. This shared variable is how this template guarantees that instead
// of relying on someone typing the same GUID twice by hand.
var objectReplicationPolicyId = guid(sourceStorageAccount.id, destStorageAccount.id, 'lab05-replication')

// Azure's real-world ordering requirement: the destination policy has to be
// created first so Azure can assign each rule a ruleId; the source policy
// then has to reference that same ruleId, not invent its own. Rather than
// hand-typing a ruleId, sourceReplicationPolicy below references
// destReplicationPolicy.properties.rules directly, which carries the
// generated ruleId along automatically once it exists.
resource destReplicationPolicy 'Microsoft.Storage/storageAccounts/objectReplicationPolicies@2023-05-01' = {
  parent: destStorageAccount
  name: objectReplicationPolicyId
  properties: {
    sourceAccount: sourceStorageAccount.name
    destinationAccount: destStorageAccount.name
    rules: [
      {
        sourceContainer: containerName
        destinationContainer: containerName
      }
    ]
  }
  dependsOn: [
    sourceContainer
    destContainer
    sourceBlobServices
    destBlobServices
  ]
}

resource sourceReplicationPolicy 'Microsoft.Storage/storageAccounts/objectReplicationPolicies@2023-05-01' = {
  parent: sourceStorageAccount
  name: objectReplicationPolicyId
  properties: {
    sourceAccount: sourceStorageAccount.name
    destinationAccount: destStorageAccount.name
    rules: destReplicationPolicy.properties.rules
  }
}

// Azure Files and Blob Storage are genuinely different services sharing one
// storage account, not the same thing under a different name — this share
// lives on the source account purely to demonstrate that, with no other
// relationship to the replication/lifecycle resources above.
resource sourceFileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: sourceStorageAccount
  name: 'default'
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: sourceFileServices
  name: fileShareName
  properties: {
    shareQuota: 5
    accessTier: 'Cool'
    enabledProtocols: 'SMB'
  }
}

output sourceStorageAccountName string = sourceStorageAccount.name
output destStorageAccountName string = destStorageAccount.name
output containerName string = containerName
output objectReplicationPolicyId string = objectReplicationPolicyId
output fileShareName string = fileShare.name
