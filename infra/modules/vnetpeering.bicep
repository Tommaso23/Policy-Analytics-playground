param peeringName string
param sourceVnetName string
param destinationVnetId string
param allowForwardedTraffic bool
param allowGatewayTransit bool
param useRemoteGateways bool

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: '${sourceVnetName}/${peeringName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: destinationVnetId
    }
  }
}


