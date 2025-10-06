targetScope='subscription'

param rg_name string = 'bullpen-blog-rg'
param rg_location string = 'northeurope'
param rg_tags object = {
    Environment: 'Production'
    Project: 'Bullpen Blog'
    Version: '1.0.0'
}

resource bullpen_rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rg_name
  location: rg_location
  tags: rg_tags
}
