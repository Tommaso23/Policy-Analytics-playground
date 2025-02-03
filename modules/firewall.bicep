param fwPolicyName string
param fwName string
param subnetId string
param publicIpId string
param enableMgmtConf bool
param mgmtSubnetId string
param mgmtPublicIpId string



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
    managementIpConfiguration: enableMgmtConf == false ? null : {
      name: 'mgmtfirewallconf'
      properties: {
        subnet: {
          id: mgmtSubnetId
        }
        publicIPAddress: {
          id: mgmtPublicIpId
        }
      }
    }
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
  }
}
