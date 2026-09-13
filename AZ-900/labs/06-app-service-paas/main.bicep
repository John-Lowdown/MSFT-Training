// AZ-900 Lab 6: App Service (PaaS)
// Domain: Cloud Concepts — IaaS / PaaS / SaaS
// Cost: near-$0 on the Free (F1) tier — no cost if you stay on F1 and delete after the demo.
//       Some capabilities (custom domains, staging slots, autoscale) require Basic (B1) or above,
//       which does carry a small hourly cost — this template defaults to F1.
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az900-lab06 --template-file main.bicep \
//     --parameters webAppName=az900lab06yourinitials

@description('Globally-unique name for the web app (becomes <name>.azurewebsites.net)')
param webAppName string

@description('Azure region')
param location string = resourceGroup().location

@description('App Service Plan SKU. F1 = Free tier (default, $0). B1 = Basic, small hourly cost.')
@allowed([
  'F1'
  'B1'
])
param skuName string = 'F1'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'asp-${webAppName}'
  location: location
  sku: {
    name: skuName
  }
  properties: {
    reserved: true // Linux plan
  }
  kind: 'linux'
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: skuName != 'F1' // Free tier doesn't support Always On
      httpsOnly: true
    }
    httpsOnly: true
  }
  tags: {
    course: 'AZ-900'
    lab: 'lab06-app-service-paas'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output planTier string = skuName
