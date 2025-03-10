param location string
param virtualMachineName string
param networkInterfaceName string = 'nic-${virtualMachineName}'
param osDiskType string = 'Standard_LRS'
param virtualMachineSize string = 'Standard_DS1_v2'
param adminUsername string
@secure()
param adminPassword string
param subnetId string
param publicIpId string
param computerName string
param dataDisks array
param privateIpAllocationMethod string = 'Static'
param privateIpAddress string = ''
param publicIpRequired bool

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: privateIpAllocationMethod
          privateIPAddress: privateIpAddress
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = {

}
