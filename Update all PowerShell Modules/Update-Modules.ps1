function Update-Modules {
    param (
        [switch]$Prerelease,
        [string]$Name = '*',
        [string[]]$Exclude,
        [ValidateSet('AllUsers', 'CurrentUser')][string]$Scope = 'AllUsers',
        [switch]$UpgradeToPSResource,
        [switch]$WhatIf,
        [switch]$Verbose
    )

    # Test admin privileges without using -Requires RunAsAdministrator on Windows,
    # which causes a nasty error message if trying to load the function within a PS profile but without admin privileges
    if ($IsWindows) {
        if ($Scope -eq 'AllUsers') {
            if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
                Write-Warning ("Function {0} needs admin privileges. Break now." -f $MyInvocation.MyCommand)
                return
            }
        }
    }

    # Set scope to CurrentUser if not running on Windows
    if (-not $IsWindows) {
        $Scope = 'CurrentUser'
    }

    # Install the Microsoft.PowerShell.PSResourceGet Module if not available (PowerShell v5 doesn't ship with it by default like in v7)
    if (-not (Get-Module -Name Microsoft.PowerShell.PSResourceGet -ListAvailable)) {
        try {
            Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope:$Scope -Force:$true -Confirm:$false -SkipPublisherCheck:$true -ErrorAction Stop
            Write-Host ("Installed required Microsoft.PowerShell.PSResourceGet Module") -ForegroundColor Green
        }
        catch {
            Write-Warning ("Could not install required Module Microsoft.PowerShell.PSResourceGet, check permissions! Exiting...")
            return
        }
    }

    # Configure PSGallery as Trusted if it was not configurd as Trusted
    if (-not (Get-PSResourceRepository -Name PSGallery).Trusted -eq $true) {
        try {
            Set-PSResourceRepository -Name PSGallery -Trusted:$true -Confirm:$false
            Write-Host ("Configured PSGallery as Trusted Repository") -ForegroundColor Green
        }
        catch {
            Write-Warning ("Error configuring PSGallery as Trusted Repository, exiting...")
            return
        }
    }

    # Install all modules which were installed using Install-Module to PSResourceGet
    if ($UpgradeToPSResource) {
        $InstalledModules = Get-Module -ListAvailable | Select-Object Name -Unique | Sort-Object Name
        foreach ($Module in $InstalledModules) {
            Write-Host ("Checking if module {0} was installed from PSGallery, installing it using PSResourceGet if needed" -f $module.Name) -ForegroundColor Green
            if (-not (Get-InstalledPSResource -Name $Module.Name -Scope:$Scope -ErrorAction SilentlyContinue)) {
                if (Find-Module -Name $module.name -ErrorAction SilentlyContinue) {
                    try {
                        Install-PSResource $Module.Name -Prerelease:$Prerelease.IsPresent -AcceptLicense:$true -Scope:$Scope -ErrorAction Stop -WhatIf:$WhatIf.IsPresent -Verbose:$Verbose.IsPresent -SkipDependencyCheck:$true -Reinstall:$true
                        Write-Host ("- Installed {0} using PSResourceGet" -f $module.Name) -ForegroundColor Gray
                    }
                    catch {
                        Write-Warning ("Could not install {0} using PSResourceGet, skipping..." -f $module.Name)
                    }
                }
            }
        }
    }


    # Get all installed modules minus excluded modules from $Exclude
    Write-Host ("Retrieving all installed modules ...") -ForegroundColor Green
    $CurrentModules = foreach ($Installedmodule in Get-PSResource -Name $Name -Scope:$Scope -ErrorAction SilentlyContinu ) {
        if ($null -ne $Exclude) {
            if (-not ($Installedmodule.Name | Select-String $Exclude)) {
                [PSCustomObject]@{
                    Name    = $Installedmodule.Name
                    Version = $Installedmodule.Version
                }
            }
        }
        else {
            [PSCustomObject]@{
                Name    = $Installedmodule.Name
                Version = $Installedmodule.Version
            }
        }
    }

    if (-not $CurrentModules) {
        Write-Host ("No modules found.") -ForegroundColor Gray
        return
    }
    else {
        $ModulesCount = $CurrentModules.Name.Count
        $DigitsLength = $ModulesCount.ToString().Length
    }

    # Show status of Prerelease Switch
    if ($Prerelease) {
        Write-Host ("Updating installed modules to the latest PreRelease version ...") -ForegroundColor Green
    }
    else {
        Write-Host ("Updating installed modules to the latest Production version ...") -ForegroundColor Green
    }

    # Retrieve current versions of modules if $CurrentModules is greater than 0
    if ($CurrentModules.Count -eq 1) {
        Write-Host ("Checking online versions for installed module {0}" -f $name) -ForegroundColor Green
        $Onlineversions = Find-PSResource -Name $CurrentModules.name
    }
    if ($CurrentModules.Count -gt 1) {
        Write-Host ("Checking online version for the {0} installed modules" -f $CurrentModules.Count) -ForegroundColor Green
        $Onlineversions = Find-PSResource -Name $CurrentModules.name
    }

    if (-not $CurrentModules) {
        Write-Warning ("No modules were found to check for updates, please check your NameFilter. Exiting...")
        return
    }

    # Loop through the installed modules and update them if a newer version is available
    $i = 0
    foreach ($Module in $CurrentModules | Sort-Object Name) {
        $i++
        $Counter = ("[{0,$DigitsLength}/{1,$DigitsLength}]" -f $i, $ModulesCount)
        $CounterLength = $Counter.Length
        Write-Host ('{0} Checking for updated version of module {1} ...' -f $Counter, $Module.Name) -ForegroundColor Green
        try {
            $latest = $Onlineversions | Where-Object Name -EQ $module.Name -ErrorAction Stop
            if ([version]$Module.Version -lt [version]$latest.version) {
                Update-PSResource -Name $Module.Name -Prerelease:$Prerelease.IsPresent -AcceptLicense:$true -Scope:$Scope -Force:$True -ErrorAction Stop -WhatIf:$WhatIf.IsPresent -Verbose:$Verbose.IsPresent -SkipDependencyCheck:$true
            }
        }
        catch {
            Write-Host ("{0,$CounterLength} Error updating module {1}! (In use?)" -f ' ', $Module.Name) -ForegroundColor Red
        }

        # Retrieve newest version number and remove old(er) version(s) if any
        $AllVersions = Get-PSResource -Name $Module.Name -Scope:$Scope | Sort-Object PublishedDate -Descending
        $MostRecentVersion = $AllVersions[0].Version
        if ($AllVersions.Count -gt 1 ) {
            foreach ($Version in $AllVersions) {
                if ($Version.Version -ne $MostRecentVersion) {
                    try {
                        Write-Host ("{0,$CounterLength} Uninstalling previous version {1} of module {2} ..." -f ' ', $Version.Version, $Module.Name) -ForegroundColor Gray
                        Uninstall-PSResource -Name $Module.Name -Version $Version.Version -ErrorAction Stop -Prerelease:$Prerelease.IsPresent -WhatIf:$WhatIf.IsPresent -Verbose:$Verbose.IsPresent -SkipDependencyCheck:$true -Scope:$Scope
                    }
                    catch {
                        Write-Warning ("{0,$CounterLength} Error uninstalling previous version {1} of module {2}! (In use?)" -f ' ', $Version.Version, $Module.Name)
                    }
                }
            }
        }
    }

    # Get the new module versions for comparing them to the previous one if updated
    $NewModules = Get-PSResource -Name $Name -Scope:$Scope | Where-Object Name -NotMatch $Exclude | Select-Object Name, Version | Sort-Object Name
    if ($NewModules) {
        ''
        Write-Host ("List of updated modules:") -ForegroundColor Green
        $NoUpdatesFound = $true
        foreach ($Module in $NewModules) {
            $CurrentVersion = $CurrentModules | Where-Object Name -EQ $Module.Name
            if ($CurrentVersion.Version -notlike $Module.Version) {
                $NoUpdatesFound = $false
                Write-Host ("- Updated module {0} from version {1} to {2} and/or removed older version(s) if any..." -f $Module.Name, ($CurrentVersion.Version | Sort-Object Ascending | Select-Object -First 1), $Module.Version) -ForegroundColor Green
            }
        }

        if ($NoUpdatesFound) {
            Write-Host ("No modules were updated.") -ForegroundColor Gray
        }
    }
}