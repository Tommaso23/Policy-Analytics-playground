param subnetName string
param vnetName string
param subnetAddrPrefix string
param nsgId string
param routeTableId string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties:{ 
    addressPrefix: subnetAddrPrefix
    networkSecurityGroup: nsgId == '' ? null : {
      id: nsgId
    }
    routeTable: routeTableId == '' ? null : {
      id: routeTableId
    }
  }
}


output subnetId string = subnet.id
