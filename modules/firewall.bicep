param location string
param fwName string
param subnetId string
param publicIpId string
param firewallPolicyId string

resource firewall 'Microsoft.Network/azureFirewalls@2024-03-01' = {
  name: fwName
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'primaryfirewallconf'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]    
    firewallPolicy: {
      id: firewallPolicyId
    }
  }
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
