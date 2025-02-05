param subnetName string
param vnetName string
param subnetAddrPrefix string
param routeTableId string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${vnetName}/${subnetName}'
  properties:{ 
    addressPrefix: subnetAddrPrefix
    routeTable: routeTableId == '' ? null : {
      id: routeTableId
    }
  }
}


output subnetId string = subnet.id
