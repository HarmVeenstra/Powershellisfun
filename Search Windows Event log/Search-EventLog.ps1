#-Requires RunAsAdministrator
function Search-Eventlog {
    
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of remote computer")][string]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory = $false, HelpMessage = "Number of hours to search back for")][double]$Hours,
        [Parameter(Mandatory = $false, HelpMessage = "EventID number")][string]$EventID,
        [Parameter(Mandatory = $false, HelpMessage = "The name of the eventlog to search in")][string[]]$EventLogName,
        [Parameter(Mandatory = $false, HelpMessage = "Output results in a gridview")][switch]$Gridview,
        [Parameter(Mandatory = $false, HelpMessage = "String to search for")][string]$Filter,
        [Parameter(Mandatory = $false, HelpMessage = "Output path, e.g. c:\data\events.csv")][string]$Output
    )

    #Set $hours to -1 to $hours if not specified
    if (-not $Hours) {
        [DateTime]$hours = (Get-Date).AddHours(-1)
    }
    else {
        [DateTime]$hours = (Get-Date).AddHours(-$hours)
    }

    #Test if EventLogName is available
    if ($EventLogName) {
        try {
            Get-WinEvent -ListLog $EventLogName -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            Write-Host ("Specified EventLog name {0} is valid on {1}, continuing..." -f $($EventLogName), $ComputerName) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Specified EventLog name {0} is not valid or can't access {1}, exiting..." -f $($EventLogName), $ComputerName)
            return
        }
    }

    #Create array of logs for Eventlogname if not specified
    if (-not $EventLogName) {
        try {
            $EventLogNames = Get-WinEvent -ListLog * -ComputerName $ComputerName
        }
        catch {
            Write-Warning ("Can't retrieve Eventlogs on {0}, exiting..." -f $ComputerName)
            return
        }
    }

    #set Eventlogname
    if ($EventLogName) {
        $EventLogNames = Get-WinEvent -ListLog $EventLogName
    }

    #Retrieve events
    $lognumber = 1
    $total = foreach ($log in $EventLogNames | Sort-Object LogName) {
        $foundevents = 0
        Write-Host ("[Eventlog {0}/{1}] - Retrieving events from the {2} Event log on {3}..." -f $lognumber, $EventLogNames.count, $log.LogName, $ComputerName) -ForegroundColor Green
        #Specify different type of filters
        try {
            if (-not $EventID) {
                $events = Get-WinEvent -FilterHashtable @{
                    LogName   = $log.LogName
                    StartTime = $hours
                } -ErrorAction Stop
            }

            if ($EventID) {
                $events = Get-WinEvent -FilterHashtable @{
                    LogName   = $log.LogName
                    StartTime = $hours
                    ID        = $EventID
                } -ErrorAction Stop
            }

            foreach ($event in $events) {
                if (-not $Filter -or $event.Message -match $Filter) {
                    [PSCustomObject]@{
                        Time         = $event.TimeCreated.ToString('dd-MM-yyy HH:mm')
                        Computer     = $ComputerName
                        LogName      = $event.LogName
                        ProviderName = $event.ProviderName
                        Level        = $event.LevelDisplayName
                        User         = if ($event.UserId) {
                            "$($event.UserId)"
                        }
                        else {
                            "N/A"
                        }
                        EventID      = $event.ID
                        Message      = $event.Message
                    }
                    $foundevents++
                }
            }
        }
        catch {
            Write-Host ("No events found in {0} within the specified time-frame (After {1}), EventID or Filter on {2}, skipping..." -f $log.LogName, $Hours, $ComputerName)
        }
        $lognumber++
        Write-Host ("{0} events found in the {1} Event log on {2}" -f $foundevents, $log.LogName, $ComputerName) -ForegroundColor Green
    }

    #Output results to GridView
    if ($Gridview -and $total) {
        return $total | Sort-Object Time, LogName | Out-GridView -Title 'Retrieved events...'
    }

    #Output results to specified file location
    if ($Output -and $total) {
        try {
            $total | Sort-Object Time, LogName | export-csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path $Output -ErrorAction Stop
            Write-Host ("Exported results to {0}" -f $Output) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Error saving results to {0}, check path or permissions. Exiting...")
            return
        }
    }
    
    #Output to screen is Gridview or Output were not specified
    if (-not $Output -and -not $Gridview -and $total) {
        return $total | Sort-Object Time, LogName
    }

    #Return warning if no results were found
    if (-not $total) {
        Write-Warning ("No results were found on {0}..." -f $ComputerName)
    }
}