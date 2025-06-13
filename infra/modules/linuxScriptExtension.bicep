param linuxVirtualMachineName string
param location string
param firewallPublicIp string

resource linuxVirtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: linuxVirtualMachineName
}

resource cronJobExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: linuxVirtualMachine
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
*/20 * * * * nc -w4 ${firewallPublicIp} 80
*/20 * * * * nc -w4 ${firewallPublicIp} 8080
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
