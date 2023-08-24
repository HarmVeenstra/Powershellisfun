#Requires -RunAsAdministrator

[CmdletBinding(DefaultparameterSetname = 'All')]
param(
    [parameter(Mandatory = $false)][string[]]$ComputerName = $env:COMPUTERNAME,    
    [parameter(Mandatory = $true)][string]$Filename,
    [parameter(Mandatory = $false, parameterSetname = "EventLog")][switch]$PowerShellEventlogOnly,
    [parameter(Mandatory = $false, parameterSetname = "History")][switch]$PSReadLineHistoryOnly
)

#Validate output $filename
if (-not ($Filename.EndsWith('.xlsx'))) {
    Write-Warning ("Specified {0} filename does not end with .xlsx, exiting..." -f $Filename)
    return
}

#Check access to the path, and if the file already exists, append if it does or test the creation of a new one
if (-not (Test-Path -Path $Filename)) {
    try {
        New-Item -Path $Filename -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
        Remove-Item -Path $Filename -Force:$true -Confirm:$false | Out-Null
        Write-Host ("Specified {0} filename is correct, and the path is accessible, continuing..." -f $Filename) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Path to specified {0} filename is not accessible, correct or file is in use, exiting..." -f $Filename)
        return
    }
}
else {
    Write-Warning ("Specified file {0} already exists, appending data to it..." -f $Filename)
}

#Check if the ImportExcel module is installed. Install it if not
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Warning ("The ImportExcel module was not found on the system, installing now...")
    try {
        Install-Module -Name ImportExcel -SkipPublisherCheck -Force:$true -Confirm:$false -Scope CurrentUser -ErrorAction Stop
        Import-Module -Name ImportExcel -Scope Local -ErrorAction Stop
        Write-Host ("Successfully installed the ImportExcel module, continuing..") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Could not install the ImportExcel module, exiting...")
        return
    }
}
else {
    try {
        Import-Module -Name ImportExcel -Scope Local -ErrorAction Stop
        Write-Host ("The ImportExcel module was found on the system, continuing...") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error importing the ImportExcel module, exiting...")
        return  
    }
    
}

#List of PowerShell event logs to search in
$Eventlogs = @(
    'Windows PowerShell'
    'PowerShellCore/Operational'
    'Microsoft-Windows-PowerShell/Admin'
    'Microsoft-Windows-PowerShell/Operational'
    'Microsoft-Windows-PowerShell-DesiredStateConfiguration-FileDownloadManager/Operational'
    'Microsoft-Windows-WinRM/Operational'
)

#Set dateformat for the Excel tabs
$date = Get-Date -Format ddMMyyhhmm

#Loop through all computers specified in $ComputerName. If not specified, it will use your local computer
foreach ($computer in $ComputerName | Sort-Object) {
    
    #Check if the computer is reachable
    if (Test-Path -Path "\\$($computer)\c$" -ErrorAction SilentlyContinue) {
        Write-Host ("`nComputer {0} is accessible, continuing..." -f $computer) -ForegroundColor Green
    
        #Eventlogs
        if (-not $PSReadLineHistoryOnly) {

            #Search all EventLogs specified in the $eventlogs variable
            $TotalEventLogs = foreach ($Eventlog in $Eventlogs) {
                $events = Get-WinEvent -LogName $Eventlog -ComputerName $computer -ErrorAction SilentlyContinue
                if ($events.count -gt 0) {
                    Write-Host ("- Exporting {0} events from the {1} EventLog" -f $events.count, $Eventlog) -ForegroundColor Green
                    foreach ($event in $events) {
                        [PSCustomObject]@{
                            ComputerName = $computer
                            EventlogName = $Eventlog
                            TimeCreated  = $event.TimeCreated
                            EventID      = $event.Id
                            Message      = $event.Message
                        }
                    }
                }
                else {
                    Write-Host ("- No events found in the {0} Eventlog" -f $Eventlog) -ForegroundColor Gray
                }
            }

            #Create an Excel file and add an Eventlog tab containing the events for the computer
            if ($TotalEventLogs.count -gt 0) {
                try {
                    $TotalEventLogs | Export-Excel -Path $Filename -WorksheetName "PowerShell_EventLog_$($date)" -AutoFilter -AutoSize -Append
                    Write-Host ("Exported Eventlog data to {0}" -f $Filename) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error exporting Eventlog data to {0} (File in use?), exiting..." -f $Filename)
                    return
                }
            }
        }


        #PSreadLineHistory
        if (-not $EventlogOnly) {

            #Search for all PSReadLine history files in all Windows User profiles on the system
            if (-not $PowerShellEventlogOnly) {
                Write-Host ("Checking for Users/Documents and Settings folder on {0}" -f $computer) -ForegroundColor Green
                try {
                    if (Test-Path "\\$($computer)\c$\Users") {
                        $UsersFolder = "\\$($computer)\c$\Users"
                    }
                    else {
                        $UsersFolder = "\\$($computer)\c$\Documents and Settings"
                    }
                }
                catch {
                    Write-Warning ("Error finding Users/Documents and Settings folder on {0}. Exiting..." -f $computer)
                    return
                }

                Write-Host ("Scanning for PSReadLine History files in {0}" -f $UsersFolder) -ForegroundColor Green
                $HistoryFiles = foreach ($UserProfileFolder in Get-ChildItem -Path $UsersFolder -Directory) {
                    $list = Get-ChildItem -Path "$($UserProfileFolder.FullName)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\*.txt" -ErrorAction SilentlyContinue
                    if ($list.count -gt 0) {
                        Write-Host ("- {0} PSReadLine history file(s) found in {1}" -f $list.count, $UserProfileFolder.FullName) -ForegroundColor Green
                        foreach ($file in $list) {
                            [PSCustomObject]@{
                                HistoryFileName = $file.FullName
                            }
                        }   
                    }
                    else {
                        Write-Host ("- No PSReadLine history file(s) found in {0}" -f $UserProfileFolder.FullName) -ForegroundColor Gray
                    }
                }

                #Get the contents of the found PSReadLine history files on the system
                $TotalHistoryLogs = foreach ($file in $HistoryFiles) {
                    $HistoryData = Get-Content -Path $file.HistoryFileName -ErrorAction SilentlyContinue
                    if ($HistoryData.count -gt 0) {
                        Write-Host ("- Exporting {0} PSReadLine History events from the {1} file" -f $HistoryData.count, $file.HistoryFileName) -ForegroundColor Green
                        foreach ($line in $HistoryData) {
                            if ($line.Length -gt 0) {
                                [PSCustomObject]@{
                                    ComputerName = $computer
                                    FileName     = $File.HistoryFileName
                                    Command      = $line
                                }
                            }
                        }
                    }
                    else {
                        Write-Warning ("No PSReadLine history found in the {0} file" -f $Log)
                    }
                }

                #Create an Excel file and add the PSReadLineHistory tab containing PowerShell history
                if ($TotalHistoryLogs.count -gt 0) {
                    try {
                        $TotalHistoryLogs | Export-Excel -Path $Filename -WorksheetName "PSReadLine_History_$($date)" -AutoFilter -AutoSize -Append
                        Write-Host ("Exported PSReadLine history to {0}" -f $Filename) -ForegroundColor Green
                    }
                    catch {
                        Write-Warning ("Error exporting PSReadLine history data to {0} (File in use?), exiting..." -f $Filename)
                        return
                    }
                }
            }
        }
    }

    else {
        Write-Warning ("Specified computer {0} is not accessible, check permissions and network settings. Skipping..." -f $computer)
        continue
    }
}