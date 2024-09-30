$resourceOrderRemovalOrder = [ordered]@{
    "Microsoft.Compute/virtualMachines" = 0
    "Microsoft.Compute/disks" = 1
    "Microsoft.Network/networkInterfaces" = 2
    "Microsoft.Network/publicIpAddresses" = 3
    "Microsoft.Network/networkSecurityGroups" = 4
    "Microsoft.Network/virtualNetworks" = 5
}

az resource list --resource-group BicepStudy | 
                         ConvertFrom-Json | 
            Sort-Object @{Expression = {$resourceOrderRemovalOrder[$_.type]}; Descending = $False} | 
    ForEach-Object {az resource delete --resource-group BicepStudy --ids $_.id --verbose}