function Update-Modules {
	param (
		[switch]$AllowPrerelease,
		[string]$Name = '*',
		[ValidateSet('AllUsers', 'CurrentUser')][string]$Scope = 'AllUsers',
		[switch]$WhatIf,
		[switch]$Verbose
	)
	
	#Test admin privileges without using -Requires RunAsAdministrator,
	# which causes a nasty error message, if trying to load the function within a PS profile but without admin privileges
	if ($Scope -eq 'AllUsers') {
		if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
			Write-Warning ("Function {0} needs admin privileges. Break now." -f $MyInvocation.MyCommand)
			return
		}
	}

	# Get all installed modules
	Write-Host ("Retrieving all installed modules ...") -ForegroundColor Green
	[array]$CurrentModules = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue | Select-Object Name, Version | Sort-Object Name

	if (-not $CurrentModules) {
		Write-Host ("No modules found.") -ForegroundColor Gray
		return
	}
	else {
		$ModulesCount = $CurrentModules.Name.Count
		$DigitsLength = $ModulesCount.ToString().Length
		Write-Host ("{0} modules found." -f $ModulesCount) -ForegroundColor Gray
	}

	# Show status of AllowPrerelease Switch
	''
	if ($AllowPrerelease) {
		Write-Host ("Updating installed modules to the latest PreRelease version ...") -ForegroundColor Green
	}
	else {
		Write-Host ("Updating installed modules to the latest Production version ...") -ForegroundColor Green
	}

	#Retrieve current versions of modules (63 at a time because of PSGallery limit) if $InstalledModules is greater than 0
	if ($CurrentModules.Count -eq 1) {
		$onlineversions = $null
		Write-Host ("Checking online versions for installed module {0}" -f $name) -ForegroundColor Green
		$currentversions = Find-Module -Name $CurrentModules.name
		$onlineversions = $onlineversions + $currentversions
	}

	if ($CurrentModules.Count -gt 1) {
		$startnumber = 0
		$endnumber = 62
		$onlineversions = $null
		while ($CurrentModules.Count -gt $onlineversions.Count) {
			Write-Host ("Checking online versions for installed modules [{0}..{1}/{2}]" -f $startnumber, $endnumber, $CurrentModules.Count) -ForegroundColor Green
			$currentversions = Find-Module -Name $CurrentModules.name[$startnumber..$endnumber]
			$startnumber = $startnumber + 63
			$endnumber = $endnumber + 63
			$onlineversions = $onlineversions + $currentversions
		}
	}
	
	if (-not $CurrentModules) {
		Write-Warning ("No modules were found to check for updates, please check your NameFilter. Exiting...")
		return
	}

	# Loop through the installed modules and update them if a newer version is available
	$i = 0
	foreach ($Module in $CurrentModules) {
		$i++
		$Counter = ("[{0,$DigitsLength}/{1,$DigitsLength}]" -f $i, $ModulesCount)
		$CounterLength = $Counter.Length
		Write-Host ('{0} Checking for updated version of module {1} ...' -f $Counter, $Module.Name) -ForegroundColor Green
		try {
			$latest = $onlineversions | Where-Object Name -EQ $module.Name -ErrorAction Stop
			if ([version]$Module.Version -lt [version]$latest.version) {
				Update-Module -Name $Module.Name -AllowPrerelease:$AllowPrerelease -AcceptLicense -Scope:$Scope -Force:$True -ErrorAction Stop -WhatIf:$WhatIf.IsPresent -Verbose:$Verbose.IsPresent
			}
		}
		catch {
			Write-Host ("{0$CounterLength} Error updating module {1}!" -f ' ', $Module.Name) -ForegroundColor Red
		}

		# Retrieve newest version number and remove old(er) version(s) if any
		$AllVersions = Get-InstalledModule -Name $Module.Name -AllVersions | Sort-Object PublishedDate -Descending
		$MostRecentVersion = $AllVersions[0].Version
		if ($AllVersions.Count -gt 1 ) {
			Foreach ($Version in $AllVersions) {
				if ($Version.Version -ne $MostRecentVersion) {
					try {
						Write-Host ("{0,$CounterLength} Uninstalling previous version {1} of module {2} ..." -f ' ', $Version.Version, $Module.Name) -ForegroundColor Gray
						Uninstall-Module -Name $Module.Name -RequiredVersion $Version.Version -Force:$True -ErrorAction Stop -AllowPrerelease -WhatIf:$WhatIf.IsPresent -Verbose:$Verbose.IsPresent
					}
					catch {
						Write-Warning ("{0,$CounterLength} Error uninstalling previous version {1} of module {2}!" -f ' ', $Version.Version, $Module.Name)
					}
				}
			}
		}
	}

	# Get the new module versions for comparing them to to previous one if updated
	$NewModules = Get-InstalledModule -Name $Name | Select-Object Name, Version | Sort-Object Name
	if ($NewModules) {
		''
		Write-Host ("List of updated modules:") -ForegroundColor Green
		$NoUpdatesFound = $true
		foreach ($Module in $NewModules) {
			$CurrentVersion = $CurrentModules | Where-Object Name -EQ $Module.Name
			if ($CurrentVersion.Version -notlike $Module.Version) {
				$NoUpdatesFound = $false
				Write-Host ("- Updated module {0} from version {1} to {2}" -f $Module.Name, $CurrentVersion.Version, $Module.Version) -ForegroundColor Green
			}
		}

		if ($NoUpdatesFound) {
			Write-Host ("No modules were updated.") -ForegroundColor Gray
		}
	}
}