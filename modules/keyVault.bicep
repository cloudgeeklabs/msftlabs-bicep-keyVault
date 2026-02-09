// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault. Must be globally unique, 3-24 characters, alphanumeric and hyphens.')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Optional. Azure region for deployment.')
param location string = resourceGroup().location

@description('Optional. SKU name for Key Vault. Standard is sufficient for most workloads.')
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

@description('Optional. Soft delete retention in days. Minimum 7, maximum 90.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Optional. Enable purge protection. Once enabled, cannot be disabled.')
param enablePurgeProtection bool = true

@description('Optional. Enable RBAC authorization instead of access policies.')
param enableRbacAuthorization bool = true

@description('Optional. Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Optional. Allow trusted Microsoft services to bypass the firewall.')
param allowTrustedMicrosoftServices bool = false

@description('Optional. Virtual network rules for firewall.')
param virtualNetworkRules array = []

@description('Optional. IP rules for firewall.')
param ipRules array = []

@description('Required. Resource tags for organization and cost tracking.')
param tags object

// ============ //
// Variables    //
// ============ //

// Network ACLs configuration
// bypass: 'AzureServices' allows trusted Azure services, 'None' blocks all
// For-expressions must be top-level variable declarations, not nested in objects
var formattedVnetRules = [for rule in virtualNetworkRules: {
  id: rule
  ignoreMissingVnetServiceEndpoint: false
}]

var formattedIpRules = [for ip in ipRules: {
  value: ip
}]

var networkAcls = {
  bypass: allowTrustedMicrosoftServices ? 'AzureServices' : 'None'
  defaultAction: 'Deny'
  virtualNetworkRules: formattedVnetRules
  ipRules: formattedIpRules
}

// ============ //
// Resources    //
// ============ //

// Deploy Key Vault with security-first configuration
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.keyvault/vaults
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: publicNetworkAccess
    networkAcls: networkAcls
    // Access policies left empty when using RBAC authorization
    accessPolicies: []
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the Key Vault.')
output resourceId string = keyVault.id

@description('The name of the Key Vault.')
output name string = keyVault.name

@description('The URI of the Key Vault.')
output vaultUri string = keyVault.properties.vaultUri

@description('The resource group the Key Vault was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = keyVault.location
