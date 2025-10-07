param keyVaultName string

@description('Location of the Key Vault')
param resourceGroupLocation string

@description('Optional tags')
param keyVaultTags object

@description('The SKU family for the Key Vault, e.g., "A". Determines the hardware family and general performance characteristics.')
param keyVaultSkuFamily string

@description('The SKU name for the Key Vault, e.g., "standard" or "premium". Determines available features and performance tier.')
param keyVaultSkuName string

@description('The Azure AD principal ID of the Web App’s managed identity. Used by Key Vault to grant access to secrets and keys.')
param webAppPrincipalId string

@description('Allow Azure services (like App Service) to retrieve secrets during deployment.')
param keyVaultEnabledForDeployment bool

@description('Retains the Key Vault and its contents after deletion, allowing recovery within the retention period.')
param keyVaultEnableSoftDelete bool

@description('Prevents the Key Vault from being permanently deleted until the soft-delete retention period expires.')
param keyVaultEnablePurgeProtection bool

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: keyVaultName
  location: resourceGroupLocation
  tags: keyVaultTags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: keyVaultSkuFamily
      name: keyVaultSkuName
    }
    enabledForDeployment: keyVaultEnabledForDeployment
    enableSoftDelete: keyVaultEnableSoftDelete
    enablePurgeProtection: keyVaultEnablePurgeProtection
    accessPolicies: [
      {
        objectId: webAppPrincipalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          keys: []
          certificates: []
        }
      }
    ]
  }
}
