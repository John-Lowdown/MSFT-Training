// AZ-104 Lab 08: Containers — Registry, Container Instances & Container Apps
// Domain: Deploy and manage Azure compute resources — Provision and manage containers
// Cost: near-$0 if deleted promptly. ACR Basic is a flat ~$0.167/day. ACI bills per-second
//       while running (trivial for a short demo, but it runs CONTINUOUSLY until stopped —
//       it does not scale to zero). Container Apps on Consumption scales to zero between
//       requests, so it's genuinely ~$0 once idle. Delete within the hour, especially the
//       Container Instance.
//
// Deploy into an existing resource group:
//   az group create --name rg-az104-lab08 --location eastus
//   az deployment group create --resource-group rg-az104-lab08 --template-file main.bicep

@description('Azure region')
param location string = resourceGroup().location

@description('Public test image for the Container Instance')
param aciImage string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

@description('Public test image for the Container App')
param containerAppImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var acrName = 'az104lab08${uniqueString(resourceGroup().id)}'
var aciDnsLabel = 'az104lab08-${uniqueString(resourceGroup().id)}'

// Basic SKU, deliberately — Premium is required for geo-replication (a named exam
// sub-bullet), but Premium carries a continuously-higher cost that isn't justified for a
// single-region training lab. Basic keeps this cheap; the tradeoff is named here on purpose
// rather than silently picked.
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab08-containers-acr-aci-apps'
  }
}

// restartPolicy: 'Never' is a deliberate cost guard — 'Always' would keep restarting (and
// billing for) this container group indefinitely if the process inside ever exits.
resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'aci-az104lab08'
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Never'
    containers: [
      {
        name: 'aci-helloworld'
        properties: {
          image: aciImage
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: json('1.5')
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: aciDnsLabel
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab08-containers-acr-aci-apps'
  }
}

// Log Analytics is required wiring for a Container Apps managed environment's log
// destination — PerGB2018 has a free daily allotment that a short demo won't come close to.
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-az104lab08'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab08-containers-acr-aci-apps'
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: 'cae-az104lab08'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab08-containers-acr-aci-apps'
  }
}

// Consumption plan, scale-to-zero (minReplicas: 0) — this is the genuinely different cost
// model vs. the Container Instance above: idle traffic means idle billing, not continuous
// billing.
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'ca-az104lab08'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
    }
    template: {
      containers: [
        {
          name: 'containerapps-helloworld'
          image: containerAppImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
  tags: {
    course: 'AZ-104'
    lab: 'lab08-containers-acr-aci-apps'
  }
}

output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output aciFqdn string = aci.properties.ipAddress.fqdn
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
