// AZ-900 Lab 2: Storage Redundancy (LRS / ZRS / GRS)
// Domain: Core Services — Storage
// Cost: near-$0 — a handful of empty storage accounts on pay-as-you-go pricing;
//       delete immediately after the demo to avoid any charge beyond pennies.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az900-lab02 --template-file main.bicep

@description('Base name for the storage accounts (must be globally unique; a suffix is appended per SKU)')
@minLength(3)
@maxLength(11)
param storageBaseName string = 'az900lab02'

@description('Azure region')
param location string = resourceGroup().location

// Three accounts side-by-side so students can compare redundancy tiers directly
// in the portal: Storage account -> Data protection / Redundancy.
var redundancyOptions = [
  {
    suffix: 'lrs'
    sku: 'Standard_LRS' // Locally Redundant Storage: 3 copies, one datacenter
  }
  {
    suffix: 'zrs'
    sku: 'Standard_ZRS' // Zone-Redundant Storage: 3 copies across availability zones in-region
  }
  {
    suffix: 'grs'
    sku: 'Standard_GRS' // Geo-Redundant Storage: LRS in primary region + async copy to paired region
  }
]

resource storageAccounts 'Microsoft.Storage/storageAccounts@2023-05-01' = [
  for opt in redundancyOptions: {
    name: '${storageBaseName}${opt.suffix}'
    location: location
    kind: 'StorageV2'
    sku: {
      name: opt.sku
    }
    properties: {
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      supportsHttpsTrafficOnly: true
    }
    tags: {
      course: 'AZ-900'
      lab: 'lab02-storage-redundancy'
    }
  }
]

output storageAccountNames array = [for i in range(0, length(redundancyOptions)): storageAccounts[i].name]
output redundancyTiersDeployed array = [for opt in redundancyOptions: opt.sku]
