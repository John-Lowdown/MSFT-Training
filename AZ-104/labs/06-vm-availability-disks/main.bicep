// AZ-104 Lab 06: VM Deployment, Availability Zones & Managed Disks
// Domain: Deploy and manage Azure compute resources — Create and configure virtual machines
// Cost: REAL, genuinely billable — ~$0.01/hr for the VM (Standard_B1s) plus ~$0.02/day for a
//       small Premium SSD managed disk. This is the first AZ-104 lab with real hourly billing
//       (Labs 01-05 are governance-only and free). Delete the same day you deploy it.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab06 --location eastus
//   az deployment group create --resource-group rg-az104-lab06 --template-file main.bicep \
//     --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"

@description('Azure region')
param location string = resourceGroup().location

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user — password auth is disabled, key-based only')
param adminPublicKey string

@description('VM size — B1s is the cheapest widely-available Linux burstable size, appropriate for a demo, not production')
param vmSize string = 'Standard_B1s'

@description('Availability zone this VM is pinned to. A VM can be in a zone OR an availability set, never both — see the comment above the VM resource.')
@allowed([
  '1'
  '2'
  '3'
])
param vmZone string = '1'

@description('CIDR allowed to reach SSH (22). Defaults to any address for lab simplicity — in the real world, scope this to your own IP.')
param sshSourceAddressPrefix string = '*'

var vnetAddressPrefix = '10.40.0.0/24'
var subnetAddressPrefix = '10.40.0.0/26'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-az104lab06'
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
  tags: {
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-az104lab06'
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
  tags: {
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-az104lab06'
  location: location
  sku: {
    name: 'Standard'
  }
  // Standard SKU public IPs default to zone-redundant; calling it out explicitly
  // keeps the IP reachable regardless of which zone the VM itself lands in.
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-az104lab06'
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
  tags: {
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
  }
}

// AVAILABILITY ZONE vs. AVAILABILITY SET — a VM can use one or the other, never both.
// An availability zone (what this VM uses, via the `zones` property below) places the VM
// in a physically separate datacenter facility within the region — its own power, cooling,
// and network, protecting against a whole-datacenter failure. An availability set instead
// spreads VMs across fault domains (separate racks/power/network within ONE datacenter) and
// update domains (groups that aren't patched/rebooted simultaneously during planned
// maintenance) — it protects against a single rack or host failing, not a datacenter-level
// outage. They are mutually exclusive on the same VM because they solve problems at two
// different blast radii, and the exam tests that distinction directly rather than testing
// either concept in isolation.
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-az104lab06'
  location: location
  zones: [
    vmZone
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    // Encrypts the VM's temp disk, OS disk cache, and data disk caches at the host level.
    // This is separate from (and complementary to) Azure Disk Encryption, which encrypts
    // the OS itself via BitLocker/dm-crypt inside the guest — not this lab's focus, just
    // worth knowing the two aren't the same control.
    // Some subscriptions need the feature registered before this will deploy:
    //   az feature register --namespace Microsoft.Compute --name EncryptionAtHost
    //   az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state
    securityProfile: {
      encryptionAtHost: true
    }
    osProfile: {
      computerName: 'az104lab06'
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
          // Premium SSD — intentional choice here (vs. AZ-900 Lab 9's Standard_LRS) so the
          // disk's own SKU/tier is something worth opening the Disks blade to inspect.
          storageAccountType: 'Premium_LRS'
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
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
    availabilityZone: vmZone
  }
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
output assignedZone string = vmZone
output osDiskSku string = vm.properties.storageProfile.osDisk.managedDisk.storageAccountType
