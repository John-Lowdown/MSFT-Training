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

var trustedVnetAddressPrefix = '10.50.0.0/24'
var trustedSubnetAddressPrefix = '10.50.0.0/26'

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

// A small VNet whose one subnet has a SERVICE ENDPOINT for Microsoft.Storage —
// a second, distinct network-ACL mechanism alongside the ipRules above, and a
// different (older, simpler) mechanism than the private endpoint Lab 11
// deploys. A service endpoint does NOT give the storage account a private IP
// address inside this VNet the way Lab 11's private endpoint does — the
// storage account keeps its normal public endpoint and public IP the whole
// time. What a service endpoint actually does: it extends this VNet's
// identity onto Azure's backbone network for the Microsoft.Storage service
// specifically, so traffic leaving snet-trusted for the storage account's
// public endpoint gets tagged as "from this VNet/subnet" instead of "from some
// public IP" — which is what lets the virtualNetworkRules entry below
// allow-list it by subnet ID rather than by IP address. Traffic still
// physically traverses the storage account's public endpoint; a service
// endpoint only changes how that traffic is *identified and authorized*,
// while a private endpoint changes the network *path* itself.
resource trustedVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-az104lab04-trusted'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        trustedVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-trusted'
        properties: {
          addressPrefix: trustedSubnetAddressPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
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
      // Service endpoint rule — coexists with the IP rule above. Both are
      // evaluated the same way: an allow-list checked before defaultAction:
      // Deny kicks in.
      virtualNetworkRules: [
        {
          id: trustedVnet.properties.subnets[0].id
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
      // Kept identical to the first pass above — networkAcls isn't part of
      // what this second pass changes, only the encryption block is.
      virtualNetworkRules: [
        {
          id: trustedVnet.properties.subnets[0].id
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
output trustedSubnetId string = trustedVnet.properties.subnets[0].id
