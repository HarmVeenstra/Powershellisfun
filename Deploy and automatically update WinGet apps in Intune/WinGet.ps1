[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [parameter(Mandatory = $true)][string]$Id,
    [parameter(Mandatory = $true, ParameterSetName = 'Install')][string]$Version,
    [parameter(Mandatory = $true, ParameterSetName = 'Install')][switch]$Install,
    [parameter(Mandatory = $true, ParameterSetName = 'Uninstall')][switch]$Uninstall
)

#Start Transcript logging to c:\program data\wingetintune\$id.txt
Start-Transcript -Path "C:\ProgramData\WinGetIntune\$($id).txt" -Append:$true -Force:$true

#Import the Microsoft.WinGet.Client module
Import-Module Microsoft.WinGet.Client
Write-Host ("Imported the Microsoft.WinGet.Client module")

#Install specified software with the latest or specified version
try {
    if ($install -and $version -eq 'Latest') {
        Write-Host ("Installing latest version of {0}" -f $Id)
        Install-WinGetPackage -Id $Id -Force:$true -Mode Silent -Scope System -MatchOption EqualsCaseInsensitive -ErrorAction Stop
        Write-Host ("Installed latest version of {0}" -f $Id)
    }
    if ($install -and $version -ne 'Latest') {
        Write-Host ("Installing version {0} of {1}" -f $Version, $Id)
        Install-WinGetPackage -Id $Id -Version $Version -Force:$true -Mode Silent -MatchOption EqualsCaseInsensitive -Scope System -ErrorAction Stop
        Write-Host ("Installed version {0} of {1}" -f $Version, $Id)
    }
}
catch {
    Write-Host ("Error installing {0} with version {1} (Id or version not found?), exiting..." -f $id, $Version)
    Stop-Transcript
    exit 1
}

#If the file .\Custom.ps1 exists, it will be used to run additional commands after Install.
#Check c:\program data\wingetintune\$id_custom.txt for logs
if ((Test-Path .\Custom.ps1) -and $Install) {
    Write-Host ("Executing Custom install command from .\Custom.ps1")
    .\Custom.ps1 -Id $Id -Install
    Write-Host ("Executed Custom install command from .\Custom.ps1")
}

#Uninstall specified software
if ($uninstall) {
    try {
        Write-Host ("Uninstalling {0}" -f $Id)
        Uninstall-WinGetPackage -Id $Id -Force:$true -MatchOption EqualsCaseInsensitive -Mode Silent -ErrorAction Stop
        Write-Host ("Uninstalled {0}" -f $Id)
    }
    catch {
        Write-Host ("Error uninstalling {0}, exiting..." -f $id)
        Stop-Transcript
        exit 1
    }
}

#If the file .\Custom.ps1 exists, it will be used to run additional commands after Uninstall.
#Check c:\program data\wingetintune\$id_custom.txt for logs
if ((Test-Path .\Custom.ps1) -and $Uninstall) {
    Write-Host ("Executing Custom uninstall command from .\Custom.ps1")
    .\Custom.ps1 -Id $Id -Uninstall
    Write-Host ("Executed Custom uninstall command from .\Custom.ps1")
}

#Stop Transcript logging to c:\program data\wingetintune\$id.txt
Stop-Transcript
exit 0