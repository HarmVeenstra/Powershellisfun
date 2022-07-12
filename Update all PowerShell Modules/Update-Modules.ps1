#Requires -RunAsAdministrator
function Update-Modules {
    param (
        [switch]$AllowPrerelease
    )

    #Get all installed modules
    Write-Host "Retrieving all installed modules" -ForegroundColor Green
    $currentmodules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    #Show status of AllowPrerelease Switch
    if ($AllowPrerelease) {
        Write-Host "Updating installed modules to the latest PreRelease version" -ForegroundColor Green
    }
    else {
        Write-Host "Updating installed modules to the latest Production version" -ForegroundColor Green
    }
       
    #Loop through the installed modules and update them if a newer version is available
    foreach ($module in $currentmodules) {
        Write-Host "- Checking for updated version of the $($module.Name) module" -ForegroundColor Green
        try {
            update-module -Name $module.Name -AllowPrerelease:$AllowPrerelease -AcceptLicense -Scope:AllUsers 
        }
        catch {
            Write-Host "Error updating $($module.Name)" -ForegroundColor Red
        }

        #Retrieve newewst version number and remove old(er) version(s) if any
        $allversions = Get-InstalledModule -Name $module.Name -AllVersions | Sort-Object PublishedDate -Descending
        $MostRecentVersion = $AllVersions[0].Version
        if ($AllVersions.Count -gt 1 ) {
            Foreach ($Version in $AllVersions) {
                if ($Version.Version -ne $MostRecentVersion) {
                    try {
                        Write-Host "  Uninstalling previous version $($Version.Version) of module $($Module.Name)" -ForegroundColor Gray
                        Uninstall-Module -Name $Module.Name -RequiredVersion $Version.Version -Force:$True
                    }
                    catch {
                        Write-Host "  Error uninstalling previous version $($Version.Version) of module $($Module.Name)" -ForegroundColor Red
                    }
                }
            }
        }
    }

    #Get the new module versions for comparing them to to previous one if updated
    $newmodules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name
    Write-Host "`nList of updated modules (if any)" -ForegroundColor Green
    foreach ($module in $newmodules) {
        $currentversion = $currentmodules | Where-Object Name -match $module.Name
        if ($currentversion.Version -notlike $module.version) {
            Write-Host "- Updated $($module.Name) from version $($currentversion.version) to $($module.version)" -ForegroundColor Green
        }
    }
}