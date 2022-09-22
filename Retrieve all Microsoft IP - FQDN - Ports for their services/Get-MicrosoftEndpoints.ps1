function Get-MicrosoftEndpoints {
    param (      
        [parameter(parameterSetName = "CSV")][string]$CSVPath
    )
    
    #Hide download progress, retrieve all Endpoints and Convert it from JSON format
    $ProgressPreference = "SilentlyContinue"
    try {
        $Endpoints = Invoke-WebRequest -Uri https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7 -ErrorAction Stop | ConvertFrom-Json
        Write-Host ("Downloading worldwide Microsoft Endpoints") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error downloading worldwide Microsoft Endpoints, please check URL in script if it still matches") 
        Write-Warning ("the one found in this link https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwidein from the JSON formatted link ") 
    }
    
    $Total = @()
    Write-Host ("Processing items...") -ForegroundColor Green
    foreach ($Endpoint in $Endpoints) {
        #Check if IPs are available for the Endpoint, set to False if not applicable
        if ($null -eq $Endpoint.ips) {
            $IPaddresses = 'Not applicable'
        }
        else {
            $IPaddresses = "$($Endpoint.ips)" -join ', '
        }

        #Check if TCP ports are available for the Endpoint, set to False if not applicable
        if ($Endpoint.tcpPorts.Length -eq 0) {
            $TCPPorts = 'Not applicable'
        }
        else {
            $TCPPorts = $Endpoint.TCPPorts.Split(',') -join ', '
        }
            
        #Check if UDP ports are available for the Endpoint, set to False if not applicable
        if ($Endpoint.udpPorts.length -eq 0) {
            $UDPPorts = 'Not applicable'
        }
        else {
            $UDPPorts = $Endpoint.udpPorts.Split(',') -join ', '
        }

        #Check if URLs are available for the Endpoint, set to False if not applicable
        if ($Endpoint.urls.length -eq 0) {
            $URLlist = 'Not applicable'
        }
        else {
            $URLlist = $Endpoint.urls -join ', '
        }
                        
        $Item = [PSCustomObject]@{
            serviceArea            = $Endpoint.serviceArea
            serviceAreaDisplayName = $Endpoint.serviceAreaDisplayName
            urls                   = $URLlist
            ips                    = $IPaddresses
            tcpPorts               = $TCPPorts
            udpPorts               = $UDPPorts
            expressRoute           = $Endpoint.expressRoute
            category               = $Endpoint.Category
            required               = $Endpoint.required
        }
        $Total += $Item
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
