// AZ-900 Lab 8: Azure Policy
// Domain: Azure Management & Governance — Azure Policy
// Cost: $0 — policy definitions and assignments carry no charge on their own.
//
// Deploy at SUBSCRIPTION scope (policy definitions live above resource groups):
//   az deployment sub create --location eastus --template-file main.bicep

targetScope = 'subscription'

@description('Enable or disable enforcement. Deny blocks non-compliant deployments; Audit only flags them; Disabled turns the policy off without deleting it.')
@allowed([
  'Deny'
  'Audit'
  'Disabled'
])
param policyEffect string = 'Deny'

// This is the exact example Microsoft's own AZ-900 study guide uses when it
// contrasts Azure Policy against RBAC: "Deny storage accounts with public
// blob access." A resource's configuration is denied regardless of who is
// deploying it or what RBAC role they hold — that's the whole point of Policy.
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az900-lab08-deny-public-blob-access'
  properties: {
    displayName: 'AZ-900 Lab 8: Deny public blob access on storage accounts'
    description: 'Denies (or audits) storage accounts that allow public blob access.'
    policyType: 'Custom'
    mode: 'Indexed'
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Deny'
        allowedValues: [
          'Deny'
          'Audit'
          'Disabled'
        ]
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
      }
    }
    // Policy rules are written in Azure Policy's own language, not Bicep —
    // the "[parameters('effect')]" syntax below is Policy's parameter
    // reference, evaluated by the Policy engine at assignment time.
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess'
            equals: true
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az900-lab08-assignment'
  properties: {
    displayName: 'AZ-900 Lab 8: Deny public blob access (assignment)'
    policyDefinitionId: policyDefinition.id
    parameters: {
      effect: {
        value: policyEffect
      }
    }
  }
}

output policyDefinitionId string = policyDefinition.id
output policyAssignmentId string = policyAssignment.id
output effectApplied string = policyEffect
