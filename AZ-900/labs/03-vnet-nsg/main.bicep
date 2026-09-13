// AZ-900 Lab 3: Virtual Network & NSGs
// Domain: Core Services — Networking
// Cost: $0 — VNets and NSGs are free; you're only charged for compute/data
//       resources attached to them (none are deployed here).
//
// Deploy into an existing resource group:
//   az deployment group create --resource-group rg-az900-lab03 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string = 'vnet-az900-lab03'

@description('Address space for the VNet')
param vnetAddressPrefix string = '10.20.0.0/16'

@description('Address space for the web subnet')
param webSubnetPrefix string = '10.20.1.0/24'

@description('Address space for the data subnet')
param dataSubnetPrefix string = '10.20.2.0/24'

// NSG for the "web" subnet: allow inbound HTTPS from the internet, deny everything else inbound by default
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-az900-lab03-web'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

// NSG for the "data" subnet: only allow inbound from the web subnet, nothing from the internet
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-az900-lab03-data'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-FromWebSubnet-SQL'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: webSubnetPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: {
            id: nsgWeb.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: dataSubnetPrefix
          networkSecurityGroup: {
            id: nsgData.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output webSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
