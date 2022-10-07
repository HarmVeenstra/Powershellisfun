function Get-MicrosoftEndpoints {
    param (      
        [parameter(parameterSetName = "CSV")][string]$CSVPath
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
        Write-Warning ("Error downloading worldwide Microsoft Endpoints, please check if $($jsonlink) is accessible")
        return
    }
    
    Write-Host ("Processing items...") -ForegroundColor Green
    $Total = foreach ($Endpoint in $Endpoints) {
        #Check if IPs are available for the Endpoint, set to not available if not
        if (-not $Endpoint.ips) {
            $IPaddresses = 'Not available'
        }
        else {
            $IPaddresses = $Endpoint.ips.split(' ') -join ', '
        }

        #Check if TCP ports are available for the Endpoint, set to not available if not
        if (-not $Endpoint.tcpPorts) {
            $TCPPorts = 'Not available'
        }
        else {
            $TCPPorts = $Endpoint.TCPPorts.split(',') -join ', '
        }
            
        #Check if UDP ports are available for the Endpoint, set to not available if not
        if (-not $Endpoint.udpPorts) {
            $UDPPorts = 'Not available'
        }
        else {
            $UDPPorts = $Endpoint.udpPorts.split(',') -join ', '
        }

        #Check if there are notes for the Endpoint, set to not available if not
        if (-not $Endpoint.notes) {
            $Notes = 'Not available'
        }
        else {
            $Notes = $Endpoint.Notes
        }

        #Check if URLs are available for the Endpoint, set to not available if not
        if (-not $Endpoint.urls) {
            $URLlist = 'Not available'
        }
        else {
            $URLlist = $Endpoint.urls -join ', '
        }
                        
        [PSCustomObject]@{
            serviceArea            = $Endpoint.serviceArea
            serviceAreaDisplayName = $Endpoint.serviceAreaDisplayName
            urls                   = $URLlist
            ips                    = $IPaddresses
            tcpPorts               = $TCPPorts
            udpPorts               = $UDPPorts
            notes                  = $notes
            expressRoute           = $Endpoint.expressRoute
            category               = $Endpoint.Category
            required               = $Endpoint.required
        }
    }

    #Export data to specified $CSVPath if specified
    if ($CSVPath) {
        try {
            New-Item -Path $CSVPath -ItemType File -Force:$true -ErrorAction Stop | Out-Null
            $Total | Sort-Object serviceAreaDisplayName | Export-Csv -Path $CSVPath -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("Saved results to {0} `nDone!" -f $CSVPath) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Could not save results to {0}" -f $CSVPath)
        }
    }
    else {
        #Export to Out-Gridview
        Write-Host ("Exporting results to Out-GridView `nDone!") -ForegroundColor Green
        $Total | Sort-Object serviceAreaDisplayName | Out-GridView -Title 'Microsoft Endpoints Worldwide'
    }
}
