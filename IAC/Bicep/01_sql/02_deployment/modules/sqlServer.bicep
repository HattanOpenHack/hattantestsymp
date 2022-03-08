param name string
param location string
param environment string
param administratorLogin string

@secure()
param administratorLoginPassword string

// SQL SERVER

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers?tabs=bicep
resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: name
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    version: '12.0'
  }
  tags:{
    'Env': environment
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/servers/firewallrules?tabs=bicep
resource sqlFirewallRuleAzure 'Microsoft.Sql/servers/firewallRules@2021-08-01-preview' = {
  parent: sqlServer
  name: 'AzureAccess'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output id string = sqlServer.id
output name string = sqlServer.name
output fqdn string = sqlServer.properties.fullyQualifiedDomainName