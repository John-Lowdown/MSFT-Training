// AZ-104 Lab 14: Azure Backup — Recovery Services Vault & VM Restore
// Domain: Monitor and maintain Azure resources — Implement backup and recovery
// Cost: $0 for this deploy — the vault and backup policy carry no charge on their own.
//       Cost only shows up if you do the optional manual task of enabling backup on a real
//       VM: roughly a couple of cents per GB-month of backed-up data, cheap for a short demo.
//       The optional Site Recovery capstone task is NOT cheap if left running — see the
//       README's manual tasks section before attempting it.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az104-lab14 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('UTC time-of-day the daily backup job runs, as an ISO 8601 timestamp (only the time-of-day portion matters)')
param dailyBackupTimeUtc string = '2024-01-01T23:00:00Z'

@description('Number of days a daily backup point is retained')
@minValue(7)
@maxValue(9999)
param retentionDays int = 7

// Standard SKU vaults support geo-redundant storage for backup data by default and are the
// practical default for anything beyond the free tier's limits — RS0 is the only other
// option and is effectively legacy at this point.
resource vault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: 'rsv-az104lab14'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
  tags: {
    course: 'AZ-104'
    lab: 'lab14-backup-recovery'
  }
}

// A backup policy is authored once (schedule + retention) and reused across every VM you
// later protect with it — the same "define once, apply broadly" shape as an Azure Policy
// definition (Lab 02), just in the data-protection domain instead of governance.
//
// This resource is genuinely Bicep-authorable and deployed here. What is deliberately NOT
// in this file is the VM-to-vault protection association (a "protectedItem") — that's a
// data-plane operation driven by the portal's Backup wizard or `az backup protection
// enable-for-vm`, not a clean standalone ARM resource, so it lives in the README's manual
// tasks instead.
resource dailyVmPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  parent: vault
  name: 'policy-az104lab14-daily'
  properties: {
    backupManagementType: 'AzureIaasVM'
    timeZone: 'UTC'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        dailyBackupTimeUtc
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          dailyBackupTimeUtc
        ]
        retentionDuration: {
          count: retentionDays
          durationType: 'Days'
        }
      }
    }
    // Lets an on-demand backup be retained for a short window as an "instant restore
    // point" without waiting on the full backup-to-vault pipeline — required by the
    // AzureIaasVM policy schema, not optional.
    instantRpRetentionRangeInDays: 2
  }
}

output vaultName string = vault.name
output vaultId string = vault.id
output backupPolicyName string = dailyVmPolicy.name
