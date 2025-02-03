targetScope = 'subscription'

param location string = 'italynorth'

/*Resource Groups*/
var hubRgName = 'rg-hub-in'
var spoke1RgName = 'rg-spoke1-in'
var spoke2RgName = 'rg-spoke2-in'
var automationRgName = 'rg-automation-in'
var identityRgName = 'rg-identity-in'


/*VNets*/
var hubVnetName = 'vnet-hub-in'
var identityVnetName = 'vnet-identity-in'
var spoke1VnetName = 'vnet-spoke1-in'
var spoke2VnetName = 'vnet-spoke2-in'


var hubVnetAddrPrefix = '10.0.10.0/24'
var identityVnetAddrPrefix = '10.0.20.0/24'
var spoke1VnetAddrPrefix = '10.0.30.0/24'
var spoke2VnetAddrPrefix = '10.0.40.0/24'



var hubSubnet = [
  {
    subnetAddrPrefix: hubVnetAddrPrefix
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
    vnetName: identityVnetName
    nsgId: ''
    routeTableId: ''
  }
]

var spoke1Subnet = [
  {
    subnetAddrPrefix: spoke1VnetAddrPrefix
    subnetName: 'snet-linux-vms'
    nsgId: ''
    routeTableId: ''
  }
]

var spoke2Subnet = [
  {
    subnetAddrPrefix: spoke2VnetAddrPrefix
    subnetName: 'snet-win-vms'
    nsgId: ''
    routeTableId: ''
  }
]


param firewallName string = 'myFirewall'
param fwPolicyName string = 'myFirewallPolicy'

module HubResourceGroup 'modules/resourceGroup.bicep' = {
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


module hubVnet 'modules/vnet.bicep' = {
  name: 'hubVnet'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    vnetName: hubVnetName
    vnetAddrPrefix: hubVnetAddrPrefix
    subnetId: hubSubnet.outputs.subnetId
    dnsServer: dcPrivateIp
  }
  dependsOn: [
    hubResourceGroup
  ]
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
