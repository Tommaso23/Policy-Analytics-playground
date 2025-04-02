param fwPolicyName string
param rcgName string
param ruleCollections object
param priority int

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-05-01' = {
  name: '${fwPolicyName}/${rcgName}'
  properties: {
    priority: priority
    ruleCollections: [
      ruleCollections
    ]
  }
}
