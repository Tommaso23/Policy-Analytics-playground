param name string
param location string
param securityRules array

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: name
  location: location
  properties: {
    securityRules: securityRules
  }
}

output nsgId string = networkSecurityGroup.id
