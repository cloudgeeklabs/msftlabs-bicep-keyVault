// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault to configure diagnostics for.')
param keyVaultName string

@description('Required. Resource ID of the Log Analytics workspace.')
param workspaceId string

@description('Optional. The name of the diagnostic setting.')
param diagnosticSettingName string = '${keyVaultName}-diagnostics'

@description('Optional. Enable audit event logs.')
param enableLogs bool = true

@description('Optional. Enable metrics collection.')
param enableMetrics bool = true

// ============ //
// Variables    //
// ============ //

// Log categories for Key Vault
var logsConfig = [
  {
    categoryGroup: 'audit'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
  {
    categoryGroup: 'allLogs'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
]

// Metrics configuration
var metricsConfig = [
  {
    category: 'AllMetrics'
    enabled: enableMetrics
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
]

// ============ //
// Resources    //
// ============ //

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Deploy diagnostic settings for Key Vault
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.insights/diagnosticsettings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: keyVault
  properties: {
    workspaceId: workspaceId
    logs: logsConfig
    metrics: metricsConfig
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the diagnostic setting.')
output resourceId string = diagnosticSettings.id

@description('The name of the diagnostic setting.')
output name string = diagnosticSettings.name
