targetScope = 'resourceGroup'

param createDatabase bool
param sqlDBName string
param resourceGroupLocation string

@description('The administrator username of the SQL logical server.')
param sqlDBAdminUsername string

@description('The administrator password of the SQL logical server.')
@secure()
param sqlDBAdminPassword string

param sqlServerName string

@description('Number of days to retain backups.')
param sqlServerBackupRetentionDays int

param sqlServerGeoRedundantBackup string

@description('Server creation mode ("Default" for new server, "PointInTimeRestore", etc.).')
param sqlServerCreateMode string

@description('How data encryption is managed.')
param sqlServerDataEncryptionType string

@description('"Disabled", "ZoneRedundant", "SameZone".')
param sqlServerHighAvailabilityMode string

@description('Public network access ("Enabled" or "Disabled").')
param sqlServerPublicNetworkAccess string

@description('Enable storage auto-grow ("Enabled" or "Disabled").')
param sqlServerAutoGrow string

param sqlServerInitialStorageSizeGB int

@description('Storage type ("GP_Gen5", "MO_Gen5", etc.).')
param sqlServerStorageType string

@description('PostgreSQL version number (e.g., 17 for 17.x).')
param postgresqlVersion string

@description('SKU name (defines compute size, e.g., Standard_B1ms).')
param sqlServerSkuName string

@description('SKU tier (matches tier category, e.g., Burstable, GeneralPurpose).')
param sqlServerSkuTier string

resource sqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = if (createDatabase) {
  name: sqlServerName
  location: resourceGroupLocation
  properties: {
    administratorLogin: sqlDBAdminUsername
    administratorLoginPassword: sqlDBAdminPassword
    backup: {
      backupRetentionDays: sqlServerBackupRetentionDays
      geoRedundantBackup: sqlServerGeoRedundantBackup
    }
    createMode: sqlServerCreateMode
    dataEncryption: {
      type: sqlServerDataEncryptionType
    }
    highAvailability: {
      mode: sqlServerHighAvailabilityMode
    }
    network: {
      // add delegatedSubnetResourceId and privateDnsZoneArmResourceId later for Private Endpoints
      publicNetworkAccess: sqlServerPublicNetworkAccess
    }
    storage: {
      autoGrow: sqlServerAutoGrow
      storageSizeGB: sqlServerInitialStorageSizeGB
      type: sqlServerStorageType
    }
    version: postgresqlVersion
  }
  sku: {
        name: sqlServerSkuName
        tier: sqlServerSkuTier
       }
}

resource sqlDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = if (createDatabase) {
  parent: sqlServer
  name: sqlDBName
}
