param location string
param networkSecurityGroupName string
param networkSecurityGroupRules array
param subnetName string
param virtualNetworkName string
param addressPrefixes array
param subnets array
param publicIpAddressName string
param publicIpAddressType string
param publicIpAddressSku string
param virtualMachineName string
param virtualMachineComputerName string
param virtualMachineRG string
param osDiskType string
param osDiskDeleteOption string
param virtualMachineSize string
param networkInterfaceName string
param enableAcceleratedNetworking bool
param nicDeleteOption string
param hibernationEnabled bool
param adminUsername string

@secure()
param adminPassword string

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetName = virtualNetworkName
var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
var subnetRef = '${vnetId}/subnets/${subnetName}'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'cloud-infrastructure-services'
        offer: 'wordpress-ubuntu-18-04'
        sku: 'wordpress-ubuntu-18-04'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaceConfigurations: [
        for j in range(0, 1): {
          name: networkInterfaceName
          properties: {
            primary: true
            ipConfigurations: [
              {
                name: '${take(networkInterfaceName,(80-length('-defaultIpConfiguration')))}-defaultIpConfiguration'
                properties: {
                  subnet: {
                    id: subnetRef
                  }
                  primary: true
                  applicationGatewayBackendAddressPools: []
                  loadBalancerBackendAddressPools: []
                  publicIPAddressConfiguration: {
                    name: publicIpAddressName
                    properties: {
                      idleTimeoutInMinutes: 15
                      publicIPAllocationMethod: publicIpAddressType
                    }
                  }
                }
              }
            ]
            networkSecurityGroup: ((nsgId == '') ? json('null') : json('{"id": "${nsgId}"}'))
            enableAcceleratedNetworking: enableAcceleratedNetworking
            deleteOption: nicDeleteOption
          }
        }
      ]
      networkApiVersion: '2022-11-01'
    }
    securityProfile: {}
    additionalCapabilities: {
      hibernationEnabled: false
    }
    osProfile: {
      computerName: virtualMachineComputerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        patchSettings: {
          assessmentMode: 'ImageDefault'
          patchMode: 'ImageDefault'
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  plan: {
    name: 'wordpress-ubuntu-18-04'
    publisher: 'cloud-infrastructure-services'
    product: 'wordpress-ubuntu-18-04'
  }
  dependsOn: [
    virtualNetwork
    networkSecurityGroup
  ]
}

output adminUsername string = adminUsername
