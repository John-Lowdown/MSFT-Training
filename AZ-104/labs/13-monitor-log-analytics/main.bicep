// AZ-104 Lab 13: Log Analytics, Diagnostic Settings & KQL
// Domain: Monitor and maintain Azure resources — Monitor resources in Azure
// Cost: near-$0 for this deploy — an empty storage account, a Log Analytics workspace with
//       default PerGB2018 pricing, a free action group, and a platform metric alert (platform
//       metric alerts carry no charge). Log Analytics ingestion itself is billed per GB, but a
//       new, low-volume workspace like this one typically stays within the free daily data
//       allotment for a short demo. The one piece of this lab that CAN add real ongoing cost is
//       the optional flow-log manual task below — disable it right after trying it.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az104-lab13 --template-file main.bicep \
//     --parameters contactEmail=you@example.com

@description('Name for the storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'az104lab13${uniqueString(resourceGroup().id)}'

@description('Azure region')
param location string = resourceGroup().location

@description('Email address the action group notifies when the alert fires')
param contactEmail string

@description('Log Analytics data retention in days. 30 is the minimum for the paid PerGB2018 tier and is more than enough for a short demo.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Transaction count threshold (over the evaluation window) that triggers the alert')
param transactionThreshold int = 1000

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-az104lab13'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab13-monitor-log-analytics'
  }
}

// A simple, genuinely boring target resource for diagnostics — the teaching point of this
// lab is the monitoring plumbing around it, not the storage account itself.
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
    course: 'AZ-104'
    lab: 'lab13-monitor-log-analytics'
  }
}

// The storage account's blob service, referenced as an EXISTING resource rather than
// declared fresh — Azure creates the 'default' blob service automatically the moment the
// storage account exists. We only need a symbolic reference here so the diagnostic setting
// below can scope itself to it: blob request logs (StorageBlobLogs) are only available at
// this sub-resource level, not at the storage account level itself.
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  parent: storageAccount
  name: 'default'
}

// Diagnostic setting #1: account-level METRICS (Transaction) -> Log Analytics.
// This is the "numbers over time" half of monitoring — it lands in the AzureMetrics table.
//
// API version note: 2021-05-01-preview is intentional, not a typo. Microsoft.Insights
// diagnosticSettings has stayed on a -preview suffix for years even though the resource type
// is fully GA and used in production Azure-wide — there has never been a stable-suffix
// replacement published. This is one of a handful of long-lived "permanently preview-named"
// Azure API versions worth knowing about rather than assuming is a mistake.
resource storageMetricsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-az104lab13-metrics'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// Diagnostic setting #2: blob service LOGS -> Log Analytics.
// This is the "structured records" half of monitoring — it lands in the StorageBlobLogs
// table and is what the KQL sample query in the lab README reads from.
resource blobLogsDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-az104lab13-blob-logs'
  scope: blobService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-az104lab13'
  location: 'global'
  properties: {
    groupShortName: 'az104lab13'
    enabled: true
    emailReceivers: [
      {
        name: 'PrimaryEmail'
        emailAddress: contactEmail
        useCommonAlertSchema: true
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab13-monitor-log-analytics'
  }
}

// Reuses the AZ-900 Lab 7 pattern (a threshold on a storage metric, wired to an action
// group) deliberately, so this lab's metrics half looks familiar while the logs half
// (everything above) is the genuinely new material.
resource transactionsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-az104lab13-transactions'
  location: 'global'
  properties: {
    description: 'Fires when storage account transaction count exceeds the configured threshold over the evaluation window.'
    severity: 3
    enabled: true
    scopes: [
      storageAccount.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT1H'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'TransactionsThreshold'
          metricName: 'Transactions'
          metricNamespace: 'Microsoft.Storage/storageAccounts'
          operator: 'GreaterThan'
          threshold: transactionThreshold
          timeAggregation: 'Total'
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

output workspaceName string = logAnalyticsWorkspace.name
output workspaceId string = logAnalyticsWorkspace.id
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output actionGroupId string = actionGroup.id
output alertName string = transactionsAlert.name
