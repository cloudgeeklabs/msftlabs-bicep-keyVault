// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault to assign roles on.')
param keyVaultName string

@description('Required. Array of role assignments to create.')
param roleAssignments roleAssignmentType[]

// ============ //
// Resources    //
// ============ //

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Deploy role assignments for the Key Vault
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.authorization/roleassignments
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  // guid() ensures idempotency - same inputs always produce same name
  name: guid(keyVault.id, assignment.principalId, assignment.roleDefinitionIdOrName)
  scope: keyVault
  properties: {
    // Built-in roles: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionIdOrName)
    principalId: assignment.principalId
    principalType: assignment.?principalType ?? 'ServicePrincipal'
  }
}]

// ============ //
// Outputs      //
// ============ //

@description('The resource IDs of the role assignments.')
output resourceIds array = [for (assignment, i) in roleAssignments: roleAssignment[i].id]

@description('The names of the role assignments.')
output names array = [for (assignment, i) in roleAssignments: roleAssignment[i].name]

// ============== //
// Type Definitions //
// ============== //

@description('Role assignment configuration.')
type roleAssignmentType = {
  @description('The principal ID (object ID) of the identity to assign the role to.')
  principalId: string

  @description('The role definition ID or built-in role name to assign.')
  roleDefinitionIdOrName: string

  @description('The type of principal.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ManagedIdentity')?
}
