#Running Get-WinGetPackage and Repair-WinGetPackageManager in PowerShell v7 because the WinGet cmdlets don't work in SYSTEM context in PowerShell v5
#See https://github.com/microsoft/winget-cli/issues/4820
#Supply the ID and version of the WinGet package here, use Latest if version is not important
#For example $Id = 'notepad++.notepad++' / $Version = '8.7.8' or $Id = '7zip.7zip' / $Version = 'Latest'
$Id = 'insert_package_id_here'
$Version = 'Latest'

#Start Transcript logging to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$Id.txt
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($Id).txt" -Append:$true -Force:$true

#Check if PowerShell v7 is installed before continuing the Detection
if (-not (Test-Path -LiteralPath 'C:\Program Files\PowerShell\7\pwsh.exe')) {
    Write-Host ("{0} - PowerShell v7 was not found at 'C:\Program Files\PowerShell\7\pwsh.exe', exiting..." -f $(Get-Date -Format "dd-MM-yy HH:mm"))
    Stop-Transcript
    exit 1
}

#Check if software is installed
$software = & 'C:\Program Files\PowerShell\7\pwsh.exe' -MTA -Command {
    #Import the Microsoft.WinGet.Client module, install it if it's not found or update if outdated
    try {
        if (Get-Module Microsoft.WinGet.Client -ListAvailable) {
            if ((Get-Module Microsoft.WinGet.Client -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version -lt (Find-Module Microsoft.WinGet.Client).Version) {
                Update-Module Microsoft.WinGet.Client -Force:$true -Confirm:$false -Scope AllUsers
            }
        }
        Import-Module Microsoft.WinGet.Client -ErrorAction Stop
    }
    catch {
        Install-Module Microsoft.WinGet.Client -Force:$true -Confirm:$false -Scope AllUsers
        Import-Module Microsoft.WinGet.Client
    }
    #Repair/Install WinGetPackagemanager if not found
    try {
        Assert-WinGetPackageManager -ErrorAction Stop
    }
    catch {
        Repair-WinGetPackageManager -AllUsers -Force:$true -Latest:$true
    }
    #Get all WinGetPackages
    Get-WinGetPackage -Source WinGet
} | Where-Object Id -EQ $Id

#If $Id was not found, stop and exit, and let Intune install it, or do nothing if it was uninstalled
if ($null -eq $software) {
    Write-Host ("{0} - {1} was not found on this system, installing now or doing nothing if it was uninstalled..." -f $(Get-Date -Format "dd-MM-yy HH:mm"), $Id)
    Stop-Transcript
    exit 1
}

#Check version and exit 1 if the version is not the same as the installed version or when there's an update available
if ($Version -ne 'Latest') {
    if ([version]$version -le [version]$software.InstalledVersion) {
        Write-Host ("{0} - Installed version {1} of {2} is higher or equal than specified version {3}, nothing to do..." -f $(Get-Date -Format "dd-MM-yy HH:mm"), [version]$software.InstalledVersion, $Id, [version]$Version)
        Stop-Transcript
        exit 0
    }
    if ([version]$version -gt [version]$software.InstalledVersion) {
        Write-Host ("{0} - {1} version is {2}, which is lower than specified {3} version, updating now..." -f $(Get-Date -Format "dd-MM-yy HH:mm"), $Id, $software.InstalledVersion, $Version)
        Stop-Transcript
        exit 1
    }
}

if ($version -eq 'Latest') {
    if ($software.IsUpdateAvailable -eq $false) {
        Write-Host ("{0} - {1} version is current (Version {2}), nothing to do..." -f $(Get-Date -Format "dd-MM-yy HH:mm"), $Id, $software.InstalledVersion)
        Stop-Transcript
        exit 0
    }
    else {
        Write-Host ("{0} - {1} was found with version {2}, but there's an update available for it ({3}), updating now..." -f $(Get-Date -Format "dd-MM-yy HH:mm"), $Id, $software.InstalledVersion, $($software.AvailableVersions | Select-Object -First 1))
        Stop-Transcript
        exit 1
    }
}