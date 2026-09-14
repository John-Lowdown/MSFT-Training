// AZ-104 Lab 10: VNet Peering & User-Defined Routes
// Domain: Implement and manage virtual networking — Configure and manage virtual networks in Azure
// Cost: $0 for the VNets, peering, and route table. The Standard public IP deployed standalone
//       here carries a small real hourly charge (a few cents/day) even with nothing attached to
//       it. Basic SKU public IPs are being retired, so Standard isn't a cost-saving alternative —
//       it's the only sensible default now. Delete the same day you deploy it.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab10 --location eastus
//   az deployment group create --resource-group rg-az104-lab10 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('Address space for the hub VNet')
param hubVnetAddressPrefix string = '10.0.0.0/16'

@description('Address space for the hub workload subnet')
param hubWorkloadSubnetPrefix string = '10.0.0.0/24'

@description('Address space for the spoke VNet')
param spokeVnetAddressPrefix string = '10.1.0.0/16'

@description('Address space for the spoke workload subnet')
param spokeWorkloadSubnetPrefix string = '10.1.0.0/24'

@description('Demo next-hop IP for the UDR, inside the hub workload subnet. This is a placeholder address — no NVA/firewall is deployed in this lab, and Azure will not validate that anything is listening there. The UDR mechanism itself is what the exam tests.')
param nvaPrivateIpAddress string = '10.0.0.4'

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-az104lab10-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-hub-workload'
        properties: {
          addressPrefix: hubWorkloadSubnetPrefix
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab10-vnet-peering-routing'
  }
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-az104lab10-spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-spoke-workload'
        properties: {
          addressPrefix: spokeWorkloadSubnetPrefix
          // Associates the UDR below to this subnet. A route table that exists but isn't
          // associated to any subnet does nothing — the association is what activates it.
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab10-vnet-peering-routing'
  }
}

// Sends all outbound spoke traffic to a "virtual appliance" next hop. Azure does not check
// that anything is actually listening at nvaPrivateIpAddress — it will happily route traffic
// into a black hole if the address is wrong or nothing is there. That's exactly why a
// misconfigured UDR is a common production incident: the route looks correct in the portal
// right up until you try to use it.
resource routeTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-az104lab10-spoke'
  location: location
  properties: {
    routes: [
      {
        name: 'Route-Default-To-NVA'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nvaPrivateIpAddress
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab10-vnet-peering-routing'
  }
}

// VNet peering is always TWO resources, one per VNet, each pointing at the other — unlike the
// portal's single "Add peering" wizard, which creates both sides for you in one click. Bicep
// has to declare both explicitly because there is no single "peering pair" object in Resource
// Manager, just two independent child resources that happen to reference each other.
//
// allowGatewayTransit (set here, on the hub side) would let the spoke use a VPN/ExpressRoute
// gateway attached to THIS (hub) VNet, if one existed. useRemoteGateways (set on the spoke
// peering below) is the mirror image: it's what the spoke sets to actually consume a gateway
// sitting in the hub. Neither flag does anything without a real gateway deployed — this lab
// has none, so both are false — but the exam tests the mechanism regardless of whether a lab
// budget can afford to provision an actual gateway.
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: hubVnet
  name: 'peer-hub-to-spoke'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: spokeVnet
  name: 'peer-spoke-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Standard, Static, zone-redundant public IP with nothing attached yet. Used standalone here
// to inspect its properties in isolation; later labs in this set attach a public IP of this
// same shape to a Bastion host and a Load Balancer.
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-az104lab10'
  location: location
  sku: {
    name: 'Standard'
  }
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
    lab: 'lab10-vnet-peering-routing'
  }
}

output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
output hubToSpokePeeringId string = hubToSpokePeering.id
output spokeToHubPeeringId string = spokeToHubPeering.id
output routeTableId string = routeTable.id
output publicIpName string = publicIp.name
output publicIpAddress string = publicIp.properties.ipAddress
