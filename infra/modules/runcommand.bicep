param vmName string
param location string


resource deploymentscript 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: '${vmName}/AadAppProxyPrerequisites'
  location: location
  properties: {
    source: {
      script: '''
        # Ensure scripts directory exists
        New-Item -Path "C:\\scripts" -ItemType Directory -Force | Out-Null

        # Download automation.ps1 from GitHub (public repo raw link)
        $scriptUrl = "https://github.com/Tommaso23/Policy-Analytics-playground/tree/main/scripts/automation.ps1"
        $destination = "C:\\scripts\\automation.ps1"
        Invoke-WebRequest -Uri $scriptUrl -OutFile $destination -UseBasicParsing

        # Define Scheduled Task action
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\\scripts\\automation.ps1"

        # Define trigger (every 5 minutes, indefinitely)
        $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]:: -Days 90)

        # Register scheduled task to run as SYSTEM
        Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "AutomationTask" -Description "Runs automation.ps1 every 5 minutes" -User "SYSTEM" -RunLevel Highest -Force '''
    
    }
  }
}
