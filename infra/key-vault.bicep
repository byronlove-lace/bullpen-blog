param keyVaultName string

@description('Location of the Key Vault')
param resourceGroupLocation string

@description('Optional tags')
param keyVaultTags object

@description('The SKU family for the Key Vault, e.g., "A". Determines the hardware family and general performance characteristics.')
param keyVaultSkuFamily string

@description('The SKU name for the Key Vault, e.g., "standard" or "premium". Determines available features and performance tier.')
param keyVaultSkuName string

@description('Allow Azure services (like App Service) to retrieve secrets during deployment.')
param keyVaultEnabledForDeployment bool

@description('Retains the Key Vault and its contents after deletion, allowing recovery within the retention period.')
param keyVaultEnableSoftDelete bool

@description('Enables Azure RBAC authorization for Key Vault. When true, role assignments control access to keys, secrets, and certificates instead of access policies.')
param keyVaultEnableRbac bool

@description('The built-in Azure RBAC role ID for "Key Vault Secrets Officer". This role lets a principal manage secrets (create, delete, set attributes, read).')
#disable-next-line secure-secrets-in-params
param keyVaultSecretsOfficerRoleId string

@description('The object ID of the human or service principal that should have Key Vault Officer access')
param officerPrincipalId string

param createKeyVault bool

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = if (createKeyVault) {
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
    enableRbacAuthorization: keyVaultEnableRbac
  }
}

// Assign yourself as Key Vault Secrets Officer
resource keyVaultSecretsOfficerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (createKeyVault) {
  name: guid(keyVault.id, officerPrincipalId, keyVaultSecretsOfficerRoleId)
  scope: keyVault
  properties: {
    //subscriptionResourceId necessary for ARM preffered formatting
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsOfficerRoleId)
    principalId: officerPrincipalId
  }
}
