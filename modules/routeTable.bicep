param routeTableName string
param location string
param disableBgpRoutePropagation bool

resource routeTable 'Microsoft.Network/routeTables@2022-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

output rtId string = routeTable.id
