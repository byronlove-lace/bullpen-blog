targetScope = 'resourceGroup'

param planName string
@description('The specific SKU name for the App Service Plan instance. Determines size and capacity, e.g., B1, S1, P1v3.')
param planSkuName string

@description('The pricing tier for the App Service Plan. Determines feature set, e.g., Basic, Standard, Premium.')
param planSkuTier string

@description('Location of the App Service Plan')
param resourceGroupLocation string

@description('Whether the plan is Linux')
param isLinux bool

@description('Create plan if one does not already exist')
param createAppServicePlan bool

@description('App Service Plan resource defining the compute and pricing tier for hosting Web Apps')
resource appServicePlan 'Microsoft.Web/serverFarms@2024-11-01' = if (createAppServicePlan) {
  name: planName
  location: resourceGroupLocation
  sku: {
    name: planSkuName
    tier: planSkuTier
  }
  kind: isLinux ? 'linux' : 'app'
  properties: {
    reserved: isLinux
  }
}

@description('App Service Plan resource defining the compute and pricing tier for hosting Web Apps')
output planId string = appServicePlan.id
