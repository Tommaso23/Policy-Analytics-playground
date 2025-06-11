
/*
resource cse 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${vm.name}/CreateScheduledTask'
  location: vm.location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://<your-storage-account>.blob.core.windows.net/scripts/create-task.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File create-task.ps1'
    }
  }
}*/
