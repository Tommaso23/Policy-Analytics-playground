param virtualMachineName string
param location string 

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: virtualMachineName
}

resource taskSchedulerExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
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


resource cronJobExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: virtualMachine
  name: 'installCronJobs'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      script: base64(cronJobScript)
    }
  }
}

//TODO: Dynamic public IP for Firewall
var cronJobScript = '''
#!/bin/bash

(crontab -l 2>/dev/null; cat <<EOF
*/5 * * * * nc -w4 10.0.30.4 80
*/5 * * * * nc -w4 10.0.30.5 80
*/20 * * * * nc -w4 72.146.64.19 80
*/20 * * * * nc -w4 72.146.64.19 8080
*/20 * * * * ping -c4 10.0.30.4
*/20 * * * * ping -c4 10.0.30.5
*/5 * * * * nc -w4 10.0.30.4 3389
*/5 * * * * nc -w4 10.0.30.5 3389
*/20 * * * * nslookup google.com && nslookup microsoft.com && nslookup azure.com && nslookup bing.com && nslookup youtube.com
*/20 * * * * curl -IL https://google.com
*/20 * * * * curl -IL https://bing.com
*/20 * * * * curl -IL https://ilcorriere.it
*/20 * * * * curl -IL https://snai.it
EOF
) | crontab -
'''

