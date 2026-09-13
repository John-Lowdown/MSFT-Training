// AZ-900 Lab 7: Resource Locks & Monitor Alerts
// Domain: Azure Management & Governance — Resource Locks / Azure Monitor
// Cost: near-$0 — an empty storage account, a free action group, and a platform
//       metric alert (platform metric alerts carry no charge). Delete right after the demo.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az900-lab07 --template-file main.bicep \
//     --parameters contactEmail=you@example.com

@description('Name for the storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'az900lab07${uniqueString(resourceGroup().id)}'

@description('Azure region')
param location string = resourceGroup().location

@description('Email address the action group notifies when the alert fires')
param contactEmail string

@description('UsedCapacity threshold in bytes that triggers the alert (default: 5 GB)')
param usedCapacityThresholdBytes int = 5368709120

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
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
    course: 'AZ-900'
    lab: 'lab07-resource-locks-monitor-alerts'
  }
}

// CanNotDelete blocks deletion for EVERYONE touching this resource, including
// subscription Owners — it is not an RBAC concept, and it has to be removed
// explicitly before this storage account (or its resource group) can be deleted.
resource cannotDeleteLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lab07-cannot-delete'
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'AZ-900 Lab 7 demo lock — remove before deleting this resource group.'
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-az900-lab07'
  location: 'global'
  properties: {
    groupShortName: 'az900lab07'
    enabled: true
    emailReceivers: [
      {
        name: 'PrimaryEmail'
        emailAddress: contactEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// Fires when the storage account's UsedCapacity metric averages above the
// threshold over the evaluation window — wired to the action group above.
resource usedCapacityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-az900-lab07-usedcapacity'
  location: 'global'
  properties: {
    description: 'Fires when storage account used capacity exceeds the configured threshold.'
    severity: 3
    enabled: true
    scopes: [
      storageAccount.id
    ]
    evaluationFrequency: 'PT1H'
    windowSize: 'PT6H'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'UsedCapacityThreshold'
          metricName: 'UsedCapacity'
          metricNamespace: 'Microsoft.Storage/storageAccounts'
          operator: 'GreaterThan'
          threshold: usedCapacityThresholdBytes
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output storageAccountName string = storageAccount.name
output lockName string = cannotDeleteLock.name
output actionGroupId string = actionGroup.id
output alertThresholdBytes int = usedCapacityThresholdBytes
