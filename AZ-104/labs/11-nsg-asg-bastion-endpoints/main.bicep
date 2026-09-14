// AZ-104 Lab 11: NSGs, Application Security Groups, Bastion & Private Endpoints
// Domain: Implement and manage virtual networking — Configure secure access to virtual networks
//
// Cost: Azure Bastion Standard tier costs roughly $0.19/hour — about $140 if accidentally left
//       running for a month. This is the single most expensive resource in the entire AZ-104
//       lab set. Delete it within the hour you deploy it, every time. Everything else here
//       (VNet, NSG, ASGs, private endpoint, private DNS zone) carries no charge of its own;
//       the storage account is an empty StorageV2 account and is effectively free at this scale.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab11 --location eastus
//   az deployment group create --resource-group rg-az104-lab11 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('Address space for the VNet')
param vnetAddressPrefix string = '10.2.0.0/16'

@description('Address space for the workload subnet')
param workloadSubnetPrefix string = '10.2.1.0/24'

@description('Address space for AzureBastionSubnet — must be /26 or larger, and this exact subnet name is required by Azure Bastion')
param bastionSubnetPrefix string = '10.2.2.0/26'

var storageAccountName = 'az104lab11${uniqueString(resourceGroup().id)}'

resource asgWeb 'Microsoft.Network/applicationSecurityGroups@2023-11-01' = {
  name: 'asg-az104lab11-web'
  location: location
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// Created alongside asg-web to demonstrate that ASGs group resources by ROLE, not by rule —
// this ASG is deliberately left unreferenced by any rule below. A natural hands-on extension:
// add a second NSG rule allowing SQL (1433) from asg-web to asg-db, mirroring AZ-900 Lab 3's
// two-tier pattern but with ASGs standing in for subnet-range source/destination prefixes.
resource asgDb 'Microsoft.Network/applicationSecurityGroups@2023-11-01' = {
  name: 'asg-az104lab11-db'
  location: location
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// This NSG's one custom rule targets an ASG as its DESTINATION instead of an IP/CIDR — lets you
// write rules about "anything tagged as web tier" instead of specific addresses that change
// every time a VM is rebuilt. Azure still adds its own default rules underneath this one
// (AllowVnetInBound, AllowAzureLoadBalancerInBound, DenyAllInBound, and their outbound
// equivalents) — they're invisible here because nobody writes them, but they're real and
// they're what "Effective security rules" shows merged with this custom rule.
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-az104lab11'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-From-Internet-To-Web-ASG'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgWeb.id
            }
          ]
          destinationPortRange: '443'
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-az104lab11'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-workload'
        properties: {
          addressPrefix: workloadSubnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          // Required so a private endpoint can land in this subnet. Newer subnets often
          // default this correctly, but setting it explicitly avoids a deployment failure
          // that otherwise looks unrelated to anything in this template.
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        // Exact name required by Azure Bastion — it will not deploy into a subnet named
        // anything else. No NSG is attached here to keep the lab simple; Microsoft recommends
        // one in production, with a specific set of inbound/outbound rules for Bastion's own
        // management traffic (GatewayManager, AzureLoadBalancer, and the data-plane ports).
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-az104lab11-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// Standard tier (not Basic) — Basic exists and is cheaper, but Standard unlocks features worth
// knowing about for the exam and in practice: native client support, IP-based connection,
// shareable links, and higher scale units. Gives browser-based RDP/SSH to VMs in this VNet
// without ever putting a public IP on the VM itself — direct contrast with the AZ-900-level
// "just open an NSG rule for RDP/SSH," which is the outdated-but-still-tested wrong answer.
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: 'bas-az104lab11'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// Puts the storage account's blob endpoint inside this VNet, with its own private IP in
// snet-workload — contrast with a service endpoint, which only optimizes the ROUTE to a
// still-public endpoint and never gives the PaaS resource an address inside your VNet. That
// distinction (private endpoint vs. service endpoint) is a frequently confused exam pair.
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-az104lab11-blob'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-az104lab11-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// registrationEnabled: true auto-registers any VM's own NIC deployed into this VNet as an A
// record in this zone — it is NOT what creates the private endpoint's own DNS record. That
// record comes from the privateDnsZoneGroup below instead. Without that zone group, the
// private endpoint would still work (it has a real private IP), but nothing would
// automatically resolve <account>.blob.core.windows.net to it.
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-az104lab11'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: true
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab11-nsg-asg-bastion-endpoints'
  }
}

// This is what actually makes name resolution work end to end: ties the private endpoint to
// the zone above, and Azure writes the matching A record into it automatically.
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output nsgId string = nsg.id
output asgWebId string = asgWeb.id
output asgDbId string = asgDb.id
output bastionName string = bastion.name
output bastionPublicIpAddress string = bastionPublicIp.properties.ipAddress
output storageAccountName string = storageAccount.name
output privateEndpointId string = privateEndpoint.id
output privateDnsZoneId string = privateDnsZone.id
