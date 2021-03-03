Import-Module SwisPowerShell

if(Test-Path -Path C:\scripts\logs\sw_down_server_interfaces.txt = True)
    {
        Remove-Item -Path C:\scripts\logs\sw_down_server_interfaces.txt -Force
    }

$OrionServer = 'orionserver.domain.com'

$swis = Connect-Swis -Hostname $OrionServer -Trusted

$query = "
    SELECT
        Interfaces.Node.Caption AS NodeName,
        Interfaces.Node.Status AS NodeStatus,
        Interfaces.Caption AS InterfaceName,
        Interfaces.URI,
        Interfaces.Status
    FROM Orion.NPM.Interfaces AS Interfaces
    WHERE Interfaces.Status != 1 
    AND Interfaces.Node.Status != 9 
    AND Interfaces.Node.Status != 2 
    AND Interfaces.Node.Vendor = 'Windows'
    "

$results = Get-SwisData $swis $query

foreach ($result in $results) {
    $dsi = $result.NodeName+','+$result.InterfaceName+','+$result.Status
    $dsi | Out-File -FilePath C:\scripts\logs\sw_down_server_interfaces.txt -Force -Append
}