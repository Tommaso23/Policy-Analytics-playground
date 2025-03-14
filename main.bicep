targetScope = 'subscription'

param location string = deployment().location

/*Resource Groups*/
var hubRgName = 'rg-hub-itn'
var spoke1RgName = 'rg-spoke1-itn'
var spoke2RgName = 'rg-spoke2-itn'
var automationRgName = 'rg-automation-itn'
var identityRgName = 'rg-identity-itn'

/*VNET*/
var hubVnetName = 'vnet-hub-itn'
var identityVnetName = 'vnet-identity-itn'
var spoke1VnetName = 'vnet-spoke1-itn'
var spoke2VnetName = 'vnet-spoke2-itn'

var hubVnetAddrPrefix = ['10.0.10.0/24']
var identityVnetAddrPrefix = ['10.0.20.0/24']
var spoke1VnetAddrPrefix = ['10.0.30.0/24']
var spoke2VnetAddrPrefix = ['10.0.40.0/24']

/*SUBNET*/
var hubSubnetAddrPrefix = ['10.0.10.0/26']
var dcSubnetAddrPrefix = ['10.0.20.0/27']
var linuxSubnetAddrPrefix = ['10.0.30.0/27']
var winSubnetAddrPrefix = ['10.0.40.0/27']

/*VIRTUAL MACHINE*/
var domainControllerComputerName = 'vm-dc1-itn'

@description('username administrator for all VMs')
param adminUsername string = 'azureuser'

@description('username administrator password for all VMs')
@secure()
param adminPassword string = 'Password123!'

var IIS1ComputerName = 'vm-iis-1-itn'
var IIS2ComputerName = 'vm-iis-2-itn'
var linux1ComputerName = 'vm-lnx-1-itn'
var linux2ComputerName = 'vm-lnx-2-itn'
var linux1PublicIpName = 'pip-${linux1ComputerName}'

var windowsPublisher = 'MicrosoftWindowsServer'
var windowsOffer = 'WindowsServer'
var windowsSku = '2019-Datacenter-gensecond'

var linuxPublisher = 'canonical'
var linuxOffer = 'ubuntu-24_04-lts'
var linuxSku = 'server'

var spokeVmIISExtensionProperties = {
  publisher: 'Microsoft.Compute'
  type: 'CustomScriptExtension'
  typeHandlerVersion: '1.10'
  autoUpgradeMinorVersion: true
  protectedSettings: {
    commandToExecute: 'powershell.exe Add-WindowsFeature Web-Server; powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername); powershell Set-NetFirewallProfile -Enabled False'
  }
}

var domainJoinedVmProperties = {
  publisher: 'Microsoft.Compute'
  type: 'JsonADDomainExtension'
  typeHandlerVersion: '1.3'
  autoUpgradeMinorVersion: true
  settings: {
    Name: 'contoso.com'
    OUPath: 'OU=Azure,DC=contoso,DC=com'
    User: 'contoso\\administrator'
    Restart: 'true'
  }
}


var hubSubnet = [
  {
    subnetAddrPrefix: hubSubnetAddrPrefix
    subnetName: 'AzureFirewallSubnet'
    vnetName: hubVnetName
    nsgId: ''
    routeTableId: ''
  }
]

var identitySubnet = [
  {
    subnetAddrPrefix: identityVnetAddrPrefix
    subnetName: 'snet-dc'
    vnetName: dcSubnetAddrPrefix
    nsgId: identityNsg.outputs.nsgId
    routeTableId: ''
  }
]

var spoke1Subnet = [
  {
    subnetAddrPrefix: linuxSubnetAddrPrefix
    subnetName: 'snet-linux-vms'
    nsgId: spoke1Nsg.outputs.nsgId
    routeTableId: ''
  }
]

var spoke2Subnet = [
  {
    subnetAddrPrefix: winSubnetAddrPrefix
    subnetName: 'snet-win-vms'
    nsgId: spoke2Nsg.outputs.nsgId
    routeTableId: ''
  }
]

/*ROUTE TABLE*/
var spoke1RouteTableName = 'rt-spoke1-vnet'
var identityRouteTableName = 'rt-identity-vnet'
var spoke2RouteTableName = 'rt-spoke2-vnet'

var firewallName = 'afw-hub-itn'
var fwTier = 'Premium'
var fwPolicyName = 'afw-policy-hub-itn'

var identitySubnetRouteTableRoutes = [
  {
    name: 'default-via-azfw'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: azureFirewall.outputs.firewallPrivateIp
    }
  }
]

var spoke1SubnetRouteTableRoutes = [
  {
    name: 'default-via-azfw'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: azureFirewall.outputs.firewallPrivateIp
    }
  }
  {
    name: 'fwpip-via-internet'
    properties: {
      addressPrefix: azureFirewallPublicIp.outputs.ipAddress
      nextHopType: 'Internet'
    }
  }
]

var spoke2SubnetRouteTableRoutes = [
  {
    name: 'default-via-azfw'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: azureFirewall.outputs.firewallPrivateIp
    }
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
    subnets: hubSubnet
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
    subnets: identitySubnet
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
    subnets: spoke1Subnet
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
    subnets: spoke2Subnet
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

// NSG //
module spoke1Nsg 'modules/networkSecurityGroup.bicep' = {
  name: 'spoke1Nsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    name: 'nsg-spoke1-in'
  }
}

module spoke2Nsg 'modules/networkSecurityGroup.bicep' = {
  name: 'spoke2Nsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    name: 'nsg-spoke2-in'
  }
}

module identityNsg 'modules/networkSecurityGroup.bicep' = {
  name: 'identityNsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    name: 'nsg-identity-in'
  }
}

// ROUTE TABLES and ROUTES //
module spoke1RouteTable 'modules/routeTable.bicep' = {
  name: 'Spoke1RouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: spoke1RouteTableName
    //routeTableRoutes: spoke1SubnetRouteTableRoutes
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
    //routeTableRoutes: spoke2SubnetRouteTableRoutes
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
    //routeTableRoutes: identitySubnetRouteTableRoutes
  }
  dependsOn: [
    identityVnet
  ]
}

// FIREWALL //
module azureFirewallPublicIp 'modules/publicIp.bicep' = {
  name: 'azureFirewallPublicIp'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    publicIpAddressName: 'pip-afw-hub-in'
  }
}


module azureFirewall 'modules/firewall.bicep' = {
  name: 'azureFirewall'
  scope: resourceGroup(hubRgName)
  params: {
    location: 'italynorth'
    fwName: firewallName
    fwPolicyName: fwPolicyName
    publicIpId: azureFirewallPublicIp.outputs.ipId
    subnetId: hubVnet.outputs.subnets[0].subnetId
    fwTier: fwTier
  }
}

// DOMAIN CONTROLLER //
module domainController 'modules/virtualmachine.bicep' = {
  name: 'domainController'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    virtualMachineName: domainControllerComputerName
    osDiskType: 'Standard_LRS'
    computerName: domainControllerComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: identityVnet.outputs.subnets[0].subnetId
    privateIpAddress: '10.0.20.5'
    publicIpId: ''
    publisher: windowsPublisher
    offer: windowsOffer
    sku: windowsSku
  }
  dependsOn: [
    identityVnet
  ]
}


module spoke2IISvirtualmachine1 'modules/virtualmachine.bicep' = {
  name: 'spokeIISvirtualmachine1'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    virtualMachineName: IIS1ComputerName
    osDiskType: 'Standard_LRS'
    computerName: IIS1ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke2Vnet.outputs.subnets[0].subnetId
    privateIpAddress: '10.0.40.4'
    publicIpId: ''
    publisher: windowsPublisher
    offer: windowsOffer
    sku: windowsSku
  }
}

module spoke2IISvirtualmachine2 'modules/virtualmachine.bicep' = {
  name: 'spokeIISvirtualmachine2'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    virtualMachineName: IIS2ComputerName
    osDiskType: 'Standard_LRS'
    computerName: IIS2ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke2Vnet.outputs.subnets[0].subnetId
    privateIpAddress: '10.0.40.5'
    publicIpId: ''
    publisher: windowsPublisher
    offer: windowsOffer
    sku: windowsSku
  }
}

module azureSpokeVmIISConfiguration1 'modules/virtualmachineextension.bicep' = {
  name: 'azureSpokeVmIISConfiguration'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    properties: spokeVmIISExtensionProperties
    vmExtensionName: 'DC-Creation'
    vmName: IIS1ComputerName
  }
  dependsOn: [
    spoke2IISvirtualmachine1
  ]
}

module azureSpokeVmIISConfiguration2 'modules/virtualmachineextension.bicep' = {
  name: 'azureSpokeVmIISConfiguration'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    properties: spokeVmIISExtensionProperties
    vmExtensionName: 'DC-Creation'
    vmName: IIS2ComputerName
  }
  dependsOn: [
    spoke2IISvirtualmachine2
  ]
}

module onpremSpokeVmDomainJoin 'modules/virtualmachineextension.bicep' = {
  name: 'onpremSpokeVmDomainJoin'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    properties: domainJoinedVmProperties
    vmExtensionName: 'OnpremSpoke-DomainJoin'
    vmName: IIS1ComputerName
  }
  dependsOn: [
    spoke2IISvirtualmachine1
  ]
}

module linux1PublicIp 'modules/publicip.bicep' = {
  name: 'linux1PublicIp'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    publicIpAddressName: linux1PublicIpName
  }
  dependsOn: [
    onpremHubResourceGroup
  ]
}

module spoke1LinuxVirtualMachine1 'modules/virtualmachine.bicep' = {
  name: 'spoke1LinuxVirtualMachine1'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    virtualMachineName: linux1ComputerName
    osDiskType: 'Standard_LRS'
    computerName: linux1ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke1Vnet.outputs.subnets[0].subnetId
    privateIpAddress: ''
  }
}











module onpremHubDcVmDomainControllerConfig 'modules/virtualmachineextension.bicep' = {
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




