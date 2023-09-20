#Retrieve all installed modules
Write-Host ("Retrieving installed PowerShell modules") -ForegroundColor Green
$InstalledModules = Get-InstalledModule

#Loop through all modules and check for newer versions and add those to $total
Write-Host ("Checking for updated versions") -ForegroundColor Green
$total = foreach ($module in $InstalledModules) {
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
}

#Output $total to display updates for installed modules if any
if ($total.Count -gt 0) {
    Write-Host ("Found {0} updated modules" -f $total.Count) -ForegroundColor Green
    $total | Format-Table -AutoSize
}
else {
    Write-Host ("No updated modules were found")
}