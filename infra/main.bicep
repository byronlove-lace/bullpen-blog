targetScope = 'subscription'

param resourceGroupName string
param resourceGroupLocation string
param resourceGroupTags object
param planName string
param appName string
param isLinux bool
param keyVaultName string
param keyVaultTags object
param keyVaultSkuFamily string
param keyVaultSkuName string
param planSkuName string
param planSkuTier string
param webAppKind string
param webAppTags object
param webAppClientAffinity bool
param webAppManagedServiceIdentityType string
param webAppHttps bool
param keyVaultEnabledForDeployment bool
param keyVaultEnableSoftDelete bool
param keyVaultEnableRbac bool
param keyVaultSecretsUserRoleId string
param keyVaultSecretsOfficerRoleId string
param officerPrincipalId string
param createKeyVault bool
param existingKeyVaultId string
param env string
param sqlDBName string
param sqlDBAdminUsername string
@secure()
param sqlDBAdminPassword string
param sqlDBSkuName string
param sqlDBSkuTier string
param sqlServerName string
param createDatabase bool

// Create resource group
// Note: module paths are relative to THIS file, not run command
module resourceGroup 'resource-group.bicep' = {
  name: 'resourceGroupModule'
  scope: subscription()
  params: {
    resourceGroupName: resourceGroupName
    resourceGroupLocation: resourceGroupLocation
    resourceGroupTags: resourceGroupTags
  }
}

module kv 'key-vault.bicep' = {
  name: 'keyVaultModule'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    keyVaultName: keyVaultName
    resourceGroupLocation: resourceGroupLocation
    keyVaultTags: keyVaultTags
    keyVaultSkuFamily: keyVaultSkuFamily
    keyVaultSkuName: keyVaultSkuName
    keyVaultEnabledForDeployment: keyVaultEnabledForDeployment
    keyVaultEnableSoftDelete: keyVaultEnableSoftDelete
    keyVaultEnableRbac: keyVaultEnableRbac
    keyVaultSecretsOfficerRoleId: keyVaultSecretsOfficerRoleId
    officerPrincipalId: officerPrincipalId
    createKeyVault: createKeyVault
    existingKeyVaultId: existingKeyVaultId
  }
  dependsOn: [
    resourceGroup
  ]
}

module db 'database.bicep' = {
  name: 'databaseModule'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    sqlDBName: sqlDBName
    resourceGroupLocation: resourceGroupLocation
    sqlDBAdminUsername: sqlDBAdminUsername
    sqlDBAdminPassword: sqlDBAdminPassword
    sqlDBSkuName: sqlDBSkuName
    sqlDBSkuTier: sqlDBSkuTier
    sqlServerName: sqlServerName
    env: env
    createDatabase: createDatabase
  }
}

module plan 'app-service-plan.bicep' = {
  name: 'planModule'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    planName: planName
    planSkuName: planSkuName
    planSkuTier: planSkuTier
    resourceGroupLocation: resourceGroupLocation
    isLinux: isLinux
  }
  dependsOn: [
    resourceGroup
  ]
}

// Create Web App inside the same plan
module app 'web-app.bicep' = {
  name: 'webappModule'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    appName: appName
    planId: plan.outputs.planId
    resourceGroupLocation: resourceGroupLocation
    webAppKind: webAppKind
    webAppTags: webAppTags
    webAppClientAffinity: webAppClientAffinity
    webAppHttps : webAppHttps
    webAppManagedServiceIdentityType: webAppManagedServiceIdentityType
    keyVaultId: kv.outputs.keyVaultId
    keyVaultSecretsUserRoleId: keyVaultSecretsUserRoleId
    keyVaultName: keyVaultName
  }
  // No need for dependsOn as it is automatically linked due to output dependencies
}

