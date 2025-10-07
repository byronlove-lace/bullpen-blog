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

@description('Enables Azure RBAC authorization for Key Vault. When true, role assignments control access to keys, secrets, and certificates instead of access policies.')
param keyVaultEnableRbac bool

@description('The built-in role definition ID for Key Vault Secrets User. This role allows a principal to read secret values from a Key Vault when RBAC authorization is enabled.')
param keyVaultSecretsUserRoleId string

@description('The built-in Azure RBAC role ID for "Key Vault Secrets Officer". This role lets a principal manage secrets (create, delete, set attributes, read).')
param keyVaultSecretsOfficerRoleId string

@description('The object ID of the human or service principal that should have Key Vault Officer access')
param officerPrincipalId string

@description('Determines whether the Key Vault should be created. Set to true to create a new Key Vault, or false to skip creation if one already exists.')
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
    enablePurgeProtection: keyVaultEnablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
  }
}

resource keyVaultSecretsOfficerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: 'subscription'
    name: keyVaultSecretsOfficerRoleId
    dependsOn: [
      keyVault
    ]
}

// existing because we a referencing a built-in role
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
    scope: 'subscription'
    name: keyVaultSecretsUserRoleId
    dependsOn: [
      keyVault
    ]
}

// Assign yourself as Key Vault Secrets Officer
resource keyVaultSecretsOfficerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, officerPrincipalId, keyVaultSecretsOfficerRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsOfficerRoleId
    principalId: officerPrincipalId
  }
  dependsOn: [
    keyVaultSecretsOfficerRole
  ]
}
