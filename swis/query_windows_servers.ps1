Import-Module SwisPowerShell
if(Test-Path -Path C:\scripts\logs\sw_windows_servers.txt)
    {
        Write-Host "Removing C:\scripts\logs\sw_windows_servers.txt"
        Remove-Item -Path C:\scripts\logs\sw_windows_servers.txt -Force
    }

$OrionServer = 'orionserver.domain.com'

$swis = Connect-Swis -Hostname $OrionServer -Trusted

$query = "
    SELECT DisplayName, DNS, IPAddress
    FROM Orion.Nodes
    WHERE Vendor = 'Windows'
    ORDER By DisplayName
"

$results = Get-SwisData $swis $query

foreach ($result in $results) {
    $wsl = $result.DisplayName+','+$result.DNS+','+$result.IPAddress
    $wsl | Out-File -FilePath C:\scripts\logs\sw_windows_servers.txt -Force -Append
}