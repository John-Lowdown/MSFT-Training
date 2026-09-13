// AZ-900 Lab 9: Virtual Machine Basics
// Domain: Azure Architecture & Services — Compute ("what a VM actually needs")
// Cost: ~$0.01-0.05 for a short demo on Standard_B1s — the ONLY lab in this repo with a
//       genuinely non-zero cost (every other lab is $0 or fractions of a cent on storage).
//       Delete immediately after the demo; don't leave this running.
//
// Deploy into an existing resource group:
//   az group create --name rg-az900-lab09 --location eastus
//   az deployment group create --resource-group rg-az900-lab09 --template-file main.bicep \
//     --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"

@description('Azure region')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user — password auth is disabled, key-based only')
param adminPublicKey string

@description('VM size — B1s is the cheapest widely-available Linux burstable size, appropriate for a short demo only, not production')
param vmSize string = 'Standard_B1s'

@description('CIDR allowed to reach SSH (22). Defaults to any address for lab simplicity — in the real world, scope this to your own IP.')
param sshSourceAddressPrefix string = '*'

var vnetAddressPrefix = '10.30.0.0/24'
var subnetAddressPrefix = '10.30.0.0/26'

// Same NSG-at-subnet pattern as Lab 3, applied here to a real running VM
// instead of an empty network.
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-az900-lab09'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: sshSourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-az900-lab09'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-vm'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Standard SKU — Basic SKU public IPs are on Microsoft's retirement path and
// should not be used in new templates.
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-az900-lab09'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-az900-lab09'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// The four resource categories Module 3 names explicitly: compute (size/SKU
// below), storage (osDisk), networking (nic, above), and region/resilience
// (location param — no availability set/zone for a single throwaway VM).
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-az900-lab09'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'az900lab09'
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
      // Verify this Marketplace image reference is still current before relying
      // on it: az vm image list --publisher Canonical --sku ubuntu --all -o table
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
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    course: 'AZ-900'
    lab: 'lab09-virtual-machine'
  }
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
