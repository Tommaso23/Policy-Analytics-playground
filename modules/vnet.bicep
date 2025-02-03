param vnetName string
param vnetAddrPrefix array
param location string
param subnetId string
param dnsServer array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddrPrefix
    }
    dhcpOptions: {
      dnsServers: dnsServer
    }
    subnets: [
      {
        id: subnetId
      }
    ]
        
  }
}

output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
