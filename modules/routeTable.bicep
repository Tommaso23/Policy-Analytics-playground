param routeTableName string
param location string

resource routeTable 'Microsoft.Network/routeTables@2022-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: true
  }
}

output rtId string = routeTable.id
