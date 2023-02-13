#Read SMTP files from $ExchangeInstallPath variable
try {
    $files = Get-ChildItem -Path "$($env:ExchangeInstallPath)\TransportRoles\Logs\FrontEnd\ProtocolLog" -Recurse -Filter *log -ErrorAction Stop | Sort-Object LastWriteTime
    Write-Host ("Reading SMTP Logfiles from {0}" -f "$($env:ExchangeInstallPath)TransportRoles\Logs\FrontEnd\ProtocolLog") -ForegroundColor Green
}
catch {
    Write-Warning ("Couldn't access {0}, check permissions and exiting now..." -f "$($env:ExchangeInstallPath)\TransportRoles\Logs\FrontEnd\ProtocolLog")
    return
} 

#Set variables
$report = 'C:\temp\smtplogging.csv'
$filenumber = 0

try {
    New-Item -Path $report -ItemType File -ErrorAction Stop -Force:$true -Confirm:$false | Out-Null
    Write-Host ("{0} is valid for saving results, continuing..." -f $report) -ForegroundColor Green
    Remove-Item -Path $report -Force:$true -Confirm:$false | Out-Null
}
catch {
    Write-Warning ("Coudn't write to {0}, check permissions and exiting now..." -f $report)
    return
}

foreach ($logfile in $files) {
    $filenumber++
    write-host ("[{0}/{1}] Processing file {2}" -f $filenumber, $files.count, $logfile.FullName) -ForegroundColor Green
    try {
        $csv = Import-Csv -Path $logfile.Fullname -Header 'date-time', 'connector-id', 'session-id', 'sequence-number', 'local-endpoint', 'remote-endpoint', 'event', 'data', 'context' -Delimiter ',' -Encoding UTF8
    }
    catch {
        Write-Warning ("Could not process {0}, file in use or cleaned during processing?")
    }

    foreach ($connection in $csv) {
        if (-not ($connection.'date-time'.StartsWith('#')) -and ($connection.data -match '@')) {
            #Set $EventField variable (https://learn.microsoft.com/en-us/exchange/mail-flow/connectors/protocol-logging?view=exchserver-2019#fields-in-the-protocol-log)
            Switch ($connection.event) {
                '+' { $EventField = "Connect" }
                '-' { $EventField = "Disconnect" }
                '>' { $EventField = "Send" }
                '<' { $EventField = "Receive" }
                '*' { $EventField = "Information" } 
            }
            $total = [pscustomobject]@{
                FileName       = $logfile.FullName
                DateTime       = $connection.'date-time'
                Connector      = $connection.'connector-id'
                LocalEndpoint  = $connection.'local-endpoint'.Split(':')[0]
                RemoteEndpoint = $connection.'remote-endpoint'.Split(':')[0]
                Event          = $EventField
                Data           = $connection.data                
            }
            #Export results to temporary CSV file
            $total | Export-Csv -Path "$($report).tmp" -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Append
        }
    }
}

#Read temporary CSV, sort on date and save results to CSV location specified in the $report variable
Write-Host ("Exporting results to {0}" -f $report) -ForegroundColor Green
try {
    Import-Csv -Path "$($report).tmp" -Delimiter ';' -Encoding UTF8 -ErrorAction Stop | Sort-Object DateTime | Export-Csv -Path $report -NoTypeInformation -Delimiter ';' -Encoding UTF8 -ErrorAction Stop
}
catch {
    Write-Warning ("Couldn't sort and export {0} to {1}, check permissions... " -f "$($report).tmp", $report)
}

#Cleanup temporary file
try {
    Remove-Item -Path "$($report).tmp" -ErrorAction Stop | Out-Null
    Write-Host ("Cleaned {0}, done!" -f "$($report).tmp") -ForegroundColor Green
}
catch {
    Write-Warning ("Couldn't remove {0}, check permissions or if file is in use..." -f "$($report).tmp")
}