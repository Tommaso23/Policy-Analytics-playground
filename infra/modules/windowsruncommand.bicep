param vmName string
param location string


resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: '${vmName}/CreateAutomationTask'
  location: location
  properties: {
    source: {
      script: '''
# Ensure scripts directory exists
New-Item -Path "C:\\scripts" -ItemType Directory -Force | Out-Null

# Write automation.ps1 inline
@'
# Example automation script
$urls = @("https://google.com", "https://reddit.com", "https://jackdaniels.com")

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        "[$(Get-Date)] SUCCESS: $url" | Out-File C:\\scripts\\log.txt -Append
    } catch {
        "[$(Get-Date)] FAILED: $url" | Out-File C:\\scripts\\log.txt -Append
    }
}

try {
    $sshTarget = "10.0.20.5"
    $pingSSH = Test-NetConnection -ComputerName $sshTarget -Port 22 -WarningAction SilentlyContinue
    if ($pingSSH.TcpTestSucceeded) {
        "[$(Get-Date)] SUCCESS: TCP 22 reachable on $sshTarget" | Out-File C:\\scripts\\log.txt -Append
    } else {
        "[$(Get-Date)] FAILED: TCP 22 not reachable on $sshTarget" | Out-File C:\\scripts\\log.txt -Append
    }
} catch {
    "[$(Get-Date)] ERROR: Could not test TCP 22 on $sshTarget" | Out-File C:\\scripts\\log.txt -Append
}
    try {
    $icmpTarget = "10.0.20.4"
    $ping = Test-NetConnection -ComputerName $icmpTarget -WarningAction SilentlyContinue
    if ($ping.PingSucceeded) {
        "[$(Get-Date)] SUCCESS: ICMP reachable on $icmpTarget" | Out-File C:\\scripts\\log.txt -Append
    } else {
        "[$(Get-Date)] FAILED: ICMP not reachable on $icmpTarget" | Out-File C:\\scripts\\log.txt -Append
    }
} catch {
    "[$(Get-Date)] ERROR: Could not test ICMP on $icmpTarget" | Out-File C:\\scripts\\log.txt -Append
}
'@ | Set-Content -Path "C:\\scripts\\automation.ps1" -Force

# Define Scheduled Task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\\scripts\\automation.ps1"

# Trigger every 5 minutes, for 90 days
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
  -RepetitionInterval (New-TimeSpan -Minutes 10) `
  -RepetitionDuration (New-TimeSpan -Days 90)

# Register scheduled task
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "AutomationTask" -Description "Runs automation.ps1 every 5 minutes for 3 months" -User "SYSTEM" -RunLevel Highest -Force
'''
    }
  }
}

