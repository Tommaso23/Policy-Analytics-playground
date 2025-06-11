param publicIpAddressName string
param location string

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

output ipId string = publicIpAddress.id
output ipAddress string = publicIpAddress.properties.ipAddress
