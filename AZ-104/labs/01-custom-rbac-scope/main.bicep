// AZ-104 Lab 01: Custom RBAC Roles & Scope Hierarchy
// Domain: Manage Azure identities and governance — Manage access to Azure resources
// Cost: $0 — role definitions and role assignments carry no charge.
//
// Deploy at SUBSCRIPTION scope (custom role definitions are typically defined
// at subscription or management-group scope so they're reusable across many
// resource groups, even though this lab only assigns the role to one RG):
//   az deployment sub create --location eastus --template-file main.bicep \
//     --parameters principalId=<your-object-id>

targetScope = 'subscription'

@description('Azure region for the resource group created by this lab')
param location string = deployment().location

@description('Object ID of the user, group, or service principal to assign roles to. Get your own signed-in user: az ad signed-in-user show --query id -o tsv')
param principalId string

@description('Principal type — needed by Azure so the role-assignment engine doesn\'t have to guess (guessing is what causes assignment delays/failures for groups and service principals)')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param principalType string = 'User'

var roleDefinitionGuid = guid(subscription().id, 'az104-lab01-storage-operator')

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'rg-az104-lab01'
  location: location
  tags: {
    course: 'AZ-104'
    lab: 'lab01-custom-rbac-scope'
  }
}

// A custom role narrower than any single built-in role: it can read, write,
// and list storage account keys, but it deliberately cannot delete storage
// accounts. Built-in "Storage Account Contributor" grants delete too — this
// role exists specifically to demonstrate narrowing beyond what a built-in
// role offers, which is the whole reason custom roles exist.
// assignableScopes is the subscription itself (not this one resource group),
// because custom roles are meant to be defined once and reused at whatever
// scope an assignment later targets.
resource customRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefinitionGuid
  properties: {
    roleName: 'AZ-104 Lab 01 Storage Operator'
    description: 'Can read, write, and list keys for storage accounts, but cannot delete them.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Storage/storageAccounts/read'
          'Microsoft.Storage/storageAccounts/write'
          'Microsoft.Storage/storageAccounts/listkeys/action'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

// Built-in Reader — assigned alongside the custom role so students can
// compare a built-in role's JSON against the custom one in "Check access".
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // built-in Reader
  scope: tenant()
}

resource customRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(rg.id, principalId, customRole.id)
  scope: rg
  properties: {
    roleDefinitionId: customRole.id
    principalId: principalId
    principalType: principalType
  }
}

resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(rg.id, principalId, readerRoleDefinition.id)
  scope: rg
  properties: {
    roleDefinitionId: readerRoleDefinition.id
    principalId: principalId
    principalType: principalType
  }
}

output resourceGroupName string = rg.name
output customRoleDefinitionId string = customRole.id
output customRoleAssignmentId string = customRoleAssignment.id
output readerRoleAssignmentId string = readerRoleAssignment.id
