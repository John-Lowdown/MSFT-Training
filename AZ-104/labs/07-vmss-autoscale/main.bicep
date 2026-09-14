// AZ-104 Lab 07: VM Scale Sets & Custom Autoscale
// Domain: Deploy and manage Azure compute resources — Deploy and configure Azure VM Scale Sets
// Cost: REAL, and it scales with instance count — same per-instance hourly cost as Lab 06
//       (Standard_B1s), times however many instances autoscale spins up. Default capacity is
//       1 to keep this cheap. Delete promptly; don't leave autoscale running unattended.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab07 --location eastus
//   az deployment group create --resource-group rg-az104-lab07 --template-file main.bicep \
//     --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"

@description('Azure region')
param location string = resourceGroup().location

@description('Admin username for scale set instances')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user — password auth is disabled, key-based only')
param adminPublicKey string

@description('VM size for each scale set instance — B1s keeps per-instance cost minimal for a demo')
param vmSize string = 'Standard_B1s'

@description('Starting instance count. Kept at 1 by default — autoscale is what changes this, not the template.')
param defaultCapacity int = 1

@description('Minimum instances autoscale is allowed to scale in to')
param minCapacity int = 1

@description('Maximum instances autoscale is allowed to scale out to')
param maxCapacity int = 3

var vnetAddressPrefix = '10.41.0.0/24'
var subnetAddressPrefix = '10.41.0.0/26'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-az104lab07'
  location: location
  // No inbound rules opened — instances aren't given public IPs, and the manual
  // load-generation task uses `az vmss run-command invoke`, which goes through the
  // VM agent channel rather than the network. Default NSG rules (deny inbound from
  // the internet, allow intra-VNet) are all this lab needs.
  properties: {
    securityRules: []
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab07-vmss-autoscale'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-az104lab07'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-vmss'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab07-vmss-autoscale'
  }
}

// Flexible orchestration mode, not Uniform — Microsoft's current recommended default for most
// new scale sets. Flexible manages each instance closer to a standalone VM (own NIC/disk
// lifecycle), supports mixing VM sizes in the same scale set, and spreads instances across
// fault domains/zones more flexibly than Uniform's rigid, identical-instance model. Uniform
// still exists and is still tested, but Flexible is what you should reach for by default today.
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: 'vmss-az104lab07'
  location: location
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: defaultCapacity
  }
  properties: {
    orchestrationMode: 'Flexible'
    platformFaultDomainCount: 1
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'az104l07'
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: adminPublicKey
              }
            ]
          }
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'ubuntu-24_04-lts'
          sku: 'server'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      networkProfile: {
        // Flexible orchestration requires an explicit networkApiVersion on the profile.
        networkApiVersion: '2023-09-01'
        networkInterfaceConfigurations: [
          {
            name: 'nic-config'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    subnet: {
                      id: vnet.properties.subnets[0].id
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab07-vmss-autoscale'
  }
}

// Scale-out and scale-in are TWO INDEPENDENT rules that must be paired deliberately — without
// the scale-in rule below, this scale set would only ever grow toward maxCapacity and never
// shrink back down. Cooldown periods on both rules exist to stop rapid oscillation ("flapping")
// between scaling actions triggered by noisy, short-lived metric spikes.
resource autoscale 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: 'as-az104lab07'
  location: location
  properties: {
    enabled: true
    targetResourceUri: vmss.id
    profiles: [
      {
        name: 'default'
        capacity: {
          minimum: string(minCapacity)
          maximum: string(maxCapacity)
          default: string(defaultCapacity)
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab07-vmss-autoscale'
  }
}

output vmssName string = vmss.name
output autoscaleSettingName string = autoscale.name
output defaultCapacity int = defaultCapacity
output capacityRange string = '${minCapacity}-${maxCapacity}'
