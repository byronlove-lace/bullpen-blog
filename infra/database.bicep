targetScope = 'resourceGroup'

param env string
param sqlDBSkuName string
param sqlDBSkuTier string
param createDatabase bool

param sqlDBName string
param resourceGroupLocation string

@description('The administrator username of the SQL logical server.')
param sqlDBAdminUsername string

@description('The administrator password of the SQL logical server.')
@secure()
param sqlDBAdminPassword string

// Logic included here rather than deploy because resourceGroup().id cannot be resolved post creation but pre creation of db
var sqlServerName string = uniqueString('sql', resourceGroup().id, env)

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = if (createDatabase) {
  name: sqlServerName
  location: resourceGroupLocation
  properties: {
    administratorLogin: sqlDBAdminUsername
    administratorLoginPassword: sqlDBAdminPassword
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2021-11-01' = if (createDatabase) {
  parent: sqlServer
  name: sqlDBName
  location: resourceGroupLocation
  sku: {
    name: sqlDBSkuName
    tier: sqlDBSkuTier
  }
}
