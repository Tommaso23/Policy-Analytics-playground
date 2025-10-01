param vmName string
param location string


resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: '${vmName}/CreateCronJob'
  location: location
  properties: {
    source: {
      script: '''
'''
    }
  }
}

