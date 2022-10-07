function Get-DnsCacheReport {
    param (
        [parameter(Mandatory = $true)][string]$Minutes,
        [parameter(Mandatory = $false)][string]$CSVPath
    )
    
    #check if a valid $CSVPath was provided if used
    if ($CSVPath) {
        if (New-Item -Path $CSVPath -ItemType File -Force:$true -ErrorAction SilentlyContinue) {
            Write-Host ("Path {0} is valid, continuing..." -f $CSVPath) -ForegroundColor Green
        }
        else {
            Write-Warning ("Path {0} is not valid, please check path or permissions. Aborting..." -f $CSVPath)
        }
    }

    #Start countdown, countdown to zero and restart programs again
    #Used countdown procedure from https://www.powershellgallery.com/packages/start-countdowntimer/1.0/Content/Start-CountdownTimer.psm1
    $t = New-TimeSpan -Minutes $Minutes
    $origpos = $host.UI.RawUI.CursorPosition
    $spinner = @('|', '/', '-', '\')
    $spinnerPos = 0
    $remain = $t
    $d = ( get-date) + $t
    [int]$TickLength = 1
    $remain = ($d - (get-date))
    while ($remain.TotalSeconds -gt 0) {
        Write-Host (" {0} " -f $spinner[$spinnerPos % 4]) -ForegroundColor Green -NoNewline
        write-host ("Gathering DNS Cache information, {0}D {1:d2}h {2:d2}m {3:d2}s remaining..." -f $remain.Days, $remain.Hours, $remain.Minutes, $remain.Seconds) -NoNewline -ForegroundColor Green
        $host.UI.RawUI.CursorPosition = $origpos
        $spinnerPos += 1
        Start-Sleep -seconds $TickLength
        
        #Get DNS Cache and add to $Total variable during the amount of minutes specified
        $dnscache = Get-DnsClientCache
        $total = foreach ($item in $dnscache) {
            #Switch table date is from https://www.darkoperator.com/blog/2020/1/14/getting-dns-client-cached-entries-with-cimwmi
            switch ($item.status) {
                0 { $status = 'Success' }
                9003 { $status = 'NotExist' }
                9501 { $status = 'NoRecords' }
                9701 { $status = 'NoRecords' }        
            }

            switch ($item.Type) {
                1 { $Type = 'A' }
                2 { $Type = 'NS' }
                5 { $Type = 'CNAME' }
                6 { $Type = 'SOA' }
                12 { $Type = 'PTR' } 
                15 { $Type = 'MX' }
                28 { $Type = 'AAAA' }
                33 { $Type = 'SRV' }
            }

            switch ($item.Section) {
                1 { $Section = 'Answer' }
                2 { $Section = 'Authority' }
                3 { $Section = 'Additional' }
            }

            [PSCustomObject]@{
                Entry      = $item.Entry
                RecordType = $Type
                Status     = $status
                Section    = $Section
                Target     = $item.Data            
            }
        }
        $remain = ($d - (get-date))
    }
    $host.UI.RawUI.CursorPosition = $origpos
    Write-Host (" * ")  -ForegroundColor Green -NoNewline
    write-host (" Finished gathering DNS Cache information, displaying results in a Out-Gridview now...") -ForegroundColor Green
    if ($CSVPath) {
        write-host ("Results are also saved as {0}" -f $CSVPath) -ForegroundColor Green
    }
    
    #Save results to $CSVPath if specified as parameter
    if ($CSVPath) {
        $total | Select-Object Entry, RecordType, Status, Section, Target -Unique | Sort-Object Entry | Export-Csv -Path $CSVPath -Encoding UTF8 -Delimiter ';' -NoTypeInformation -Force
    }
    
    #Return results in Out-Gridview
    return $total | Select-Object Entry, RecordType, Status, Section, Target -Unique | Sort-Object Entry | Out-GridView  
}