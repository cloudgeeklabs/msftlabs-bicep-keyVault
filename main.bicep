metadata name = 'KeyVault Module'
metadata description = 'Deploys Azure Key Vault with RBAC authorization, private endpoints, and enterprise security defaults!'
metadata owner = 'cloudgeeklabs'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============ //
// Parameters   //
// ============ //

@description('Required. Workload name used to generate resource names. Max 10 characters, lowercase letters and numbers only.')
@minLength(2)
@maxLength(10)
param workloadName string

@description('Optional. Azure region for deployment. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Optional. Environment identifier (dev, test, prod). Used in naming and tagging.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Optional. SKU name for Key Vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Optional. Enable Key Vault for Azure Resource Manager deployment.')
param enabledForDeployment bool = false

@description('Optional. Enable Key Vault for Azure Disk Encryption.')
param enabledForDiskEncryption bool = false

@description('Optional. Enable Key Vault for template deployment.')
param enabledForTemplateDeployment bool = false

@description('Optional. Soft delete retention in days.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Optional. Enable purge protection. Once enabled, cannot be disabled.')
param enablePurgeProtection bool = true

@description('Optional. Enable RBAC authorization instead of access policies. RBAC is required.')
param enableRbacAuthorization bool = true

@description('Optional. Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Optional. Allow trusted Microsoft services to bypass the firewall.')
param allowTrustedMicrosoftServices bool = false

@description('Optional. Virtual network resource IDs for firewall rules.')
param virtualNetworkRules array = []

@description('Optional. IP rules for firewall.')
param ipRules array = []

@description('Optional. Subnet resource ID for private endpoint. If provided, a private endpoint will be configured.')
param privateEndpointSubnetId string = ''

@description('Optional. Log Analytics workspace ID for diagnostics. Uses default if not specified.')
param diagnosticWorkspaceId string = ''

@description('Optional. Enable diagnostic settings for audit logging.')
param enableDiagnostics bool = true

@description('Optional. Enable resource lock to prevent deletion.')
param enableLock bool = true

@description('Optional. Lock level to apply if enabled.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param lockLevel string = 'CanNotDelete'

@description('Optional. RBAC role assignments for the Key Vault.')
param roleAssignments roleAssignmentType[] = []

@description('Optional. Secrets to store in the Key Vault. The secretType has @secure() on the value property.')
param secrets secretType[] = []

@description('Required. Resource tags for organization and cost management.')
param tags object

// ============ //
// Variables    //
// ============ //

// Generate unique suffix using resource group ID to ensure uniqueness
var uniqueSuffix = take(uniqueString(resourceGroup().id, subscription().id), 5)

// Construct Key Vault name: kv-<workload>-<env>-<suffix>
// Key Vault names must be 3-24 chars, alphanumeric and hyphens only
var keyVaultName = 'kv-${toLower(workloadName)}-${environment}-${uniqueSuffix}'
var keyVaultNameLength = length(keyVaultName)
var isValidLength = keyVaultNameLength >= 3 && keyVaultNameLength <= 24

// Default Log Analytics workspace for diagnostics if not provided
// Centralized LAW for MSFTLabs Environment
var defaultWorkspaceId = '/subscriptions/b18ea7d6-14b5-41f3-a00d-804a5180c589/resourceGroups/msft-core-observability/providers/Microsoft.OperationalInsights/workspaces/msft-core-cus-law'

// Merge provided workspace ID with default using conditional logic
var mergedWorkspaceId = !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : defaultWorkspaceId

// ============ //
// Resources    //
// ============ //

// Deploy Key Vault using nested module
module keyVault 'modules/keyVault.bicep' = if (isValidLength) {
  name: '${uniqueString(deployment().name, location)}-key-vault'
  params: {
    keyVaultName: keyVaultName
    location: location
    skuName: skuName
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: publicNetworkAccess
    allowTrustedMicrosoftServices: allowTrustedMicrosoftServices
    virtualNetworkRules: virtualNetworkRules
    ipRules: ipRules
    tags: tags
  }
}

// Deploy Private Endpoint if subnet ID provided
module privateEndpoint 'modules/privateEndpoint.bicep' = if (!empty(privateEndpointSubnetId) && isValidLength) {
  name: '${uniqueString(deployment().name, location)}-private-endpoint'
  params: {
    keyVaultName: keyVault.?outputs.name ?? ''
    keyVaultResourceId: keyVault.?outputs.resourceId ?? ''
    subnetResourceId: privateEndpointSubnetId
    location: location
    privateEndpointName: '${keyVaultName}-pe'
    tags: tags
  }
}

// Deploy Diagnostic Settings for audit logging
module diagnostics 'modules/diagnostics.bicep' = if (enableDiagnostics && isValidLength) {
  name: '${uniqueString(deployment().name, location)}-diagnostics'
  params: {
    keyVaultName: keyVault.?outputs.name ?? ''
    workspaceId: mergedWorkspaceId
    enableLogs: true
    enableMetrics: true
  }
}

// Deploy Resource Lock to prevent accidental deletion
module lock 'modules/lock.bicep' = if (enableLock && isValidLength) {
  name: '${uniqueString(deployment().name, location)}-lock'
  params: {
    keyVaultName: keyVault.?outputs.name ?? ''
    lockLevel: lockLevel
    lockNotes: 'Prevents accidental deletion of ${environment} Key Vault for ${workloadName}'
  }
}

// Deploy RBAC Role Assignments
module rbac 'modules/rbac.bicep' = if (!empty(roleAssignments) && isValidLength) {
  name: '${uniqueString(deployment().name, location)}-rbac'
  params: {
    keyVaultName: keyVault.?outputs.name ?? ''
    roleAssignments: roleAssignments
  }
}

// Deploy Secrets if provided
module secretDeployment 'modules/secret.bicep' = if (!empty(secrets) && isValidLength) {
  name: '${uniqueString(deployment().name, location)}-secrets'
  params: {
    keyVaultName: keyVault.?outputs.name ?? ''
    secrets: secrets
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the Key Vault.')
output resourceId string = keyVault.?outputs.resourceId ?? ''

@description('The name of the Key Vault.')
output name string = keyVault.?outputs.name ?? ''

@description('The URI of the Key Vault.')
output vaultUri string = keyVault.?outputs.vaultUri ?? ''

@description('The resource group the Key Vault was deployed into.')
output resourceGroupName string = keyVault.?outputs.resourceGroupName ?? ''

@description('The location the resource was deployed into.')
output location string = keyVault.?outputs.location ?? ''

@description('The generated Key Vault name.')
output keyVaultName string = keyVaultName

@description('The environment identifier.')
output environment string = environment

@description('The unique naming suffix generated.')
output uniqueSuffix string = uniqueSuffix

// ============== //
// Type Definitions //
// ============== //

@description('Role assignment configuration type.')
type roleAssignmentType = {
  @description('The principal ID (object ID) of the identity.')
  principalId: string

  @description('The role definition ID or built-in role name.')
  roleDefinitionIdOrName: string

  @description('The type of principal.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ManagedIdentity')?
}

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
}
