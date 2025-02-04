param routeTableName string
param routeName string
param addressPrefix string
param nextHopType string
param nextHopIp string

resource routeTableRoute 'Microsoft.Network/routeTables/routes@2024-05-01' = {
  name: '${routeTableName}/${routeName}'
  properties: {
    addressPrefix: addressPrefix
    nextHopType: nextHopType
    nextHopIpAddress: nextHopIp
  }
}
