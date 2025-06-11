param fwPolicyName string
param firewallPublicIp string
var spokeToSpokeRuleCollectionGroupName = 'rcg-spokeToSpoke'
var spokeToInternetRuleCollectionGroupName = 'rcg-spokeToInternet'
var DNATRuleCollectionGroupName = 'rcg-dnat'
var spokeToInternetDuplicatedRuleCollectionGroupName = 'rcg-spokeToInternetDuplicated'

var dnatRuleCollections = [
  {
    name: 'rc-spoke1dnat'
    priority: 100
    ruleCollectionType: 'FirewallPolicyNatRuleCollection'
    action: {
      type: 'Dnat'
    }
    rules: [
      {
        ruleType: 'NatRule'
        name: 'ssh-lnx01'
        translatedAddress: '10.0.20.4'
        translatedPort: '22'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
          firewallPublicIp
        ]
        destinationPorts: [
          '22'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
      {
        ruleType: 'NatRule'
        name: 'ssh-lnx02'
        translatedAddress: '10.0.20.5'
        translatedPort: '22'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
            firewallPublicIp
        ]
        destinationPorts: [
          '23'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
    ]
  }
  {
    name: 'rc-spoke2dnat'
    priority: 200
    ruleCollectionType: 'FirewallPolicyNatRuleCollection'
    action: {
      type: 'Dnat'
    }
    rules: [
      {
        ruleType: 'NatRule'
        name: 'rdp-win01'
        translatedAddress: '10.0.30.4'
        translatedPort: '3389'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
          firewallPublicIp
        ]
        destinationPorts: [
          '3389'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
      {
        ruleType: 'NatRule'
        name: 'rdp-win02'
        translatedAddress: '10.0.30.5'
        translatedPort: '3389'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
          firewallPublicIp
        ]
        destinationPorts: [
          '3390'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
      {
        ruleType: 'NatRule'
        name: 'https-win01'
        translatedAddress: '10.0.30.4'
        translatedPort: '80'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
          firewallPublicIp
        ]
        destinationPorts: [
          '80'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
      {
        ruleType: 'NatRule'
        name: 'https-win02'
        translatedAddress: '10.0.30.5'
        translatedPort: '80'
        sourceAddresses: [
          '*'
        ]
        destinationAddresses: [
          firewallPublicIp
        ]
        destinationPorts: [
          '8080'
        ]
        ipProtocols: [
          'TCP'
        ]
      }
    ]
  }
]

var spokeToSpokeRuleCollections = [
  {
    name: 'rc-spoke1ToSpoke2'
    priority: 100
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        
        ruleType: 'NetworkRule'
        name: 'http-win'
        destinationAddresses: [
          '10.0.30.0/24'
        ]
        destinationPorts: [
          '80'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.20.0/28'
          '10.0.20.16/28'
          '10.0.20.32/28'
          '10.0.20.48/28'
          '10.0.20.64/28'
          '10.0.20.80/28'
          '10.0.20.96/28'
          '10.0.20.112/28'
          '10.0.20.128/28'
          '10.0.20.144/28'
          '10.0.20.160/28'
          '10.0.20.176/28'
          '10.0.20.192/28'
          '10.0.20.208/28'
          '10.0.20.224/28'
          '10.0.20.240/28'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'rdp-win'
        destinationAddresses: [
          '10.0.30.0/27'
        ]
        destinationPorts: [
          '3389'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'rdp-win-dup'
        destinationAddresses: [
          '10.0.30.0/24'
        ]
        destinationPorts: [
          '3389'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'icmp-win'
        destinationAddresses: [
          '10.0.30.0/27'
        ]
        destinationPorts: [
          '*'
        ]
        ipProtocols: [
          'ICMP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'icmp-win-dup'
        destinationAddresses: [
          '10.0.30.0/24'
        ]
        destinationPorts: [
          '*'
        ]
        ipProtocols: [
          'ICMP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'icmp-win-dup2'
        destinationAddresses: [
          '10.0.30.0/25'
          '10.0.30.0/25'
        ]
        destinationPorts: [
          '*'
        ]
        ipProtocols: [
          'ICMP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
    ]
  }
  {
    name: 'rc-spoke2ToSpoke1'
    priority: 200
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'NetworkRule'
        name: 'ssh-lnx'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '22'
        ]
        ipProtocols: [
          'Any'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'icmp-lnx'
        destinationAddresses: [
          '*'
        ]
        destinationPorts: [
          '*'
        ]
        ipProtocols: [
          'ICMP'
        ]
        sourceAddresses: [
          '10.0.30.0/27'
        ]
      }
    ]
  }
]
/*
var spokeToDCRuleCollections = [
  {
    name: 'rc-spoke1ToDC'
    priority: 100
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'NetworkRule'
        name: 'DNS-lnx'
        destinationAddresses: [
          '10.0.20.0/27'
        ]
        destinationPorts: [
          '53'
          '54'
        ]
        ipProtocols: [
          'Any'
        ]
        sourceAddresses: [
          '10.0.20.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'DNS-lnx-dup'
        destinationAddresses: [
          '10.0.20.0/27'
        ]
        destinationPorts: [
          '53'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
    ]
  }
  {
    name: 'rc-spoke2ToDC'
    priority: 200
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'NetworkRule'
        name: 'ldap-win'
        destinationAddresses: [
          '10.0.20.0/28'
          '10.0.20.16/28'
          '10.0.20.32/28'
          '10.0.20.48/28'
          '10.0.20.64/28'
          '10.0.20.80/28'
          '10.0.20.96/28'
          '10.0.20.112/28'
          '10.0.20.128/28'
          '10.0.20.144/28'
          '10.0.20.160/28'
          '10.0.20.176/28'
          '10.0.20.192/28'
          '10.0.20.208/28'
          '10.0.20.224/28'
          '10.0.20.240/28'
        ]
        destinationPorts: [
          '389'
          '636'
        ]
        ipProtocols: [
          'Any'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'ldapgc-win'
        destinationAddresses: [
          '10.0.20.0/26'
          '10.0.20.64/26'
          '10.0.20.128/26'
          '10.0.20.192/26'
        ]
        destinationPorts: [
          '3268'
          '3269'
        ]
        ipProtocols: [
          'TCP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'kerberos-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '88'
          '464'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'dns-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '53'
        ]
        ipProtocols: [
          'TCP'
          'UDP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'smb-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '445'
        ]
        ipProtocols: [
          'Any'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'replication-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '25'
          '135'
        ]
        ipProtocols: [
          'TCP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'dynamic-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '49152-65535'
        ]
        ipProtocols: [
          'TCP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'time-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '123'
        ]
        ipProtocols: [
          'UDP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'dfsnetl-win'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '137-139'
        ]
        ipProtocols: [
          'UDP'
          'TCP'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
      {
        ruleType: 'NetworkRule'
        name: 'dfsnetl-win-dup'
        destinationAddresses: [
          '10.0.20.0/24'
        ]
        destinationPorts: [
          '137-139'
        ]
        ipProtocols: [
          'Any'
        ]
        sourceAddresses: [
          '10.0.30.0/24'
        ]
      }
    ]
  }
]*/

var spokeToInternetRuleCollections = [
  {
    name: 'rc-spoke1ToInternet'
    priority: 100
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'google-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
        ]
        targetFqdns: [
          '*.google.com'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'youtube-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        targetFqdns: [
          '*.youtube.com'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'websearchengines-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'searchenginesandportals'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'websocialnetworking-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'socialnetworking'
        ]
        sourceAddresses: [
            '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webnews-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'news'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webgambling-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'gambling'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webalcohol-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'alcoholandtobacco'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'ubuntuarchive-lnx'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        targetFqdns: [
          'archive.ubuntu.com'
          'security.ubuntu.com'
        ]
        sourceAddresses: [
          '10.0.20.0/27'
        ]
      }
    ]
  }
  {
    name: 'rc-spoke2ToInternet'
    priority: 200
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'windowsupdates-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        fqdnTags: [
          'WindowsUpdate'
        ]
        sourceAddresses: [
          '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'google-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
        ]
        targetFqdns: [
          '*.google.com'
        ]
        sourceAddresses: [
            '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'youtube-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        targetFqdns: [
          '*.youtube.com'
        ]
        sourceAddresses: [
            '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'websearchengines-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'searchenginesandportals'
        ]
        sourceAddresses: [
            '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'websocialnetworking-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'socialnetworking'
        ]
        sourceAddresses: [
            '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webnews-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'news'
        ]
        sourceAddresses: [
            '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webgambling-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'gambling'
        ]
        sourceAddresses: [
          '10.0.30.0/27'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'webalcohol-win'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'alcoholandtobacco'
        ]
        sourceAddresses: [
          '10.0.30.0/27'
        ]
      }
    ]
  }
]

var spokeToInternetDuplicatedRuleCollections = [
  {
    name: 'rc-spoke1ToInternet-dup'
    priority: 100
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: [
      {
        ruleType: 'ApplicationRule'
        name: 'google-lnx-dup'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
        ]
        targetFqdns: [
          '*.google.com'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'youtube-lnx-dup'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        targetFqdns: [
          '*.youtube.com'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
      {
        ruleType: 'ApplicationRule'
        name: 'websearchengines-lnx-dup'
        protocols: [
          {
            protocolType: 'Https'
            port: 443
          }
          {
            protocolType: 'Http'
            port: 80
          }
        ]
        webCategories: [
          'searchenginesandportals'
        ]
        sourceAddresses: [
          '10.0.20.0/29'
          '10.0.20.8/29'
          '10.0.20.16/29'
          '10.0.20.32/29'
        ]
      }
    ]
  }
]



resource DNATRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-07-01' = {
  name: '${fwPolicyName}/${DNATRuleCollectionGroupName}'
  properties: {
    priority: 1000
    ruleCollections: dnatRuleCollections
  }
}

resource spokeToSpokeRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: '${fwPolicyName}/${spokeToSpokeRuleCollectionGroupName}'
  properties: {
    priority: 2000
    ruleCollections: spokeToSpokeRuleCollections
  }
  dependsOn: [
    DNATRuleCollectionGroup
  ]
}

resource spokeToInternetRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: '${fwPolicyName}/${spokeToInternetRuleCollectionGroupName}'
  properties: {
    priority: 4000
    ruleCollections: spokeToInternetRuleCollections
  }
  dependsOn: [
    spokeToSpokeRuleCollectionGroup
  ]
}

resource spokeToInternetDuplicatedRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: '${fwPolicyName}/${spokeToInternetDuplicatedRuleCollectionGroupName}'
  properties: {
    priority: 5000
    ruleCollections: spokeToInternetDuplicatedRuleCollections
  }
  dependsOn: [
    spokeToInternetRuleCollectionGroup
  ]
}


