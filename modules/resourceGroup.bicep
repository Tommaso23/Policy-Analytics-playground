targetScope = 'subscription'

param location string
param rgName string


resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
}
