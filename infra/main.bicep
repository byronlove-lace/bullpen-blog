targetScope = 'subscription'

param resourceGroupName string
param resourceGroupLocation string
param resourceGroupTags object
param planName string
param appName string
param keyVaultName string
param keyVaultTags object
param keyVaultSkuFamily string
param keyVaultSkuName string
param planSkuName string
param planSkuTier string
param webAppKind string
param webAppManagedServiceIdentityType string
param webAppHttpsOnly bool
param keyVaultEnabledForDeployment bool
param keyVaultEnableSoftDelete bool
param keyVaultEnableRbac bool
#disable-next-line secure-secrets-in-params
param keyVaultSecretsOfficerRoleId string
param officerPrincipalId string
param createKeyVault bool
param sqlDBName string
param sqlDBAdminUsername string
@secure()
param sqlDBAdminPassword string
param sqlServerName string
param createDatabase bool
param createAppServicePlan bool
param createApp bool
param sqlServerBackupRetentionDays int
param sqlServerGeoRedundantBackup string
param sqlServerCreateMode string
param sqlServerDataEncryptionType string
param sqlServerHighAvailabilityMode string
param sqlServerPublicNetworkAccess string
param sqlServerAutoGrow string
param sqlServerInitialStorageSizeGB int
param sqlServerStorageType string
param postgresqlVersion string
param sqlServerSkuName string
param sqlServerSkuTier string
param planKind string
param planReserved bool
param prodWebAppHost string
param prodMailServer string
param prodMailLogin string
param webAppLinuxFxVersion string
param webAppPublicNetworkAccess string
param webAppReserved bool
param webAppClientCertEnabled bool
param webAppClientAffinity bool
param flaskConfig string

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
    sqlServerName: sqlServerName
    createDatabase: createDatabase
    sqlServerBackupRetentionDays: sqlServerBackupRetentionDays
    sqlServerGeoRedundantBackup: sqlServerGeoRedundantBackup
    sqlServerCreateMode: sqlServerCreateMode
    sqlServerDataEncryptionType: sqlServerDataEncryptionType
    sqlServerHighAvailabilityMode: sqlServerHighAvailabilityMode
    sqlServerPublicNetworkAccess: sqlServerPublicNetworkAccess
    sqlServerAutoGrow: sqlServerAutoGrow
    sqlServerInitialStorageSizeGB: sqlServerInitialStorageSizeGB
    sqlServerStorageType: sqlServerStorageType
    postgresqlVersion: postgresqlVersion
    sqlServerSkuName: sqlServerSkuName
    sqlServerSkuTier: sqlServerSkuTier
  }
}

module plan 'app-service-plan.bicep' = {
  name: 'planModule'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    planName: planName
    planKind: planKind
    planSkuName: planSkuName
    planSkuTier: planSkuTier
    planReserved: planReserved
    resourceGroupLocation: resourceGroupLocation
    createAppServicePlan: createAppServicePlan
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
    webAppClientAffinity: webAppClientAffinity
    webAppHttpsOnly: webAppHttpsOnly
    webAppManagedServiceIdentityType: webAppManagedServiceIdentityType
    createApp: createApp
    prodWebAppHost: prodWebAppHost
    prodMailServer: prodMailServer
    prodMailLogin: prodMailLogin
    webAppLinuxFxVersion: webAppLinuxFxVersion
    webAppPublicNetworkAccess: webAppPublicNetworkAccess
    webAppReserved: webAppReserved
    webAppClientCertEnabled: webAppClientCertEnabled
    flaskConfig: flaskConfig
  }
  // No need for dependsOn as it is automatically linked due to output dependencies
}

