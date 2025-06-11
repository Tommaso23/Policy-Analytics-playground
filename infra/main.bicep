targetScope = 'subscription'
param location string = deployment().location

@description('Name of the workload')
param workloadName string
@description('Alias for the location, used to create unique resource names.')
param locationAlias string

/*Resource Groups*/
var hubRgName = 'rg-hub-${workloadName}-${locationAlias}'
var spoke1RgName = 'rg-spoke1-${workloadName}-${locationAlias}'
var spoke2RgName = 'rg-spoke2-${workloadName}-${locationAlias}'

/*VNET*/
var hubVnetName = 'vnet-hub-${workloadName}-${locationAlias}' //hub
var spoke1VnetName = 'vnet-spoke1-${workloadName}-${locationAlias}' //linux
var spoke2VnetName = 'vnet-spoke2-${workloadName}-${locationAlias}' //windows

var hubVnetAddrPrefix = ['10.0.10.0/24'] 
var spoke1VnetAddrPrefix = ['10.0.20.0/24']
var spoke2VnetAddrPrefix = ['10.0.30.0/24']

/*SUBNET*/
var hubSubnetAddrPrefix = '10.0.10.0/26'
var linuxSubnetAddrPrefix = '10.0.20.0/27' 
var winSubnetAddrPrefix = '10.0.30.0/27'

/*VIRTUAL MACHINE*/
@description('username administrator for all VMs')
param adminUsername string

@description('username administrator password for all VMs')
@secure()
param adminPassword string 

var IIS1ComputerName = 'vm-iis1-${workloadName}-${locationAlias}'
var IIS2ComputerName = 'vm-iis2-${workloadName}-${locationAlias}'
var linux1ComputerName = 'vm-lnx-1-${workloadName}-${locationAlias}'
var linux2ComputerName = 'vm-lnx-2-${workloadName}-${locationAlias}'
var linux1PublicIpName = 'pip-${linux1ComputerName}'
var linux2PublicIpName = 'pip-${linux2ComputerName}'

var windowsPublisher = 'MicrosoftWindowsServer'
var windowsOffer = 'WindowsServer'
var windowsSku = '2022-Datacenter-azure-edition'

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

var hubSubnet = {
  subnetAddrPrefix: hubSubnetAddrPrefix
  subnetName: 'AzureFirewallSubnet'
  vnetName: hubVnetName
  nsgId: ''
  routeTableId: ''
}

var spoke1Subnet = {
  subnetAddrPrefix: linuxSubnetAddrPrefix
  subnetName: 'snet-linux-vms'
  nsgId: spoke1Nsg.outputs.nsgId
  routeTableId: spoke1RouteTable.outputs.rtId
}

var spoke2Subnet = {
  subnetAddrPrefix: winSubnetAddrPrefix
  subnetName: 'snet-win-vms'
  nsgId: spoke2Nsg.outputs.nsgId
  routeTableId: spoke2RouteTable.outputs.rtId
}


/*ROUTE TABLE*/
var spoke1RouteTableName = 'rt-spoke1-vnet'
var spoke2RouteTableName = 'rt-spoke2-vnet'

/*FIREWALL*/
var firewallName = 'afw-hub-${workloadName}-${locationAlias}'
var fwTier = 'Premium'
var fwPolicyName = 'afwp-hub-${workloadName}-${locationAlias}'

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
      addressPrefix: '${azureFirewallPublicIp.outputs.ipAddress}/32'
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
module hubResourceGroup 'modules/resourcegroup.bicep' = {
  name: 'hubResourceGroup'
  params: {
    location: location
    rgName: hubRgName
  }
}

module spoke1ResourceGroup 'modules/resourcegroup.bicep' = {
  name: 'spoke1ResourceGroup'
  params: {
    location: location
    rgName: spoke1RgName
  }
}

module spoke2ResourceGroup 'modules/resourcegroup.bicep' = {
  name: 'spoke2ResourceGroup'
  params: {
    location: location
    rgName: spoke2RgName
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
    subnets: [hubSubnet]
  }
  dependsOn: [
    hubResourceGroup
  ]
}
module spoke1Vnet 'modules/vnet.bicep' = {
  name: 'spoke1Vnet'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    vnetName: spoke1VnetName
    vnetAddrPrefix: spoke1VnetAddrPrefix
    subnets: [spoke1Subnet]
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
    subnets: [spoke2Subnet]
  }
  dependsOn: [
    spoke2ResourceGroup
  ]
}


// VNET PEERING //
module hubToSpoke1Peering 'modules/vnetpeering.bicep' = {
  name: 'hubToSpoke1Peering'
  scope: resourceGroup(hubRgName)
  params: {
    peeringName: 'hubToSpoke1'
    sourceVnetName: hubVnetName
    destinationVnetId: spoke1Vnet.outputs.vnetId
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
  }
  dependsOn: [
    hubVnet
  ]
}

module hubToSpoke2Peering 'modules/vnetpeering.bicep' = {
  name: 'hubToSpoke2Peering'
  scope: resourceGroup(hubRgName)
  params: {
    peeringName: 'hubToSpoke2'
    sourceVnetName: hubVnetName
    destinationVnetId: spoke2Vnet.outputs.vnetId
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
  }
  dependsOn: [
    hubVnet
  ]
}

module spoke1ToHubPeering 'modules/vnetpeering.bicep' = {
  name: 'spoke1ToHubPeering'
  scope: resourceGroup(spoke1RgName)
  params: {
    peeringName: 'spoke1ToHub'
    sourceVnetName: spoke1VnetName
    destinationVnetId: hubVnet.outputs.vnetId
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    spoke1Vnet
  ]
}

module spoke2ToHubPeering 'modules/vnetpeering.bicep' = {
  name: 'spoke2ToHubPeering'
  scope: resourceGroup(spoke2RgName)
  params: {
    peeringName: 'spoke2ToHub'
    sourceVnetName: spoke2VnetName
    destinationVnetId: hubVnet.outputs.vnetId
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false 
  }
  dependsOn: [
    spoke2Vnet
  ]
}

// NSG //
module spoke1Nsg 'modules/networksecuritygroup.bicep' = {
  name: 'spoke1Nsg'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    name: 'nsg-spoke1-in'
    securityRules: []
  }
  dependsOn: [
    spoke1ResourceGroup
  ]
}

module spoke2Nsg 'modules/networksecuritygroup.bicep' = {
  name: 'spoke2Nsg'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    name: 'nsg-spoke2-in'
    securityRules: []
  }
  dependsOn: [
    spoke2ResourceGroup
  ]
}


// ROUTE TABLES and ROUTES //
module spoke1RouteTable 'modules/routetable.bicep' = {
  name: 'Spoke1RouteTable'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    routeTableName: spoke1RouteTableName
  }
  dependsOn: [
    spoke1ResourceGroup
  ]
}

module spoke2RouteTable 'modules/routetable.bicep' = {
  name: 'Spoke2RouteTable'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    routeTableName: spoke2RouteTableName
  }
  dependsOn: [
    spoke2ResourceGroup
  ]
}

module spoke1SubnetRouteTableRoutesConf 'modules/routetableroute.bicep' = {
  name: 'spoke1SubnetRouteTableRoutesConf'
  scope: resourceGroup(spoke1RgName)
  params: {
    addressPrefix: spoke1SubnetRouteTableRoutes[0].properties.addressPrefix
    nextHopType: spoke1SubnetRouteTableRoutes[0].properties.nextHopType
    nextHopIp: spoke1SubnetRouteTableRoutes[0].properties.nextHopIpAddress
    routeName: spoke1SubnetRouteTableRoutes[0].name
    routeTableName: spoke1RouteTableName
  }
  dependsOn: [
    spoke1RouteTable
  ]
}

module spoke1SubnetRouteTableRoutesConf2 'modules/routetableroute.bicep' = {
  name: 'spoke1SubnetRouteTableRoutesConf2'
  scope: resourceGroup(spoke1RgName)
  params: {
    addressPrefix: spoke1SubnetRouteTableRoutes[1].properties.addressPrefix
    nextHopType: spoke1SubnetRouteTableRoutes[1].properties.nextHopType
    nextHopIp: ''
    routeName: spoke1SubnetRouteTableRoutes[1].name
    routeTableName: spoke1RouteTableName
  }
  dependsOn: [
    spoke1RouteTable
  ]
}

module spoke2SubnetRouteTableRoutesConf 'modules/routetableroute.bicep' = {
  name: 'spoke2SubnetRouteTableRoutesConf'
  scope: resourceGroup(spoke2RgName)
  params: {
    addressPrefix: spoke2SubnetRouteTableRoutes[0].properties.addressPrefix
    nextHopType: spoke2SubnetRouteTableRoutes[0].properties.nextHopType
    nextHopIp: spoke2SubnetRouteTableRoutes[0].properties.nextHopIpAddress
    routeName: spoke2SubnetRouteTableRoutes[0].name
    routeTableName: spoke2RouteTableName
  }
  dependsOn: [
    spoke2RouteTable
  ]
}

// FIREWALL //
module azureFirewallPublicIp 'modules/publicip.bicep' = {
  name: 'azureFirewallPublicIp'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    publicIpAddressName: 'pip-afw-hub-in'
  }
  dependsOn: [
    hubResourceGroup
  ]
}


module azureFirewall 'modules/firewall.bicep' = {
  name: 'azureFirewall'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    fwName: firewallName
    fwPolicyName: fwPolicyName
    publicIpId: azureFirewallPublicIp.outputs.ipId
    subnetId: hubVnet.outputs.subnets[0].id
    fwTier: fwTier
  }
  dependsOn: [
    hubResourceGroup
    hubToSpoke1Peering
    hubToSpoke2Peering
  ]
}

module firewallCollectionGroups 'modules/firewallcollectiongroup.bicep' = {
  name: 'firewallCollectionGroups'
  scope: resourceGroup(hubRgName)
  params: {
    firewallPublicIp: azureFirewallPublicIp.outputs.ipAddress 
  }
  dependsOn: [
    azureFirewall
  ]
}

module vmIIS1 'modules/virtualmachine.bicep' = {
  name: 'vmIIS-1'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    virtualMachineName: IIS1ComputerName
    osDiskType: 'Standard_LRS'
    computerName: IIS1ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke2Vnet.outputs.subnets[0].id
    privateIpAddress: '10.0.30.4'
    publicIpId: ''
    publisher: windowsPublisher
    offer: windowsOffer
    sku: windowsSku
  }
}

module vmIIS2 'modules/virtualmachine.bicep' = {
  name: 'vmIIS-2'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    virtualMachineName: IIS2ComputerName
    osDiskType: 'Standard_LRS'
    computerName: IIS2ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke2Vnet.outputs.subnets[0].id
    privateIpAddress: '10.0.30.5'
    publicIpId: ''
    publisher: windowsPublisher
    offer: windowsOffer
    sku: windowsSku
  }
}


module IISConfiguration1 'modules/virtualmachineextension.bicep' = {
  name: 'IISConfiguration-1'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    properties: spokeVmIISExtensionProperties
    vmExtensionName: 'IIS-installation'
    vmName: IIS1ComputerName
  }
  dependsOn: [
    vmIIS1
  ]
}

module IISConfiguration2 'modules/virtualmachineextension.bicep' = {
  name: 'IISConfiguration-2'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    properties: spokeVmIISExtensionProperties
    vmExtensionName: 'IIS-installation'
    vmName: IIS2ComputerName
  }
  dependsOn: [
    vmIIS2
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
    spoke1ResourceGroup
  ]
}

module spoke1LinuxVM1 'modules/virtualmachine.bicep' = {
  name: 'spoke1LinuxVirtualMachine1'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    virtualMachineName: linux1ComputerName
    osDiskType: 'Standard_LRS'
    computerName: linux1ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke1Vnet.outputs.subnets[0].id
    privateIpAddress: '10.0.20.4'
    publicIpId: linux1PublicIp.outputs.ipId
    publisher: linuxPublisher
    offer: linuxOffer
    sku: linuxSku
  }
}

module linux2PublicIp 'modules/publicip.bicep' = {
  name: 'linux2PublicIp'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    publicIpAddressName: linux2PublicIpName
  }
  dependsOn: [
    spoke1ResourceGroup
  ]
}

module spoke1LinuxVM2 'modules/virtualmachine.bicep' = {
  name: 'spoke1LinuxVirtualMachine2'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    virtualMachineName: linux2ComputerName
    osDiskType: 'Standard_LRS'
    computerName: linux2ComputerName
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: spoke1Vnet.outputs.subnets[0].id
    privateIpAddress: '10.0.20.5'
    publicIpId: linux2PublicIp.outputs.ipId
    publisher: linuxPublisher
    offer: linuxOffer
    sku: linuxSku
  }
}



