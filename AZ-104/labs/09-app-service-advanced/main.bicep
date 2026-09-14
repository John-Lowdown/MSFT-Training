// AZ-104 Lab 09: App Service — Deployment Slots & VNet Integration
// Domain: Deploy and manage Azure compute resources — Create and configure Azure App Service
// Cost: REAL and NOT cheap if left running — Standard S1 is roughly $0.10/hour, which is about
//       $70/month if left running. This is the most expensive "just sitting there" lab in the
//       AZ-104 set after Bastion. Delete it the same day, or at minimum scale the plan down
//       immediately after the demo.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab09 --location eastus
//   az deployment group create --resource-group rg-az104-lab09 --template-file main.bicep \
//     --parameters webAppName=az104lab09<your-initials>

@description('Globally-unique name for the web app (becomes <name>.azurewebsites.net)')
param webAppName string

@description('Azure region')
param location string = resourceGroup().location

var vnetAddressPrefix = '10.42.0.0/24'
var subnetAddressPrefix = '10.42.0.0/26'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-az104lab09'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        // Delegated to Microsoft.Web/serverFarms — required before a Web App's
        // regional VNet integration can attach to this subnet at all.
        name: 'snet-appservice-integration'
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'webapp-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab09-app-service-advanced'
  }
}

// Standard (S1) or above is a hard platform requirement for deployment slots — not a
// preference, a tier gate. AZ-900 Lab 6 used F1 (Free) and could never have slots.
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-az104lab09'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    reserved: true // Linux plan
  }
  kind: 'linux'
  tags: {
    course: 'AZ-104'
    lab: 'lab09-app-service-advanced'
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    // Regional VNet integration: lets this app's OUTBOUND traffic reach resources inside
    // the VNet (e.g. a private database). It does NOT by itself make the app's INBOUND
    // traffic private — that's what a private endpoint on the app would add, on the
    // inbound side, which is out of scope for this lab.
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      httpsOnly: true
    }
    httpsOnly: true
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab09-app-service-advanced'
  }
}

// A deployment slot is a fully separate, fully running App Service instance with its own
// hostname — it shares the parent plan's compute, not a copy of the production app's state.
resource stagingSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: webApp
  name: 'staging'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      httpsOnly: true
    }
    httpsOnly: true
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab09-app-service-advanced'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output stagingSlotUrl string = 'https://${stagingSlot.properties.defaultHostName}'
output planTier string = appServicePlan.sku.name
output vnetIntegrationSubnetId string = vnet.properties.subnets[0].id
