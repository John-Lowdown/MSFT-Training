// AZ-900 Lab 1: Resource Groups & Tagging
// Domain: Cloud Concepts / Governance
// Cost: $0 (resource groups are free; no billable resources deployed)
//
// Deploy at SUBSCRIPTION scope:
//   az deployment sub create --location <region> --template-file main.bicep --parameters environment=dev costCenter=IT-Training

targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string = 'rg-az900-lab01'

@description('Azure region for the resource group')
param location string = 'eastus'

@description('Environment tag value')
param environment string = 'dev'

@description('Cost center tag value')
param costCenter string = 'IT-Training'

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environment
    costCenter: costCenter
    course: 'AZ-900'
    lab: 'lab01-resource-groups-tagging'
    managedBy: 'bicep'
  }
}

output resourceGroupId string = rg.id
output appliedTags object = rg.tags
