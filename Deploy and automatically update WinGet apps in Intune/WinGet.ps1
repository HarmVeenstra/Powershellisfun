[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [parameter(Mandatory = $true)][string]$Id,
    [parameter(Mandatory = $true, ParameterSetName = 'Install')][string]$Version,
    [parameter(Mandatory = $true, ParameterSetName = 'Install')][switch]$Install,
    [parameter(Mandatory = $true, ParameterSetName = 'Uninstall')][switch]$Uninstall
)

#Start Transcript logging to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$Id.txt
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($Id).txt" -Append:$true -Force:$true

#Import the Microsoft.WinGet.Client module
Import-Module Microsoft.WinGet.Client
Write-Host ("{0} - Imported the Microsoft.WinGet.Client module" -f $(Get-Date -Format "dd-MM-yy HH:MM"))

#Install specified software with the latest or specified version
try {
    if ($Install -and $Version -eq 'Latest') {
        Write-Host ("{0} - Installing latest version of {1}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id)
        Install-WinGetPackage -Id $Id -Force:$true -Mode Silent -MatchOption EqualsCaseInsensitive -Scope SystemOrUnknown -Source WinGet -ErrorAction Stop
        if (Get-WinGetPackage -Id $Id -MatchOption EqualsCaseInsensitive -Source WinGet -ErrorAction Stop) {
            Write-Host ("{0} - Installed latest version of {1}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id)
        }
        else {
            Write-Host ("{0} - Error installing {1} with version {2} (Id or version not found?), exiting..." -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id, $Version)
            Stop-Transcript
            exit 1
        }
    }
    if ($Install -and $Version -ne 'Latest') {
        Write-Host ("{0} - Installing version {1} of {2}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Version, $Id)
        Install-WinGetPackage -Id $Id -Version $Version -Force:$true -Mode Silent -MatchOption EqualsCaseInsensitive -Scope SystemOrUnknown -Source WinGet -ErrorAction Stop
        if (Get-WinGetPackage -Id $Id -MatchOption EqualsCaseInsensitive -Source WinGet -ErrorAction Stop) {
            Write-Host ("{0} - Installed version {1} of {2}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Version, $Id)
        }
        else {
            Write-Host ("{0} - Error installing {1} with version {2} (Id or version not found?), exiting..." -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id, $Version)
            Stop-Transcript
            exit 1
        }
    }
}
catch {
    Write-Host ("{0} - Error installing {1} with version {2} (Id or version not found?), exiting..." -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id, $Version)
    Stop-Transcript
    exit 1
}

#If the file .\Custom.ps1 exists, it will be used to run additional commands after Install.
#Check c:\program data\wingetintune\$Id_custom.txt for logs
if ((Test-Path .\Custom.ps1) -and $Install) {
    Write-Host ("{0} - Executing Custom install command from .\Custom.ps1" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
    .\Custom.ps1 -Id $Id -Install
    Write-Host ("{0} - Executed Custom install command from .\Custom.ps1" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
}

#Uninstall specified software
if ($uninstall) {
    try {
        Write-Host ("{0} - Uninstalling {1}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id)
        Uninstall-WinGetPackage -Id $Id -Force:$true -MatchOption EqualsCaseInsensitive -Mode Silent -ErrorAction Stop
        Write-Host ("{0} - Uninstalled {1}" -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id)
    }
    catch {
        Write-Host ("{0} - Error uninstalling {1}, exiting..." -f $(Get-Date -Format "dd-MM-yy HH:MM"), $Id)
        Stop-Transcript
        exit 1
    }
}

#If the file .\Custom.ps1 exists, it will be used to run additional commands after Uninstall.
#Check C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$Id_custom.txt for logs
if ((Test-Path .\Custom.ps1) -and $Uninstall) {
    Write-Host ("{0} - Executing Custom uninstall command from .\Custom.ps1" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
    .\Custom.ps1 -Id $Id -Uninstall
    Write-Host ("{0} - Executed Custom uninstall command from .\Custom.ps1" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
}

#Stop Transcript logging to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$Id.txt
Stop-Transcript
exit 0