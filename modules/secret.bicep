// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault to store secrets in.')
param keyVaultName string

@description('Required. Array of secrets to create.')
param secrets secretType[]

// ============ //
// Resources    //
// ============ //

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Deploy secrets to Key Vault
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.keyvault/vaults/secrets
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in secrets: {
  parent: keyVault
  name: secret.name
  tags: secret.?tags ?? {}
  properties: {
    value: secret.value
    contentType: secret.?contentType ?? 'text/plain'
    attributes: {
      enabled: secret.?enabled ?? true
      exp: secret.?expirationDate
      nbf: secret.?notBeforeDate
    }
  }
}]

// ============ //
// Outputs      //
// ============ //

@description('The resource IDs of the secrets.')
#disable-next-line outputs-should-not-contain-secrets
output resourceIds array = [for (secret, i) in secrets: keyVaultSecrets[i].id]

@description('The names of the secrets.')
#disable-next-line outputs-should-not-contain-secrets
output names array = [for (secret, i) in secrets: keyVaultSecrets[i].name]

@description('The URIs of the secrets.')
#disable-next-line outputs-should-not-contain-secrets
output uris array = [for (secret, i) in secrets: keyVaultSecrets[i].properties.secretUri]

// ============== //
// Type Definitions //
// ============== //

@description('Secret configuration type.')
type secretType = {
  @description('The name of the secret.')
  name: string

  @description('The value of the secret.')
  @secure()
  value: string

  @description('Optional content type.')
  contentType: string?

  @description('Optional tags.')
  tags: object?

  @description('Optional. Enable the secret.')
  enabled: bool?

  @description('Optional. Expiration date as Unix epoch.')
  expirationDate: int?

  @description('Optional. Not before date as Unix epoch.')
  notBeforeDate: int?
}
