# Parameter for filtering modules for specific pattern, e.g. *Graph*
param (
    [Parameter(Mandatory = $false)][string]$NameFilter = '*'
)

#Retrieve all installed modules
Write-Host ("Retrieving installed PowerShell modules") -ForegroundColor Green
$InstalledModules = Get-InstalledModule -Name $NameFilter -ErrorAction SilentlyContinue

#Start checking for updates if $InstalledModules is greater than 1
if ($InstalledModules.Count -gt 0) {
    $number = 1
    #Loop through all modules and check for newer versions and add those to $total
    Write-Host ("Checking for updated versions") -ForegroundColor Green
    $total = foreach ($module in $InstalledModules) {
        Write-Progress ("[{0}/{1} Checking module {2}" -f $number, $InstalledModules.count, $module.name)
        try {
            $PsgalleryModule = Find-Module -Name $Module.Name -ErrorAction Stop
            if ([version]$module.version -lt [version]$PsgalleryModule.version) {
                [PSCustomObject]@{
                    Repository          = $module.Repository
                    'Module name'       = $module.Name
                    'Installed version' = $module.Version
                    'Latest version'    = $PsgalleryModule.version
                    'Published on'      = $PsgalleryModule.PublishedDate
                }
            }
        }
        catch {
            Write-Warning ("Could not find module {0}" -f $module.Name)
        }
        $number++
    }
}
else {
    Write-Warning ("No modules were found to check for updates, please check yourNameFilter. Exiting...")
    return
}

#Output $total to display updates for installed modules if any
if ($total.Count -gt 0) {
    Write-Host ("Found {0} updated modules" -f $total.Count) -ForegroundColor Green
    $total | Format-Table -AutoSize
}
else {
    Write-Host ("No updated modules were found")
}