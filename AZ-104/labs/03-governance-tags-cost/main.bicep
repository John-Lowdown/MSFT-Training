// AZ-104 Lab 03: Resource Locks, Cost Budgets & Resource Moves
// Domain: Manage Azure identities and governance — Manage Azure subscriptions
//         and governance (resource group management, cost management)
// Cost: near-$0 — two empty storage accounts; budgets and action groups carry
//       no charge on their own. Delete right after the demo.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab03 --location eastus
//   az deployment group create --resource-group rg-az104-lab03 --template-file main.bicep \
//     --parameters contactEmail=you@example.com

@description('Azure region')
param location string = resourceGroup().location

@description('Email address the action group notifies when a budget threshold is crossed')
param contactEmail string

@description('Monthly budget amount in USD')
param budgetAmount int = 50

// utcNow can only be used as a parameter default — it's deliberately
// non-deterministic, so Bicep restricts it to this one spot. Rounded to the
// first of the current month, which Microsoft.Consumption/budgets requires.
@description('First day of the budget\'s starting month, in YYYY-MM-DD format')
param budgetStartDate string = utcNow('yyyy-MM-01')

var uniqueSuffix = uniqueString(resourceGroup().id)
// dateTimeAdd is deterministic given an input, so it's fine to use outside a
// parameter default — this pushes the budget's end date 10 years out.
var budgetEndDate = dateTimeAdd(budgetStartDate, 'P10Y')
var lockedStorageAccountName = 'az104lab03lk${uniqueSuffix}'
var unlockedStorageAccountName = 'az104lab03mv${uniqueSuffix}'

// This one gets a CanNotDelete lock — used later in the manual tasks to show
// that a lock blocks az resource move, not just delete.
resource lockedStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: lockedStorageAccountName
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
    lab: 'lab03-governance-tags-cost'
    moveTest: 'locked'
  }
}

// Deliberately unlocked — the manual tasks move this one successfully after
// the locked one fails, to contrast the two outcomes directly.
resource unlockedStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: unlockedStorageAccountName
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
    lab: 'lab03-governance-tags-cost'
    moveTest: 'unlocked'
  }
}

// CanNotDelete blocks more than deletes — it blocks moves too. That's the
// exam-tested detail this lab's manual tasks make concrete with a live,
// failing az resource move command.
resource cannotDeleteLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lab03-cannot-delete'
  scope: lockedStorageAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'AZ-104 Lab 03 demo lock — remove before deleting or moving this storage account.'
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-az104-lab03'
  location: 'global'
  properties: {
    groupShortName: 'az104lab03'
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
    lab: 'lab03-governance-tags-cost'
  }
}

// Two thresholds against two different signals — 80% of actual spend (a
// warning while it's still happening) and 100% of forecasted spend (a
// heads-up before the month even ends) — more realistic than a single
// threshold and scoped to this resource group rather than the whole
// subscription.
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'budget-az104-lab03'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: budgetEndDate
    }
    filter: {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroup().name
        ]
      }
    }
    notifications: {
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: []
        contactGroups: [
          actionGroup.id
        ]
      }
      Forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: []
        contactGroups: [
          actionGroup.id
        ]
      }
    }
  }
}

output lockedStorageAccountName string = lockedStorageAccount.name
output unlockedStorageAccountName string = unlockedStorageAccount.name
output lockName string = cannotDeleteLock.name
output actionGroupId string = actionGroup.id
output budgetName string = budget.name
