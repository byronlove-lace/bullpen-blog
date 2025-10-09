targetScope = 'resourceGroup'

param appName string

@description('Resource ID of the App Service Plan')
param planId string

@description('Location for the Web App')
param resourceGroupLocation string

@description('Optional tags for the Web App')
param webAppTags object

@description('Specifies the kind of Web App. Typically "app" for Windows apps or "linux" for Linux-based apps.')
param webAppKind string

@description('Enables or disables client affinity (sticky sessions) for the Web App. Typically false for stateless applications.')
param webAppClientAffinity bool

@description('Specifies the type of Managed Service Identity (MSI) for the Web App. Common values: "SystemAssigned", "UserAssigned", or "None". Used to enable the app to authenticate to Azure resources like Key Vault without credentials.')
param webAppManagedServiceIdentityType string

@description('The built-in role definition ID for Key Vault Secrets User. This role allows a principal to read secret values from a Key Vault when RBAC authorization is enabled.')
param keyVaultSecretsUserRoleId string
param keyVaultId string
param keyVaultName string

param webAppHttps bool

resource webApp 'Microsoft.Web/sites@2024-11-01' = {
  name: appName
  location: resourceGroupLocation
  kind: webAppKind
  identity: {
    type: webAppManagedServiceIdentityType
  }
  properties: {
    serverFarmId: planId
    httpsOnly: webAppHttps
    clientAffinityEnabled: webAppClientAffinity
  }
  tags: webAppTags
}

// Reference the Key Vault as an existing resource
resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

// Assign webApp as KeyVaultSecretsUser
resource keyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, webApp.name, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    //subscriptionResourceId necessary for ARM preffered formatting
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: webApp.identity.principalId
  }
}

