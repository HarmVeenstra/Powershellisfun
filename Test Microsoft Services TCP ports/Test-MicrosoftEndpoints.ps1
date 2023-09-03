function Test-MicrosoftEndpoints {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [parameter(parameterSetName = "All")][switch]$All,
        [parameter(Mandatory = $false)][string]$CSVPath,
        [parameter(parameterSetName = "Note")][string]$Note,
        [parameter(parameterSetName = "ServiceAreaDisplayName")][string]$ServiceAreaDisplayName,
        [parameter(parameterSetName = "URL")][string]$URL
    )

    #Hide download progress, get current JSON url, retrieve all Endpoints and Convert it from JSON format
    $ProgressPreference = "SilentlyContinue"
    try {
        $site = Invoke-WebRequest -Uri 'https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide' -UseBasicParsing
        $jsonlink = ($site.Links | where-Object OuterHTML -match 'JSON formatted').href
    }
    catch {
        Write-Warning ("Error downloading JSON file, please check if https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide is accessible")
        return 
    }

    try {
        $Endpoints = Invoke-WebRequest -Uri $jsonlink -ErrorAction Stop | ConvertFrom-Json
        Write-Host ("Downloading worldwide Microsoft Endpoints") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error downloading worldwide Microsoft Endpoints, please check if {0} is accessible" -f $jsonlink)
        return
    }

    #Search for specified parameter value
    if ($All) {
        $TestEndpoints = $Endpoints | Where-Object urls -ne $null | Select-Object urls, tcpports, udpports, ips, notes
    }

    if ($note) {
        $TestEndpoints = $Endpoints | Where-Object Notes -Match $note | Select-Object urls, tcpports, udpports, ips, notes
    }

    if ($ServiceAreaDisplayName) {
        $TestEndpoints = $Endpoints | Where-Object ServiceAreaDisplayName -Match $ServiceAreaDisplayName | Select-Object urls, tcpports, udpports, ips, notes
    }

    if ($URL) {
        $TestEndpoints = $Endpoints | Where-Object urls -Match $URL | Select-Object urls, tcpports, udpports, ips, notes
    }

    if ($null -eq $TestEndpoints) {
        Write-Warning ("No results found...")
        return
    }

    #Test Microsoft Endpoint Adresses and report if failed or succeeded
    $Global:ProgressPreference = 'SilentlyContinue'
    $total = foreach ($TestEndpoint in $TestEndpoints) {
        if ($TestEndpoint.tcpPorts) {
            foreach ($tcpport in $TestEndpoint.tcpPorts.split(',')) {
                foreach ($testurl in $TestEndpoint.urls) {
                    if ($TestEndpoint.notes) {
                        $notes = $TestEndpoint.notes
                    }
                    else {
                        $notes = "No notes available"
                    }
                    #Skip wildcard adresses because these are note resolvable
                    if ($testurl.Contains("*")) {
                        Write-Warning ("Skipping {0} because it's a wildcard address" -f $testurl)
                        $Status = "Failed or couldn't resolve DNS name"
                        $ipaddress = "Not applicable"
                    }
                    else {
                        #Test connection and retrieve all information
                        $test = Test-NetConnection -Port $tcpport -ComputerName $testurl -ErrorAction SilentlyContinue -InformationLevel Detailed 
                        if ($test.TcpTestSucceeded -eq $true) {
                            $Status = 'Succeeded'
                            $ipaddress = $test.RemoteAddress
                            Write-Host ("{0} is reachable on TCP port {1} ({2}) using IP-Address {3}" -f $testurl, $tcpport, $notes, $ipaddress) -ForegroundColor Green
                        
                        }
                        else {
                            $Status = "Failed or couldn't resolve DNS name"
                            $ipaddress = "Not applicable"
                        }
                    }
                    #Set iprange variable if applicable
                    if ($TestEndpoint.ips) {
                        $iprange = $TestEndpoint.ips -join (', ')
                    }
                    else {
                        $iprange = "Not applicable"
                    }
                    [PSCustomObject]@{
                        Status          = $Status
                        URL             = $testurl
                        TCPport         = $tcpport
                        IPAddressUsed   = $ipaddress
                        Notes           = $notes
                        EndpointIPrange = $iprange
                    }
                }
            }
        }
    }

    #Output results to Out-Gridview or CSV
    if (-not $CSVPath) {
        Write-Host ("Output results to Out-GridView `nDone!") -ForegroundColor Green
        $total | Sort-Object Url, TCPport | Out-GridView -Title 'Microsoft Endpoints Test results'
    }
    else {
        try {
            New-Item -Path $CSVPath -ItemType File -Force:$true -ErrorAction Stop | Out-Null
            $Total | Sort-Object Url, TCPport | Export-Csv -Path $CSVPath -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("Saved results to {0} `nDone!" -f $CSVPath) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Could not save results to {0}" -f $CSVPath)
        }
    }
}