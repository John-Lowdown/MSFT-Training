// AZ-900 Lab 4: RBAC Role Assignment
// Domain: Identity, Governance, Compliance
// Cost: $0 — role assignments carry no charge
//
// IMPORTANT: unlike the other labs, this one needs a real principal (user, group,
// or service principal) object ID to assign a role to. Get yours with:
//   az ad signed-in-user show --query id -o tsv
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az900-lab04 --template-file main.bicep \
//     --parameters principalId=<your-object-id>

@description('Object ID of the user, group, or service principal to assign the role to')
param principalId string

@description('Type of the principal above — required by Azure to avoid AAD replication-lag errors')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'User'

// Well-known built-in role definition IDs (these GUIDs are the same in every Azure tenant)
var roleDefinitions = {
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  StorageBlobDataReader: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

@description('Which built-in role to assign for this demo')
@allowed([
  'Reader'
  'Contributor'
  'StorageBlobDataReader'
])
param roleToAssign string = 'Reader'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // name must be a deterministic GUID so re-running the deployment doesn't try to create a duplicate
  name: guid(resourceGroup().id, principalId, roleToAssign)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions[roleToAssign])
  }
}

output assignedRole string = roleToAssign
output scopedTo string = resourceGroup().id
