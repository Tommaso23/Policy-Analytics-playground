# Define the URLs and IPs
$urls = @("https://youtube.com", "https://reddit.com", "https://jackdaniels.com")

# Make HTTP requests
foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url
        Write-Output "Successfully accessed $url"
    } catch {
        Write-Output "Failed to access $url"
    }
}

# Ping IP address with SSH
try {
    $ping = Test-NetConnection -ComputerName 10.0.20.5 -Port 22
    if ($ping.PingSucceeded) {
        Write-Output "Successfully pinged $ip"
    } else {
        Write-Output "Failed to ping $ip"
    }
} catch {
    Write-Output "Error pinging $ip"
}

# Ping Ip address with ICMP
try {
    $ping = Test-NetConnection -ComputerName 10.0.20.4
    if ($ping.PingSucceeded) {
        Write-Output "Successfully pinged $ip"
    } else {
        Write-Output "Failed to ping $ip"
    }
} catch {
    Write-Output "Error pinging $ip"
}