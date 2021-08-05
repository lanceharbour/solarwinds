<#
all_sw_node_compare.ps1
author: Lance Harbour

Description: Compares all nodes marked as category 2(server) in Solarwinds 
against enabled servers in AD, powered on servers on vmware hosts 
to identify missing nodes.
#>
Import-Module SwisPowerShell
$logfile = "C:\scripts\logs\missing_nodes.csv"

#test for logfile and remove if present
if(Test-Path -Path $logfile)
    {
        #Write-Host "Removing C:\scripts\logs\missing_nodes.csv"
        Remove-Item -Path $logfile -Force
        "Hostname,OS,IPAddress,Source" | Out-File -FilePath $logfile -Force
    }

#query swis for all nodes with category server
$OrionServer = 'orionserver.domain.com'
$swis = Connect-Swis -Hostname $OrionServer -Trusted

$query = "
    SELECT DisplayName, DNS, SysName, MachineType, IPAddress
    FROM Orion.Nodes
    WHERE Category = 2'
    ORDER By DisplayName
"

$swquery = Get-SwisData $swis $query

#-----------------------------------------------------------------------------#
#query AD for all Windows servers that are enabled
$winswnodes = $swquery | Where {$_.MachineType -like "Windows*"} | Out-String

$adservers = Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*" -and enabled -eq $True' -Properties DNSHostName,IPv4Address,OperatingSystem | Sort-Object -property DNSHostName 

#Loop through all AD servers and then compare against solarwinds node array
foreach ($adserver in $adservers)
    {
    if ($winswnodes -notmatch $adserver.DNSHostName -and $adserver.IPv4Address -ne $null)
        {
            $adserver.DNSHostName+","+$adserver.OperatingSystem+","+$adserver.IPv4Address+",AD" | Out-File -FilePath $logfile -Append
        }
    }

#-----------------------------------------------------------------------------#
#query all vcenter servers for all vm nodes
$swnodes = $swquery | Out-String

$vCServers = "vcenter1.domain.com","vcenter2.domain.com"
Connect-VIServer -Server $VCServers -WarningAction SilentlyContinue
$vmnodes = get-vm | Where {$_.Guest.OSFullName -notlike "Microsoft Windows 10*" -and $_.Guest.OSFullName -notlike "Microsoft Windows 7*" -and $_.PowerState -eq "PoweredOn"} | 
    Select-object -Property Name, 
    @{N='HostName';E={$_.Guest.HostName}},
    @{N='OperatingSystem';E={$_.Guest.OSFullName}},
    @{N='PowerState';E={$_.PowerState}},
    VMHost,
    @{N='IPAddress';E={$_.guest.IPAddress[0]}} | Sort-Object HostName

#loop through all vm nodes
$vmnodes | Export-Csv -Path C:\scripts\logs\all_vmnodes.csv -NoTypeInformation

foreach ($vmnode in $vmnodes)
    {
    if ($swnodes -notmatch $vmnode.Name)
        {
            #$vmnode.Name
            $vmnode.Name+","+$vmnode.OperatingSystem+","+$vmnode.IPAddress+","+$vmnode.VMHost | Out-File -FilePath $logfile -Append
        }
    }
