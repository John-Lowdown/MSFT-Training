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

@description('Availability zone this VM is pinned to. Only used when deploymentTarget is "zone". A VM can be in a zone OR an availability set, never both — see the comment above the VM resource.')
@allowed([
  '1'
  '2'
  '3'
])
param vmZone string = '1'

@description('Which placement strategy to deploy the VM with. "zone" (the default, matching this lab\'s original behavior/cost) pins the VM to the availability zone in vmZone. "availabilitySet" instead creates an availability set and places the VM in it — the two are mutually exclusive on a single VM, which is the entire point of this parameter.')
@allowed([
  'zone'
  'availabilitySet'
])
param deploymentTarget string = 'zone'

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
// An availability zone (deploymentTarget: 'zone', the default, via the `zones` property
// below) places the VM in a physically separate datacenter facility within the region —
// its own power, cooling, and network, protecting against a whole-datacenter failure. An
// availability set (deploymentTarget: 'availabilitySet', the resource below) instead
// spreads VMs across fault domains (separate racks/power/network within ONE datacenter) and
// update domains (groups that aren't patched/rebooted simultaneously during planned
// maintenance) — it protects against a single rack or host failing, not a datacenter-level
// outage. They are mutually exclusive on the same VM because they solve problems at two
// different blast radii, and the exam tests that distinction directly rather than testing
// either concept in isolation.
//
// Only created when deploymentTarget is 'availabilitySet' — this is the Bicep resource-level
// `if` condition, not a manually-toggled comment. 2 fault domains / 5 update domains are the
// typical defaults for a region that supports the standard FD/UD maximums (some regions cap
// fault domains at 2; 5 update domains is the platform default when none is specified).
// sku.name: 'Aligned' is the modern, managed-disk-compatible availability set SKU — the
// older 'Classic' SKU does NOT support managed disks at all, which is itself a testable fact:
// an availability set created without specifying 'Aligned' defaults to 'Classic' and cannot
// host the Premium_LRS managed disk this VM uses below.
resource avSet 'Microsoft.Compute/availabilitySets@2024-03-01' = if (deploymentTarget == 'availabilitySet') {
  name: 'avail-az104lab06'
  location: location
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab06-vm-availability-disks'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-az104lab06'
  location: location
  // A VM can't have both `zones` and `properties.availabilitySet` set at once — Azure
  // rejects the deployment outright. Bicep's ternary + `null` is the standard pattern for
  // this exact mutual exclusivity: assigning `null` to a property omits it from the
  // generated ARM template entirely, rather than sending an empty/invalid value. Only one of
  // `zones` below and `properties.availabilitySet` further down ever actually renders.
  zones: deploymentTarget == 'zone' ? [
    vmZone
  ] : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    // The other half of the mutual-exclusivity pattern described above — only renders when
    // deploymentTarget is 'availabilitySet', referencing the conditional avSet resource
    // declared earlier in this file.
    availabilitySet: deploymentTarget == 'availabilitySet' ? {
      id: avSet.id
    } : null
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
    availabilityZone: deploymentTarget == 'zone' ? vmZone : 'none (availability set)'
  }
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.ipAddress}'
output deploymentTarget string = deploymentTarget
output assignedZone string = deploymentTarget == 'zone' ? vmZone : ''
output availabilitySetName string = deploymentTarget == 'availabilitySet' ? avSet.name : ''
output osDiskSku string = vm.properties.storageProfile.osDisk.managedDisk.storageAccountType
