#Function for reading the Intune Management Extension log
function Get-IntuneLogContent {
    param (
        [Parameter(Mandatory = $true)][string]$Filepath
    )
    
    if (-not (Test-Path -Path $Filepath -ErrorAction SilentlyContinue)) {
        Write-Warning ("Error accessing {0}, check permissions" -f $false)
        return
    }

    #Start reading logfile
    $LogTotal = foreach ($line in Get-Content -Path $Filepath) {
        #Get Time-stamp
        try {
            $time = (Select-String 'time=(.*)' -InputObject $line).Matches.groups[0].value.split('"')[1]
        }
        catch {
            $time = 'n.a.'
        }

        #Get date
        try {
            $date = (Select-String 'date=(.*)' -InputObject $line).Matches.groups[0].value.split('"')[1]
        }
        catch {
            $date = 'n.a.'
        }
            
        #Set datetime to n.a. if not found
        if ($date -ne 'n.a.' -and $time -ne 'n.a.') {
            $datetime = "$($date) $($time)"
        }
        else {
            $datetime = 'n.a.' 
        }

        #Get the component value
        try {
            $component = (Select-String 'component=(.*)' -InputObject $line).matches.groups[0].value.split('"')[1]
        }
        catch {
            $component = 'n.a'
        }

        #If line is part of a muli-line, display it or else split it to message text
        If ($line.StartsWith('<![LOG') -ne $true -or ($line.Split('!><')[3]).length -eq 0 ) {
            $text = $line
        }
        else {
            $text = $line.Split('!><')[3]
        }

        [PSCustomObject]@{
            'Log Text'  = $text
            'Date/Time' = $datetime
            Component   = $component
        }
    } 

    #Return found items in a GridView
    $LogTotal | Out-GridView -Title $Filepath
}
function Show-IntuneManagementExtensionLog {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (      
        [parameter(ParameterSetName = "Indiviudal")][switch]$AgentExecutor,
        [parameter(ParameterSetName = "All")][switch]$All,
        [parameter(ParameterSetName = "Indiviudal")][switch]$ClientHealth,
        [parameter(ParameterSetName = "Indiviudal")][switch]$IntuneManagementExtension,
        [parameter(ParameterSetName = "Indiviudal")][switch]$Sensor
    )

    #Warn if not parameter specified
    if (-not ($AgentExecutor.IsPresent -or $All.IsPresent -or $ClientHealth.IsPresent -or $IntuneManagementExtension.IsPresent -or $Sensor.IsPresent)) {
        Write-Warning ("No parameter specified, please use the AgentExecutor, All, ClientHealth, IntuneManagementExtension or Sensor parameter to display the log(s)...")
        return
    }

    #If all parameter is set, set all switches to True
    if ($all) {
        Write-Host ("Processing all logs...") -ForegroundColor Green
        $AgentExecutor = $true
        $ClientHealth = $true
        $IntuneManagementExtension = $true
        $Sensor = $true
    }

    #Invoke the Get-IntuneLogContent with the path of the log
    if ($AgentExecutor) {
        Write-Host ("Processing AgentExecutor log") -ForegroundColor Green
        Get-IntuneLogContent -FilePath C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log
    }

    if ($ClientHealth) {
        Write-Host ("Processing ClientHealth log") -ForegroundColor Green
        Get-IntuneLogContent -FilePath C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ClientHealth.log
    }

    if ($IntuneManagementExtension) {
        Write-Host ("Processing IntuneManagementExtension log") -ForegroundColor Green
        Get-IntuneLogContent -FilePath C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
    }

    if ($Sensor) {
        Write-Host ("Processing Sensor log") -ForegroundColor Green
        Get-IntuneLogContent -FilePath C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Sensor.log
    }
}