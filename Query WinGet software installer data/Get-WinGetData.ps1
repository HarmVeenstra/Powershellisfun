param (
    [Parameter(Mandatory = $true)][string[]]$ApplicationName,
    [Parameter(Mandatory = $false)][validateset('ConsoleGridView', 'GridView', 'List')][string]$Output = 'List',
    [Parameter(Mandatory = $false)][string]$Filename
)
    
#Check if the required modules are installed
foreach ($module in 'Microsoft.WinGet.Client', 'Microsoft.PowerShell.ConsoleGuiTools', 'powershell-yaml') {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        try {
            Write-Warning ("The required module {0} was not found, installing now..." -f $module) 
            Install-Module -Name $module -Scope CurrentUser -ErrorAction Stop
            Import-Module -Name $module -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing/importing required {0} module, exiting..." -f $module)
            return
        }
    }
    else {    
        try {
            Import-Module -Name $module -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error importing required $module module, exiting...")
            return
        }
    }
}
    
#Check $applicationname, select the application the from Out-ConsoleGridView
$Applications = foreach ($Application in $ApplicationName) {
    try {
        $results = Find-WinGetPackage $Application -Source WinGet -ErrorAction Stop | Out-ConsoleGridView -Title "Select the application from the list for selected $($Application) query" -OutputMode Multiple
        foreach ($result in $results) {
            [PSCustomObject]@{
                ID      = $result.ID
                Version = $result.Version
            }
        }
    }
    catch {
        Write-Warning ("The application(details) could not be found, exiting...")
        return
    }
}
    
#Loop through the applications and collect the details, exit if no applications were found or selected
if ($null -ne $Applications.count) {    
    $total = foreach ($item in $Applications | Sort-Object ID) {
        Write-Host ("Processing {0}..." -f $item.ID) -ForegroundColor Green
        try {
            $ApplicationYAML = Invoke-RestMethod ("https://raw.githubusercontent.com/microsoft/winget-pkgs/refs/heads/master/manifests/{0}/{1}/{2}/$($Item.ID).installer.yaml" -f $Item.ID.Substring(0, 1).ToLower(), $Item.ID.Replace('.', '/'), $Item.version) -UseBasicParsing -Method Get -ErrorAction Stop | ConvertFrom-Yaml -ErrorAction Stop
            foreach ($installer in $ApplicationYAML.Installers) {
                $applicationdetails = Get-WinGetPackageInfo -Id $item.ID -ErrorAction Stop
                [PSCustomObject]@{
                    'Name'                        = $item.ID
                    'Author'                      = if ($applicationdetails.Author) { $applicationdetails.Author } else { "Not found" }
                    'Version'                     = [version]$item.Version
                    'Release Date'                = if ($applicationdetails.'Release Date') { $applicationdetails.'Release Date' } else { "Not found" }
                    'Install Modes'               = if ($ApplicationYAML.InstallModes) { $ApplicationYAML.InstallModes -join ', ' } else { "Not found" }
                    'Installer Architecture'      = if ($installer.Architecture) { $installer.Architecture } else { "Not found" }
                    'Silent switches'             = if ($applicationYAML.InstallerSwitches.Silent) { $applicationYAML.InstallerSwitches.Silent } else { "Not found" }
                    'SilentWithProgress switches' = if ($applicationYAML.InstallerSwitches.SilentWithProgress) { $applicationYAML.InstallerSwitches.SilentWithProgress } else { "Not found" }
                    'Installer Type'              = if ($applicationYAML.InstallerType) { $applicationYAML.InstallerType } else { "Not found" }
                    'Installer URL'               = if ($installer.Installerurl) { $installer.Installerurl } else { "Not found" }
                    'HomePage'                    = if ($applicationdetails.HomePage) { $applicationdetails.HomePage } else { "Not found" }
                }
            }
        }
        catch {
            Write-Warning ("Error retrieving details for {0}" -f $item.id)
        }
    }
}
else {
    Write-Warning ("No applications were found or selected, exiting...")
    return
}
    
#If $total has items, output it to display or file
if ($null -ne $total.count) {
    #Display $total to the chosen $ouput value if $FileName was not used
    if ($Output) {
        switch ($Output) {
            ConsoleGridView {
                try {
                    $total | Sort-Object Name, Author, Version, 'Release Date', 'Installer Architecture' | Out-ConsoleGridView -Title 'WinGet Information'
                }
                catch {
                    Write-Warning ("Error sending information to Out-ConsoleGridview, exiting...")
                    return
                }
            }
            GridView { 
                try {
                    $total | Sort-Object Name, Author, Version, 'Release Date', 'Installer Architecture' | Out-GridView -Title 'WinGet Information'
                }
                catch {
                    Write-Warning ("Error sending information to Out-Gridview, exiting...")
                    return
                }
            }
            List { 
                try {
                    $total | Sort-Object Name, Author, Version, 'Release Date', 'Installer Architecture' | Format-List
                }
                catch {
                    Write-Warning ("Error sending information to Format-List, exiting...")
                    return
                }
            }
        }
    }

    #Export to file if $FileName was specified
    if ($Filename) {
        if ($Filename.EndsWith('csv')) {
            try {
                $total | Sort-Object Name, Author, Version, 'Release Date', 'Installer Architecture' | Export-Csv -Path $Filename -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Append:$true -Force:$true -ErrorAction Stop
                Write-Host ('Exported WinGet package information to {0}' -f $Filename) -ForegroundColor Green
            }
            catch {
                Write-Warning ('Could not write {0}, check path and permissions. Exiting...' -f $Filename)
                return
            }
        }
        if ($Filename.EndsWith('xlsx')) {
            if (-not (Get-Module ImportExcel -ListAvailable)) {
                try {
                    Install-Module ImportExcel -Scope CurrentUser -ErrorAction Stop
                    Import-Module ImportExcel -ErrorAction Stop
                    Write-Host ('Installed missing PowerShell Module ImportExcel which is needed for XLSX output') -ForegroundColor Green
                }
                catch {
                    Write-Warning ('Could not install missing PowerShell Module ImportExcel which is needed for XLSX output, exiting...')
                    return
                }
            }
            try {
                $total | Sort-Object Name, Author, Version, 'Release Date', 'Installer Architecture' | Export-Excel -Path $Filename -AutoSize -AutoFilter -Append:$true -ErrorAction Stop
                Write-Host ('Exported WinGet package information to {0}' -f $Filename) -ForegroundColor Green
            }
            catch {
                Write-Warning ('Could not write {0}, check path and permissions. Exiting...' -f $Filename)
                return
            }
        }
    }
}
else {
    Write-Warning ('Specified application(s) were not found, exiting...')
    return
}