// AZ-104 Lab 02: Azure Policy — Initiatives & Remediation
// Domain: Manage Azure identities and governance — Implement and manage Azure Policy
// Cost: $0 — policy definitions, initiatives, assignments, and remediation tasks
//       carry no charge on their own.
//
// Deploy at SUBSCRIPTION scope (policy and initiative definitions live above
// resource groups):
//   az deployment sub create --location eastus --template-file main.bicep

targetScope = 'subscription'

@description('Resource group the initiative is assigned to and the remediation task targets')
param location string = deployment().location

@description('Required tag this lab enforces/auto-appends on resource groups that are missing it')
param requiredTagName string = 'costCenter'

@description('Value written onto a resource group by the Modify policy when the tag is missing')
param requiredTagValue string = 'unassigned'

// Well-known built-in "Tag Contributor" role — Modify/DeployIfNotExists effects
// need a managed identity with write permissions to actually remediate, unlike
// Deny/Audit which only evaluate and never write anything themselves.
var tagContributorRoleId = '4a9ae827-6dc8-4573-8ac7-8239d42aa03f'

// Well-known built-in policy: "Require a tag on resource groups".
var requireTagBuiltInPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'rg-az104-lab02'
  location: location
  tags: {
    course: 'AZ-104'
    lab: 'lab02-azure-policy-initiatives'
  }
}

// A Modify policy: instead of just blocking (Deny) or flagging (Audit) a
// missing tag, it auto-appends the tag with a default value. Modify effects
// require roleDefinitionIds on the definition itself, naming the roles the
// policy's managed identity will be granted at assignment time.
resource modifyTagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az104-lab02-modify-costcenter-tag'
  properties: {
    displayName: 'AZ-104 Lab 02: Append costCenter tag to resource groups'
    description: 'Adds a default costCenter tag to resource groups that do not already have one.'
    policyType: 'Custom'
    // Mode must be 'All', not 'Indexed', because this rule targets resource
    // groups themselves. 'Indexed' only evaluates resource types that support
    // tags/location and specifically skips resource groups and subscriptions —
    // a common gotcha when a tagging policy looks like it should use Indexed.
    mode: 'All'
    parameters: {
      tagName: {
        type: 'String'
        defaultValue: requiredTagName
        metadata: {
          displayName: 'Tag Name'
          description: 'Name of the tag to require/append'
        }
      }
      tagValue: {
        type: 'String'
        defaultValue: requiredTagValue
        metadata: {
          displayName: 'Tag Value'
          description: 'Default value written when the tag is missing'
        }
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: 'false'
          }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            subscriptionResourceId('Microsoft.Authorization/roleDefinitions', tagContributorRoleId)
          ]
          operations: [
            {
              operation: 'add'
              field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
              value: '[parameters(\'tagValue\')]'
            }
          ]
        }
      }
    }
  }
}

// An initiative groups the new Modify policy with a built-in Audit policy —
// real organizations assign dozens of related policies as one initiative
// rather than managing each assignment individually.
resource initiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'az104-lab02-tagging-initiative'
  properties: {
    displayName: 'AZ-104 Lab 02: Resource group tagging initiative'
    description: 'Groups a custom Modify policy with the built-in "Require a tag on resource groups" policy.'
    policyType: 'Custom'
    policyDefinitions: [
      {
        policyDefinitionReferenceId: 'modifyCostCenterTag'
        policyDefinitionId: modifyTagPolicy.id
        parameters: {
          tagName: {
            value: requiredTagName
          }
          tagValue: {
            value: requiredTagValue
          }
        }
      }
      {
        policyDefinitionReferenceId: 'requireTagBuiltIn'
        policyDefinitionId: requireTagBuiltInPolicyId
        parameters: {
          tagName: {
            value: requiredTagName
          }
        }
      }
    ]
  }
}

// SystemAssigned identity is required here: Modify needs write permission on
// the resources it remediates, which Deny/Audit assignments never need since
// they only evaluate at (or after) deployment time without writing anything.
resource initiativeAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az104-lab02-assignment'
  scope: rg
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'AZ-104 Lab 02: Tagging initiative assignment'
    policyDefinitionId: initiative.id
    parameters: {}
  }
}

// Grants the assignment's managed identity the permissions named in the
// Modify policy's roleDefinitionIds, scoped to the resource group it will
// remediate.
resource remediationRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(rg.id, initiativeAssignment.id, tagContributorRoleId)
  scope: rg
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', tagContributorRoleId)
    principalId: initiativeAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Deny/Audit enforce at (or after) deployment time and never need this —
// Modify/DeployIfNotExists only affect resources created or updated going
// forward, so a remediation task is what fixes resources that already
// existed before the policy was assigned.
resource remediation 'Microsoft.PolicyInsights/remediations@2021-10-01' = {
  name: 'az104-lab02-remediation'
  scope: rg
  properties: {
    policyAssignmentId: initiativeAssignment.id
    policyDefinitionReferenceId: 'modifyCostCenterTag'
    resourceDiscoveryMode: 'ReEvaluateCompliance'
  }
  dependsOn: [
    remediationRoleAssignment
  ]
}

output resourceGroupName string = rg.name
output policyDefinitionId string = modifyTagPolicy.id
output initiativeId string = initiative.id
output initiativeAssignmentId string = initiativeAssignment.id
output remediationTaskId string = remediation.id
