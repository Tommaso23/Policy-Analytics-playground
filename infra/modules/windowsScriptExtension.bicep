param windowsVirtualMachineName string
param location string

resource windowsVirtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: windowsVirtualMachineName
}

resource taskSchedulerExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: windowsVirtualMachine
  name: 'setupScheduledTask'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "${inlineScript}"'
    }
  }
}

var inlineScript = '''
$scriptPath = "C:\\ScheduledTasks\\monitor.ps1"
New-Item -Path "C:\\ScheduledTasks" -ItemType Directory -Force | Out-Null

$scriptContent = @"
# Define the URLs and IPs
\$urls = @("https://youtube.com", "https://reddit.com", "https://jackdaniels.com")

# Make HTTP requests
foreach (\$url in \$urls) {
    try {
        \$response = Invoke-WebRequest -Uri \$url
        Write-Output "Successfully accessed \$url"
    } catch {
        Write-Output "Failed to access \$url"
    }
}

# Ping IP address with SSH
try {
    \$ping = Test-NetConnection -ComputerName 10.0.20.5 -Port 22
    if (\$ping.PingSucceeded) {
        Write-Output "Successfully pinged 10.0.20.5"
    } else {
        Write-Output "Failed to ping 10.0.20.5"
    }
} catch {
    Write-Output "Error pinging 10.0.20.5"
}

# Ping IP address with ICMP
try {
    \$ping = Test-NetConnection -ComputerName 10.0.20.4
    if (\$ping.PingSucceeded) {
        Write-Output "Successfully pinged 10.0.20.4"
    } else {
        Write-Output "Failed to ping 10.0.20.4"
    }
} catch {
    Write-Output "Error pinging 10.0.20.4"
}
"@

Set-Content -Path $scriptPath -Value $scriptContent

# Register scheduled task
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "ConnectivityMonitor" -Action $action -Trigger $trigger -Principal $principal -Force
'''
