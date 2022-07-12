#Requires -RunAsAdministrator
function Update-Modules {
    param (
        [switch]$AllowPrerelease
    )

    #Get all installed modules
    Write-Host "Retrieving all installed modules" -ForegroundColor Green
    $CurrentModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    #Show status of AllowPrerelease Switch
    if ($AllowPrerelease) {
        Write-Host "Updating installed modules to the latest PreRelease version" -ForegroundColor Green
    }
    else {
        Write-Host "Updating installed modules to the latest Production version" -ForegroundColor Green
    }
       
    #Loop through the installed modules and update them if a newer version is available
    foreach ($Module in $CurrentModules) {
        Write-Host "- Checking for updated version of the $($Module.Name) module" -ForegroundColor Green
        try {
            Update-Module -Name $Module.Name -AllowPrerelease:$AllowPrerelease -AcceptLicense -Scope:AllUsers 
        }
        catch {
            Write-Host "Error updating $($Module.Name)" -ForegroundColor Red
        }

        #Retrieve newest version number and remove old(er) version(s) if any
        $AllVersions = Get-InstalledModule -Name $Module.Name -AllVersions | Sort-Object PublishedDate -Descending
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
    $NewModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name
    Write-Host "`nList of updated modules (if any)" -ForegroundColor Green
    foreach ($Module in $NewModules) {
        $CurrentVersion = $CurrentModules | Where-Object Name -eq $Module.Name
        if ($CurrentVersion.Version -notlike $Module.Version) {
            Write-Host "- Updated $($Module.Name) from version $($CurrentVersion.Version) to $($Module.Version)" -ForegroundColor Green
        }
    }
}
