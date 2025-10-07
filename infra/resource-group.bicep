targetScope = 'subscription'

param resourceGroupName string
param resourceGroupLocation string
param resourceGroupTags object

// Resource definition
resource bullpenResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: resourceGroupTags
}
