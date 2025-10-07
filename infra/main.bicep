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
param keyVaultEnablePurgeProtection bool

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

// Create App Service Plan inside RG
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
  }
  // No need for dependsOn as it is automatically linked due to output dependencies
}

// Key Vault with Web App access
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
    keyVaultEnablePurgeProtection: keyVaultEnablePurgeProtection
    webAppPrincipalId: app.outputs.webAppPrincipalId
  }
}
