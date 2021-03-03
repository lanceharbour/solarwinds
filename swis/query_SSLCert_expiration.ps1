Import-Module SwisPowerShell

$OrionServer = 'orionserver.domain.com'

$swis = Connect-Swis -Hostname $OrionServer -Trusted

$query = "
    SELECT nd.Caption AS Node_Name, 
        nd.IP_Address AS IP_Address,
        cs.ComponentStatisticData AS Days_Remaining,
        SUBSTRING(ccs.ErrorMessage,CHARINDEX(':',ErrorMessage)+1,15) AS Expiration_Date
    FROM Orion.APM.CurrentComponentStatus ccs
    JOIN Orion.APM.Component c ON c.ComponentID = ccs.ComponentID
    JOIN Orion.APM.Application a ON a.ApplicationID = ccs.ApplicationID
    JOIN Orion.APM.CurrentStatistics cs on cs.ApplicationID = ccs.ApplicationID
    JOIN Orion.Nodes nd ON nd.NodeID = a.NodeID
    WHERE c.ComponentType = '48'
    ORDER BY Days_Remaining
    "

$results = Get-SwisData $swis $query

foreach ($result in $results) {
    Write-Host $result.Node_Name $result.IP_Address $result.Days_Remaining $result.Expiration_Date
}