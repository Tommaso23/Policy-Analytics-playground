param vmName string
param vmExtensionName string
param location string
param properties object

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${vmName}/${vmExtensionName}'
  location: location
  properties: properties
}
