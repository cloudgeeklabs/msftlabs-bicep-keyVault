// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault to lock.')
param keyVaultName string

@description('Optional. The lock level to apply.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param lockLevel string = 'CanNotDelete'

@description('Optional. Notes describing why the lock was applied.')
param lockNotes string = 'Prevents accidental deletion of production Key Vault.'

// ============ //
// Resources    //
// ============ //

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Apply resource lock to Key Vault
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.authorization/locks
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${keyVaultName}-lock'
  scope: keyVault
  properties: {
    level: lockLevel
    notes: lockNotes
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the lock.')
output resourceId string = lock.id

@description('The name of the lock.')
output name string = lock.name

@description('The lock level applied.')
output level string = lock.properties.level
