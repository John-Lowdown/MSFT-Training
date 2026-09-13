// AZ-900 Lab 5: Budgets & Cost Alerts
// Domain: Pricing, SLA & Lifecycle
// Cost: $0 — budgets are a monitoring construct, not a billable resource
//
// Deploy at SUBSCRIPTION scope (budgets are a subscription-level construct):
//   az deployment sub create --location eastus --template-file main.bicep \
//     --parameters contactEmail=you@example.com

targetScope = 'subscription'

@description('Name of the budget')
param budgetName string = 'az900-lab05-monthly-budget'

@description('Monthly budget amount in your billing currency')
param budgetAmount int = 50

@description('Email address to notify at each threshold')
param contactEmail string

@description('Start date for the budget, first of the current month (YYYY-MM-01T00:00:00Z)')
param startDate string = '${utcNow('yyyy-MM')}-01T00:00:00Z'

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      Actual_50Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      Actual_80Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [
          contactEmail
        ]
      }
      Forecasted_100Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          contactEmail
        ]
      }
    }
  }
}

output budgetId string = budget.id
output thresholds array = ['50% actual', '80% actual', '100% forecasted']
