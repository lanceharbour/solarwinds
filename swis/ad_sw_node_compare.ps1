<#
ad_sw_node_compare.ps1

Description: Compares all nodes marked as category 2(server) and have MachineType 
of Windows in Solarwinds against enabled servers in AD.
#>
Import-Module SwisPowerShell

if(Test-Path -Path C:\scripts\logs\missing_ad_nodes.csv)
    {
        Remove-Item -Path C:\scripts\logs\missing_ad_nodes.csv -Force
        "Hostname,OS,IPAddress" | Out-File -FilePath C:\scripts\logs\missing_ad_nodes.csv
    }

#query swis for all nodes with category server
$OrionServer = 'orionserver.domain.com'
$swis = Connect-Swis -Hostname $OrionServer -Trusted

$query = "
    SELECT DisplayName, DNS, SysName, MachineType, IPAddress
    FROM Orion.Nodes
    WHERE Category = 2 AND Caption NOT LIKE '%anira%'
    ORDER By DisplayName
"

$swquery = Get-SwisData $swis $query

$winswnodes = $swquery | Where {$_.MachineType -like "Windows*"} | Out-String

#query AD for all Windows servers that are enabled
$adservers = Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*" -and enabled -eq $True' -Properties DNSHostName,IPv4Address,OperatingSystem | Sort-Object -property DNSHostName 

#Loop through all AD servers and verify reachable via ICMP and then compare against solarwinds node array
foreach ($adserver in $adservers)
    {
    if ($winswnodes -notmatch $adserver.DNSHostName -and $winswnodes -notmatch $adserver.IPv4Address -and $adserver.IPv4Address -ne $null)
        {
            $adserver.DNSHostName+","+$adserver.OperatingSystem+","+$adserver.IPv4Address | Out-File -FilePath C:\scripts\logs\missing_ad_nodes.csv -Append
        }
    }