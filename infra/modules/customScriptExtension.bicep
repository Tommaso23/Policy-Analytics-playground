param vmName string
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' existing = {
  name: vmName
}

resource taskSchedulerExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${vm.name}/setupScheduledTask'
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
    \$ping = Test-NetConnection -ComputerName 10.0.30.5 -Port 22
    if (\$ping.PingSucceeded) {
        Write-Output "Successfully pinged 10.0.30.5"
    } else {
        Write-Output "Failed to ping 10.0.30.5"
    }
} catch {
    Write-Output "Error pinging 10.0.30.5"
}

# Ping IP address with ICMP
try {
    \$ping = Test-NetConnection -ComputerName 10.0.30.40
    if (\$ping.PingSucceeded) {
        Write-Output "Successfully pinged 10.0.30.40"
    } else {
        Write-Output "Failed to ping 10.0.30.40"
    }
} catch {
    Write-Output "Error pinging 10.0.30.40"
}
"@

Set-Content -Path $scriptPath -Value $scriptContent

# Register scheduled task
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "ConnectivityMonitor" -Action $action -Trigger $trigger -Principal $principal -Force
'''


param vmName string
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' existing = {
  name: vmName
}

resource cronJobExtension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${vm.name}/installCronJobs'
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

var cronJobScript = '''
#!/bin/bash

echo "Aggiunta cron jobs..."

# Salva cron esistente + aggiunte
(crontab -l 2>/dev/null; cat <<EOF
*/5 * * * * nc -w4 10.0.40.4 443
*/5 * * * * nc -w4 10.0.40.5 443
*/20 * * * * nc -w4 72.146.64.19 443
*/20 * * * * nc -w4 72.146.64.19 8443
*/20 * * * * ping -c4 10.0.40.4
*/20 * * * * ping -c4 10.0.40.5
*/5 * * * * nc -w4 10.0.40.4 3389
*/5 * * * * nc -w4 10.0.40.5 3389
*/20 * * * * nslookup google.com && nslookup microsoft.com && nslookup azure.com && nslookup bing.com && nslookup youtube.com
*/20 * * * * curl -IL https://google.com
*/20 * * * * curl -IL https://bing.com
*/20 * * * * curl -IL https://ilcorriere.it
*/20 * * * * curl -IL https://snai.it
EOF
) | crontab -
'''

