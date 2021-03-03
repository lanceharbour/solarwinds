Import-Module SwisPowerShell
if(Test-Path -Path C:\scripts\logs\sw_windows_servers.txt)
    {
        Write-Host "Removing C:\scripts\logs\sw_windows_servers.txt"
        Remove-Item -Path C:\scripts\logs\sw_windows_servers.txt -Force
    }
$swservers = ""

$cred = Get-Credential

$OrionServer = 'mpnetmon.dadco.com'

$swis = Connect-Swis -Hostname $OrionServer -Credential $cred

$query = "
    SELECT DisplayName, DNS, IPAddress, SysName
    FROM Orion.Nodes
    WHERE Vendor = 'Windows'
    ORDER By DisplayName
"

$results = Get-SwisData $swis $query

foreach ($result in $results)
    {
    $swservers = $swservers+$result.DNS+','+$result.SysName+','
    }

$adservers = Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*" -and enabled -eq $True' -Properties DNSHostName | Sort-Object -property DNSHostName 

foreach ($adserver in $adservers)
    {
    if ($swservers -notmatch $adserver.DNSHostName -and $swservers -notmatch $adserver.Name)
        {
        Write-Host $adserver.DNSHostName"not in SW"
        }

    }