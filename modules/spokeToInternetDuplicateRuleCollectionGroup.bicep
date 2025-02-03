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
          '10.0.30.0/29'
          '10.0.30.8/29'
          '10.0.30.16/29'
          '10.0.30.32/29'
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
          '10.0.30.0/29'
          '10.0.30.8/29'
          '10.0.30.16/29'
          '10.0.30.32/29'
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
          '10.0.30.0/29'
          '10.0.30.8/29'
          '10.0.30.16/29'
          '10.0.30.32/29'
        ]
      }
    ]
  }
]


resource spokeToInternetDuplicatedRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: '${fwPolicyName}/${spokeToInternetDuplicatedRuleCollectionGroupName}'
  dependsOn: [
    spokeToInternetRuleCollectionGroup
  ]
  properties: {
    priority: 5000
    ruleCollections: spokeToInternetDuplicatedRuleCollections
  }
}

