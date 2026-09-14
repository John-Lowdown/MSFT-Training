// AZ-104 Lab 12: Standard Load Balancer & Azure DNS
// Domain: Implement and manage virtual networking — Configure name resolution and load balancing
// Cost: NOT literally free, but trivial for a same-day demo. Standard Load Balancer bills a
//       small hourly rate plus data-processed charges; a public DNS zone bills roughly
//       $0.50/month, prorated to the day. Delete when done rather than leaving either running.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab12 --location eastus
//   az deployment group create --resource-group rg-az104-lab12 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('Public DNS zone name. This is a demo zone — it is never delegated to a real registrar as part of this lab, so it will not resolve on the public internet. The record-management mechanics are exam content regardless of whether the domain is real.')
param dnsZoneName string = 'az104lab12-demo.com'

var lbName = 'lb-az104lab12'

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-az104lab12-lb'
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
    lab: 'lab12-load-balancer-dns'
  }
}

// Standard SKU Load Balancer, public-facing. All four moving parts below — frontend IP,
// backend pool, health probe, and load-balancing rule — are declared inline on this one
// resource and wired together with resourceId(), since a sub-resource can't reference its
// sibling's symbolic name before the parent resource itself finishes being defined.
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'feConfig'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'beAddressPool'
      }
    ]
    // TCP probe on port 80 — determines which pool members actually receive traffic. A VM
    // can be IN the backend pool and still get zero traffic if the probe marks it unhealthy.
    probes: [
      {
        name: 'httpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'lbRuleHttp'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'feConfig')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'beAddressPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'httpProbe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
        }
      }
    ]
    // Standard SKU requires an EXPLICIT outbound rule (or a NAT Gateway) for backend instances
    // to reach the internet — Basic SKU gave this implicitly. Omitting this is one of the most
    // common "it worked on Basic, why doesn't it work now" production surprises, and it's
    // exam-tested directly.
    outboundRules: [
      {
        name: 'outboundRuleDefault'
        properties: {
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'feConfig')
            }
          ]
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'beAddressPool')
          }
          protocol: 'All'
          allocatedOutboundPorts: 10000
        }
      }
    ]
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab12-load-balancer-dns'
  }
}

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
  tags: {
    course: 'AZ-104'
    lab: 'lab12-load-balancer-dns'
  }
}

// Points www.<zone> at the load balancer's public IP. This record is fully real and queryable
// via Azure DNS's own name servers the moment it's created — it just won't answer queries from
// the public internet at large until someone delegates dnsZoneName's registrar NS records to
// the ones Azure generated for this zone (see the lab README's manual-tasks section).
resource wwwRecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone
  name: 'www'
  properties: {
    ttl: 3600
    ARecords: [
      {
        ipv4Address: publicIp.properties.ipAddress
      }
    ]
  }
}

output loadBalancerPublicIp string = publicIp.properties.ipAddress
output loadBalancerId string = loadBalancer.id
output dnsZoneName string = dnsZone.name
output dnsZoneNameServers array = dnsZone.properties.nameServers
output wwwRecordFqdn string = 'www.${dnsZoneName}'
