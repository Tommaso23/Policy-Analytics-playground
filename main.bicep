targetScope = 'subscription'

param location string = 'italynorth'

/*Resource Groups*/
var hubRgName = 'rg-hub-in'
var spoke1RgName = 'rg-spoke1-in'
var spoke2RgName = 'rg-spoke2-in'
var automationRgName = 'rg-automation-in'
var identityRgName = 'rg-identity-in'


/*VNET*/
var hubVnetName = 'vnet-hub-in'
var identityVnetName = 'vnet-identity-in'
var spoke1VnetName = 'vnet-spoke1-in'
var spoke2VnetName = 'vnet-spoke2-in'


var hubVnetAddrPrefix = '10.0.10.0/24'
var identityVnetAddrPrefix = '10.0.20.0/24'
var spoke1VnetAddrPrefix = '10.0.30.0/24'
var spoke2VnetAddrPrefix = '10.0.40.0/24'

var hubSubnetAddrPrefix = '10.0.10.0/26'
var dcSubnetAddrPrefix = '10.0.20.0/27'
var linuxSubnetAddrPrefix = '10.0.30.0/27'
var winSubnetAddrPrefix = '10.0.40.0/27'

var spoke1RouteTableName = 'rt-spoke1-vnet'
var identityRouteTableName = 'rt-identity-vnet'
var spoke2RouteTableName = 'rt-spoke2-vnet'

var identitySubnetRouteTableRoutes = {
  name: 'default-via-azfw'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: //azureFirewall.outputs.firewallPrivateIp
  }
}

var spoke1SubnetRouteTableRoutes = [
  {
    name: 'default-via-azfw'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: //azureFirewall.outputs.firewallPrivateIp
    }
  }
  {
    name: 'fwpip-via-internet'
    properties: {
      addressPrefix: //azureFirewall.outputs.firewallPublicIp
      nextHopType: 'Internet'
    }
  }
]

var spoke2SubnetRouteTableRoutes = {
  name: 'default-via-azfw'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: //azureFirewall.outputs.firewallPrivateIp
  }
}
    


var hubSubnet = [
  {
    subnetAddrPrefix: hubSubnetAddrPrefix
    subnetName: 'AzureFirewallSubnet'
    vnetName: hubVnetName
    nsgId: //TODO
    routeTableId: //TODO
  }
]

var identitySubnet = [
  {
    subnetAddrPrefix: identityVnetAddrPrefix
    subnetName: 'snet-dc'
    vnetName: dcSubnetAddrPrefix
    nsgId: //TODO
    routeTableId: //TODO
  }
]

var spoke1Subnet = [
  {
    subnetAddrPrefix: linuxSubnetAddrPrefix
    subnetName: 'snet-linux-vms'
    nsgId: //TODO
    routeTableId: //TODO
  }
]

var spoke2Subnet = [
  {
    subnetAddrPrefix: winSubnetAddrPrefix
    subnetName: 'snet-win-vms'
    nsgId: //TODO
    routeTableId: //TODO
  }
]


// RESOURCE GROUPS //
module hubResourceGroup 'modules/resourceGroup.bicep' = {
  name: 'HubResourceGroup'
  params: {
    location: location
    rgName: hubRgName
  }
}

module spoke1ResourceGroup 'modules/resourceGroup.bicep' = {
  name: 'spoke1ResourceGroup'
  params: {
    location: location
    rgName: spoke1RgName
  }
}

module spoke2ResourceGroup 'modules/resourceGroup.bicep' = {
  name: 'spoke2ResourceGroup'
  params: {
    location: location
    rgName: spoke2RgName
  }
}

module identityResourceGroup 'modules/resourceGroup.bicep' = {
  name: 'identityResourceGroup'
  params: {
    location: location
    rgName: identityRgName
  }
}

module automationResourceGroup 'modules/resourceGroup.bicep' = {
  name: 'automationResourceGroup'
  params: {
    location: location
    rgName: automationRgName
  }
}


// VNET //
module hubVnet 'modules/vnet.bicep' = {
  name: 'hubVnet'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    vnetName: hubVnetName
    vnetAddrPrefix: hubVnetAddrPrefix
    subnet: hubSubnet
  }
  dependsOn: [
    hubResourceGroup
  ]
}

module identityVnet 'modules/vnet.bicep' = {
  name: 'identityVnet'
  scope: resourceGroup(identityRgName)
  params: {
    location: location
    vnetName: identityVnetName
    vnetAddrPrefix: identityVnetAddrPrefix
    subnet: identitySubnet
  }
  dependsOn: [
    identityResourceGroup
  ]
}

module spoke1Vnet 'modules/vnet.bicep' = {
  name: 'spoke1Vnet'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    vnetName: spoke1VnetName
    vnetAddrPrefix: spoke1VnetAddrPrefix
    subnet: spoke1Subnet
  }
  dependsOn: [
    spoke1ResourceGroup
  ]
}

module spoke2Vnet 'modules/vnet.bicep' = {
  name: 'spoke2Vnet'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    vnetName: spoke2VnetName
    vnetAddrPrefix: spoke2VnetAddrPrefix
    subnet: spoke2Subnet
  }
  dependsOn: [
    spoke2ResourceGroup
  ]
}


// VNET PEERING //
module hubToSpoke1Peering 'modules/vnetPeering.bicep' = {
  name: 'hubToSpoke1Peering'
  scope: resourceGroup(hubRgName)
  params: {
    peeringName: 'hubToSpoke1'
    sourceVnetName: hubVnetName
    destinationVnetId: spoke1Vnet.outputs.vnetId
  }
  dependsOn: [
    hubVnet
  ]
}

module hubToSpoke2Peering 'modules/vnetPeering.bicep' = {
  name: 'hubToSpoke2Peering'
  scope: resourceGroup(hubRgName)
  params: {
    peeringName: 'hubToSpoke2'
    sourceVnetName: hubVnetName
    destinationVnetId: spoke2Vnet.outputs.vnetId
  }
  dependsOn: [
    hubVnet
  ]
}

module hubToIdentityPeering 'modules/vnetPeering.bicep' = {
  name: 'hubToIdentityPeering'
  scope: resourceGroup(hubRgName)
  params: {
    peeringName: 'hubToIdentity'
    sourceVnetName: hubVnetName
    destinationVnetId: identityVnet.outputs.vnetId
  }
  dependsOn: [
    hubVnet
  ]
}

module spoke1ToHubPeering 'modules/vnetPeering.bicep' = {
  name: 'spoke1ToHubPeering'
  scope: resourceGroup(spoke1RgName)
  params: {
    peeringName: 'spoke1ToHub'
    sourceVnetName: spoke1VnetName
    destinationVnetId: hubVnet.outputs.vnetId
  }
  dependsOn: [
    spoke1Vnet
  ]
}

module spoke2ToHubPeering 'modules/vnetPeering.bicep' = {
  name: 'spoke2ToHubPeering'
  scope: resourceGroup(spoke2RgName)
  params: {
    peeringName: 'spoke2ToHub'
    sourceVnetName: spoke2VnetName
    destinationVnetId: hubVnet.outputs.vnetId
  }
  dependsOn: [
    spoke2Vnet
  ]
}

module identityToHubPeering 'modules/vnetPeering.bicep' = {
  name: 'identityToHubPeering'
  scope: resourceGroup(identityRgName)
  params: {
    peeringName: 'identityToHub'
    sourceVnetName: identityVnetName
    destinationVnetId: hubVnet.outputs.vnetId
  }
  dependsOn: [
    identityVnet
  ]
}


// ROUTE TABLES //
module spoke1RouteTable 'modules/routeTable.bicep' = {
  name: 'Spoke1RouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: spoke1RouteTableName
  }
  dependsOn: [
    spoke1Vnet
  ]
}

module spoke2RouteTable 'modules/routeTable.bicep' = {
  name: 'Spoke2RouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: spoke2RouteTableName
  }
  dependsOn: [
    spoke2Vnet
  ]
}

module identityRouteTable 'modules/routeTable.bicep' = {
  name: 'IdentityRouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: identityRouteTableName
  }
  dependsOn: [
    identityVnet
  ]
}


module onpremHubDcVmDomainControllerConfig 'virtualmachineextension.bicep' = {
  name: 'onpremHubDcVmDomainControllerConfig'
  scope: resourceGroup(onpremHubRgName)
  params: {
    location: location
    properties: onpremDcConfigurationExtensionProperties
    vmExtensionName: 'DC-Creation'
    vmName: onpremHubDcName
  }
  dependsOn: [
    onpremHubDcVm
  ]
}



// UPDATE VNET DNS//
module hubVnetUpdate 'modules/vnet.bicep' = {
  name: 'onpremHubVnetUpdate'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    vnetName: hubVnetName
    vnetAddrPrefix: hubVnetAddrPrefix
    subnets: hubSubnet
    dnsServers: [
      dcPrivateIp
    ]
  }
  dependsOn: [
    onpremHubDcVmDomainControllerConfig
  ]
}


// UPDATE ROUTE TABLES//
module identitySubnetRouteTableRoutesConf 'modules/routeTableRoute.bicep' = {
  name: 'azureGatewaySubnetRouteTableRoutesConf'
  scope: resourceGroup(hubRgName)
  params: {
    addressPrefix: identitySubnetRouteTableRoutes.properties.addressPrefix
    nextHopIp: identitySubnetRouteTableRoutes.properties.nextHopIpAddress
    nextHopType: identitySubnetRouteTableRoutes.properties.nextHopType
    routeName: identitySubnetRouteTableRoutes.name
    routeTableName: identityRouteTableName
  }
}

module spoke1SubnetRouteTableRoutesConf 'modules/routeTableRoute.bicep' = {
  name: 'spoke1SubnetRouteTableRoutesConf'
  scope: resourceGroup(hubRgName)
  params: {
    addressPrefix: spoke1SubnetRouteTableRoutes[0].properties.addressPrefix
    nextHopIp: spoke1SubnetRouteTableRoutes[0].properties.nextHopIpAddress
    nextHopType: spoke1SubnetRouteTableRoutes[0].properties.nextHopType
    routeName: spoke1SubnetRouteTableRoutes[0].name
    routeTableName: spoke1RouteTableName
  }
}

module spok1SubnetRouteTableRoutesConf2 'modules/routeTableRoute.bicep' = {
  name: 'spoke1SubnetRouteTableRoutesConf2'
  scope: resourceGroup(hubRgName)
  params: {
    addressPrefix: spoke1SubnetRouteTableRoutes[1].properties.addressPrefix
    nextHopIp: spoke1SubnetRouteTableRoutes[1].properties.nextHopIpAddress
    nextHopType: spoke1SubnetRouteTableRoutes[1].properties.nextHopType
    routeName: spoke1SubnetRouteTableRoutes[1].name
    routeTableName: spoke1RouteTableName
  }
}

module spoke2SubnetRouteTableRoutesConf 'modules/routeTableRoute.bicep' = {
  name: 'spoke2SubnetRouteTableRoutesConf'
  scope: resourceGroup(hubRgName)
  params: {
    addressPrefix: spoke2SubnetRouteTableRoutes.properties.addressPrefix
    nextHopIp: spoke2SubnetRouteTableRoutes.properties.nextHopIpAddress
    nextHopType: spoke2SubnetRouteTableRoutes.properties.nextHopType
    routeName: spoke2SubnetRouteTableRoutes.name
    routeTableName: spoke2RouteTableName
  }
}



/*module azureFirewall 'firewall.bicep' = {
  name: 'azureFirewall'
  scope: resourceGroup(resourceGroup)
  params: {
    location: 'italynorth'
    fwName: firewallName
    fwPolicyName: fwPolicyName
    publicIpId: azureFirewallPublicIp.outputs.ipId
  }
}*/
