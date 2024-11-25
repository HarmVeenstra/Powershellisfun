param (
    [Parameter(Mandatory = $false)][string]$APIKEY = 'XXX-XXX-XXX',
    [Parameter(Mandatory = $false)][int]$Seconds = 45,
    [Parameter(Mandatory = $true)][string[]]$URL,
    [Parameter(Mandatory = $false)][validateset("public", "unlisted", "private")][string]$Type = 'private'
)

#Retrieve actual url(s) for $URL
$ProgressPreference = "SilentlyContinue"
$ExpandedURLs = foreach ($Site in $URL) {
    try {
        $LongURL = (Invoke-WebRequest -Uri $Site -MaximumRedirection 0 -ErrorAction SilentlyContinue).Headers.Location
        [PSCustomObject]@{
            ShortURL = $Site
            LongURL  = if ($LongURL) { $LongURL } else { $site }
        }
        Write-Host ("Processed {0}..." -f $Site ) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Specified {0} URL could not be found or expanded, skipping..." -f $Site)
    }
}

#Submit expanded $URL(s) for checking on urlscan.io if $ExpandedURLs returned LongURL(s)
if ($ExpandedURLs) {
    $Headers = @{
        'Content-Type' = "application/json"
        'API-Key'      = "$APIKEY"
    }
    $submits = foreach ($ExpandedURL in $ExpandedURLs) {
        $request = @{
            'url'        = $ExpandedURL.LongURL
            'visibility' = $Type
        }
        try {
            $Submit = Invoke-RestMethod -Uri 'https://urlscan.io/api/v1/scan/' -Method Post -Headers $Headers -Body $($Request | ConvertTo-Json) -ErrorAction Stop
            [PSCustomObject]@{
                ShortURL = $ExpandedURL.ShortURL
                LongURL  = $ExpandedURL.LongURL
                message  = $Submit.message
                api      = $Submit.api
            }
            Write-Host ("Submitted specified {0} Short URL to be scanned as {1}..." -f $ExpandedURL.ShortURL, $ExpandedURL.LongURL) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Error submitting {0}, check URL manually on urlscan.io because it might be blocked from scanning..." -f $ExpandedURL.ShortURL)
        }
    }

    #Retrieve results for submitted urls if any, wait for the amount of seconds specified in $Seconds (Default is 45)
    if ($submits) {
        Write-Host ("Sleeping for {0} seconds to wait on results..." -f $Seconds) -ForegroundColor Green
        Start-Sleep -Seconds $Seconds
        $results = foreach ($response in $submits) {
            try {
                $data = Invoke-RestMethod -Uri $response.api -Method Get -ErrorAction Stop
                [PSCustomObject]@{
                    ShortURL    = $response.ShortURL
                    LongURL     = $response.LongURL
                    Score       = $data.verdicts.overall.score
                    Categories  = if ($data.verdicts.overall.categories) { $data.verdicts.overall.categories } else { "None" }
                    Brands      = if ($data.verdicts.overall.brands) { $data.verdicts.overall.brands } else { "None" }
                    Malicious   = if ($data.verdicts.overall.Malicious) { $data.verdicts.overall.Malicious } else { "None" }
                    Hasverdicts = $data.verdicts.overall.hasVerdicts
                }
            }
            catch {
                Write-Warning ("Could not retrieve results for {0}" -f $response.ShortURL)
            }
        }
        return $results | Sort-Object ShortURL | Format-Table -AutoSize
    }
    else {
        Write-Warning ("URLS failed to submit, try to increase time-out or scan manually on urlscan.io. Exiting...")
        return
    }
}
else {
    Write-Warning ("Supplied URL(s) could not be found, exiting..." )
    return
}