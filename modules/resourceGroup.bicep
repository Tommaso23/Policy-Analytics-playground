targetScope = 'subscription'

param location string
param rgName string


resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2021-08-01' = {
  name: 'myAKSCluster'
  location: location
  properties: {
    kubernetesVersion: '1.21.2'
    nodeResourceGroup: resourceGroup
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
      }
    ]
    networkProfile: {
      networkPlugin: ''
    }
  }
}
