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
param privateIpAllocationMethod string = 'Static'
param privateIpAddress string = ''
param publisher string
param offer string
param sku string


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
          publicIPAddress: publicIpId == '' ? null : {
            id: publicIpId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

output virtualMachinePrivateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
