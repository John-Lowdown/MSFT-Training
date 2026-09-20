// AZ-104 Lab 14: Azure Backup — Recovery Services Vault, Backup Vault & VM Restore
// Domain: Monitor and maintain Azure resources — Implement backup and recovery
// Cost: $0 for this deploy — both vault types and both backup policies carry no charge on
//       their own; nothing is actually protecting data yet, just defining where/how it would
//       be if you enabled it. Cost only shows up if you do the optional manual task of
//       enabling backup on a real VM (roughly a couple of cents per GB-month of backed-up
//       data) or actually protecting a storage account with the blob backup policy below
//       (similarly small, billed on backed-up data volume) — both cheap for a short demo.
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

// ---------------------------------------------------------------------------
// Azure Backup vault (Microsoft.DataProtection/backupVaults) — a SEPARATE
// resource type from the Recovery Services vault above, not a newer version
// of the same thing. Different resource provider namespace
// (Microsoft.DataProtection vs. Microsoft.RecoveryServices), different
// underlying backup stack, different portal experience. "Azure Backup" built
// on a Backup vault is the direction Microsoft is consolidating newer
// workload types toward — blobs, managed disks, PostgreSQL flexible server,
// and a growing list of others — but a Recovery Services vault remains what
// VM backup (and Site Recovery) actually use, which is exactly why this lab
// now deploys both rather than replacing one with the other. This is the
// literal "vault vs. vault" distinction the exam's own skill list names.
resource backupVault 'Microsoft.DataProtection/backupVaults@2023-11-01' = {
  name: 'bv-az104lab14'
  location: location
  // A system-assigned identity is what the vault later uses to reach the
  // resource it's protecting. Actually protecting a specific storage
  // account additionally requires granting this identity the
  // "Storage Account Backup Contributor" role on that account — a
  // data-plane/target-specific RBAC step, so (like enabling VM protection
  // above) it's left as a manual task rather than baked in here.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // LocallyRedundant is the minimal/cheapest datastore redundancy for a
    // demo vault; GeoRedundant is the other common option. datastoreType
    // 'VaultStore' is the operational-tier datastore blob backup uses.
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: 'LocallyRedundant'
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab14-backup-recovery'
  }
}

// A Backup vault's policy is a separate resource type AND a genuinely more
// complex schema than the Recovery Services vault's AzureIaasVM policy
// above. This one is written for BLOB backup specifically — operational
// (continuous, point-in-time-restore) backup of blob storage, the
// flagship, simplest workload type for the newer Backup vault.
//
// CONFIDENCE NOTE: the backupVault resource type/API version and the
// storageSettings shape above are well-documented and used here with
// confidence. The policyRules structure below — property names like
// `objectType`, `sourceDataStore`, `dataStoreType`, `AbsoluteDeleteOption`,
// and the fact that a minimal blob-operational-backup policy needs only a
// retention rule with NO scheduled trigger (because blob operational
// backup runs continuously in the background rather than on a schedule the
// way VM backup does) — reflects the documented shape as of this file's
// authoring, but this corner of the Microsoft.DataProtection schema is
// genuinely more obscure than the rest of this template and has shifted
// between API versions before. Run `az bicep build --file main.bicep` and,
// ideally, `az deployment group validate` against a real subscription
// before treating this policy resource as authoritative — don't take these
// property names on faith the way you safely can for the rest of this file.
resource blobBackupPolicy 'Microsoft.DataProtection/backupVaults/backupPolicies@2023-11-01' = {
  parent: backupVault
  name: 'policy-az104lab14-blob'
  properties: {
    objectType: 'BackupPolicy'
    datasourceTypes: [
      'Microsoft.Storage/storageAccounts/blobServices'
    ]
    policyRules: [
      {
        name: 'Default'
        objectType: 'AzureRetentionRule'
        isDefault: true
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${retentionDays}D'
            }
            sourceDataStore: {
              dataStoreType: 'OperationalStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
      }
    ]
  }
}

output vaultName string = vault.name
output vaultId string = vault.id
output backupPolicyName string = dailyVmPolicy.name
output backupVaultName string = backupVault.name
output backupVaultId string = backupVault.id
output blobBackupPolicyName string = blobBackupPolicy.name
