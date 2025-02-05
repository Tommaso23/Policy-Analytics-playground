param fwPolicyName string
param location string
param fwName string
param subnetId string
param publicIpId string
param fwTier string


resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-05-01' = {
  name: fwPolicyName
  location: location
  properties: {
    sku: {
      tier: fwTier
    }
    threatIntelMode: 'Alert'
  }
}


resource firewall 'Microsoft.Network/azureFirewalls@2024-03-01' = {
  name: fwName
  location: 'italynorth'
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
      id: firewallPolicy.id
    }
  }
}

output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
