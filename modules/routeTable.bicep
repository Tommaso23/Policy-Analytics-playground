param routeTableName string
param location string
param routes array

resource routeTable 'Microsoft.Network/routeTables@2022-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: true
    routes: routes
  }
}

output rtId string = routeTable.id
