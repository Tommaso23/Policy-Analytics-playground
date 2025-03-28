targetScope = 'subscription'

param location string = deployment().location

/*Resource Groups*/
var hubRgName = 'rg-hub-itn'
var spoke1RgName = 'rg-spoke1-itn'
var spoke2RgName = 'rg-spoke2-itn'
var automationRgName = 'rg-automation-itn'

/*VNET*/
var hubVnetName = 'vnet-hub-itn'
var spoke1VnetName = 'vnet-spoke1-itn'
var spoke2VnetName = 'vnet-spoke2-itn'

var hubVnetAddrPrefix = ['10.0.10.0/24']
var spoke1VnetAddrPrefix = ['10.0.20.0/24']
var spoke2VnetAddrPrefix = ['10.0.30.0/24']

/*SUBNET*/
var hubSubnetAddrPrefix = '10.0.10.0/26'
var linuxSubnetAddrPrefix = '10.0.20.0/27' //before: 10.0.30.0/27
var winSubnetAddrPrefix = '10.0.30.0/27'

/*VIRTUAL MACHINE*/
@description('username administrator for all VMs')
param adminUsername string = 'azureuser'

@description('username administrator password for all VMs')
@secure()
param adminPassword string = 'Password123?'

var IIS1ComputerName = 'vm-iis-1-itn'
var IIS2ComputerName = 'vm-iis-2-itn'
var linux1ComputerName = 'vm-lnx-1-itn'
var linux2ComputerName = 'vm-lnx-2-itn'
var linux1PublicIpName = 'pip-${linux1ComputerName}'
var linux2PublicIpName = 'pip-${linux2ComputerName}'


var windowsPublisher = 'MicrosoftWindowsServer'
var windowsOffer = 'WindowsServer'
var windowsSku = '2022-Datacenter-gensecond'

var linuxPublisher = 'canonical'
var linuxOffer = 'ubuntu-24_04-lts'
var linuxSku = 'server'

var spokeVmIISExtensionProperties = {
  publisher: 'Microsoft.Compute'
  type: 'CustomScriptExtension'
  typeHandlerVersion: '1.10'
  autoUpgradeMinorVersion: true
  protectedSettings: {
    commandToExecute: 'powershell.exe Add-WindowsFeature Web-Server; powershell.exe New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation Cert:\\LocalMachine\\My; powershell.exe Import-Module IISAdministration; powershell.exe New-IISSite -Name "Default Web Site" -PhysicalPath "C:\\inetpub\\wwwroot" -BindingInformation "*:443:" -CertificateStoreName "My" -CertificateHash (Get-ChildItem Cert:\\LocalMachine\\My | Where-Object {$_.Subject -match "CN=localhost"}).Thumbprint; powershell.exe Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername); powershell.exe Set-NetFirewallProfile -Enabled False'
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
  routeTableId: ''
}

var spoke2Subnet = {
  subnetAddrPrefix: winSubnetAddrPrefix
  subnetName: 'snet-win-vms'
  nsgId: spoke2Nsg.outputs.nsgId
  routeTableId: ''
}


/*ROUTE TABLE*/
var spoke1RouteTableName = 'rt-spoke1-vnet'
var spoke2RouteTableName = 'rt-spoke2-vnet'

/*FIREWALL*/
var firewallName = 'afw-hub-itn'
var fwTier = 'Premium'
var fwPolicyName = 'afw-policy-hub-itn'

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

// NSG //
module spoke1Nsg 'modules/networkSecurityGroup.bicep' = {
  name: 'spoke1Nsg'
  scope: resourceGroup(spoke1RgName)
  params: {
    location: location
    name: 'nsg-spoke1-in'
  }
}

module spoke2Nsg 'modules/networkSecurityGroup.bicep' = {
  name: 'spoke2Nsg'
  scope: resourceGroup(spoke2RgName)
  params: {
    location: location
    name: 'nsg-spoke2-in'
  }
}


// ROUTE TABLES and ROUTES //
module spoke1RouteTable 'modules/routeTable.bicep' = {
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

module spoke2RouteTable 'modules/routeTable.bicep' = {
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



// FIREWALL //
module azureFirewallPublicIp 'modules/publicIp.bicep' = {
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
    location: 'italynorth'
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



module IIS1 'modules/virtualmachine.bicep' = {
  name: 'IIS-1'
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

module IIS2 'modules/virtualmachine.bicep' = {
  name: 'IIS-2'
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
    IIS1
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
    IIS2
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



