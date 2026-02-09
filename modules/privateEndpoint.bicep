// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault for the private endpoint.')
param keyVaultName string

@description('Required. The resource ID of the Key Vault.')
param keyVaultResourceId string

@description('Required. The resource ID of the subnet for the private endpoint.')
param subnetResourceId string

@description('Optional. Azure region for deployment.')
param location string = resourceGroup().location

@description('Optional. The name of the private endpoint.')
param privateEndpointName string = '${keyVaultName}-pe'

@description('Required. Resource tags.')
param tags object

// ============ //
// Variables    //
// ============ //

// Private DNS Zone group for Key Vault
var privateDnsZoneName = 'privatelink.vaultcore.azure.net'

// ============ //
// Resources    //
// ============ //

// Deploy Private Endpoint for Key Vault
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.network/privateendpoints
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: keyVaultResourceId
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Deploy Private DNS Zone Group for automatic DNS registration
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(privateDnsZoneName, '.', '-')
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', privateDnsZoneName)
        }
      }
    ]
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the private endpoint.')
output resourceId string = privateEndpoint.id

@description('The name of the private endpoint.')
output name string = privateEndpoint.name

@description('The private IP addresses of the private endpoint.')
output customDnsConfigs array = privateEndpoint.properties.customDnsConfigs
