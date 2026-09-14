// AZ-104 Lab 04: Storage Security — SAS, Network Rules & Customer-Managed Keys
// Domain: Implement and manage storage — Configure access to storage
// Cost: near-$0 — an empty storage account and a Key Vault with one key.
//       Key Vault charges ~$0.03 per 10,000 operations; a short demo is negligible.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az104-lab04 --template-file main.bicep \
//     --parameters allowedClientIp=<your-public-ip>

@description('Name for the storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'az104lab04${uniqueString(resourceGroup().id)}'

@description('Name for the Key Vault (must be globally unique, 3-24 chars)')
@minLength(3)
@maxLength(24)
param keyVaultName string = 'az104lab04kv${substring(uniqueString(resourceGroup().id), 0, 6)}'

@description('Name of the customer-managed key created in the vault')
param keyName string = 'az104lab04cmkkey'

@description('Azure region')
param location string = resourceGroup().location

@description('Your own public IP address (single IP or CIDR), e.g. 203.0.113.5 — get it with: curl -s https://ifconfig.me. Added as the one allowed entry on the storage account firewall; without it, Deny blocks your own CLI/portal data-plane calls too.')
param allowedClientIp string

@description('Whether the Key Vault has purge protection enabled. Leave true to see the real-world behavior (a deleted vault cannot be purged early, full stop); set false only if you are redeploying this lab repeatedly and need to free up the vault name quickly during cleanup.')
param enablePurgeProtection bool = true

// Built-in "Key Vault Crypto Service Encryption User" — lets a principal (here,
// the storage account's own managed identity, not a human) wrap/unwrap keys for
// encryption-at-rest purposes without granting it broader key management rights.
var keyVaultCryptoServiceEncryptionUserRoleId = 'e147488a-f6f5-4113-8e2d-b22465e65bf6'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: enablePurgeProtection
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab04-storage-security-access'
  }
}

resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab04-storage-security-access'
  }
}

// First pass: identity exists, default Microsoft.Storage-managed encryption,
// network ACLs locked down to one IP. Deliberately NOT configured for CMK yet —
// the storage account's managed identity doesn't exist until this resource is
// created, so the role assignment below has to come after this, and the CMK
// encryption switch-over (storageAccountCmk, further down) has to come after
// that role assignment. This three-step order is the real Azure constraint,
// not a Bicep workaround: Azure will refuse to enable CMK encryption before the
// identity reading the key has been granted access to it.
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    // defaultAction: Deny blocks every request — portal, CLI, and data-plane
    // alike — except what's explicitly allowed below or from trusted Azure
    // services. This is a separate, stackable layer from SAS/RBAC: network
    // rules answer "can this request even reach the account," identity/token
    // checks answer "is this specific request authorized."
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        {
          value: allowedClientIp
          action: 'Allow'
        }
      ]
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab04-storage-security-access'
  }
}

// A resource authenticating to another resource, not a human — this is why
// enabling CMK needs a role assignment at all. Scoped to the vault only.
resource encryptionRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, storageAccount.id, keyVaultCryptoServiceEncryptionUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultCryptoServiceEncryptionUserRoleId)
    principalId: storageAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Second pass against the SAME storage account resource, gated on the role
// assignment above via an explicit dependsOn. This has to be a separate
// resource block: the role assignment needs storageAccount.identity.principalId
// to exist first, so folding the CMK switch-over into the resource above would
// create a circular dependency (identity -> role assignment -> encryption ->
// same resource that defines the identity).
resource storageAccountCmk 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        {
          value: allowedClientIp
          action: 'Allow'
        }
      ]
    }
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyvaulturi: keyVault.properties.vaultUri
        keyname: cmkKey.name
      }
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab04-storage-security-access'
  }
  dependsOn: [
    encryptionRoleAssignment
  ]
}

output storageAccountName string = storageAccountCmk.name
output storageAccountPrincipalId string = storageAccount.identity.principalId
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output cmkKeyName string = cmkKey.name
