# Parameter for filtering modules for specific pattern, e.g. *Graph*
param (
    [Parameter(Mandatory = $false)][string]$NameFilter = '*'
)

#Retrieve all installed modules
Write-Host ("Retrieving installed PowerShell modules") -ForegroundColor Green
[array]$InstalledModules = Get-InstalledModule -Name $NameFilter -ErrorAction SilentlyContinue

#Retrieve current versions of modules (63 at a time because of PSGallery limit) if $InstalledModules is greater than 0
if ($InstalledModules.Count -eq 1) {
    $onlineversions = $null
    Write-Host ("Checking online versions for installed module {0}" -f $name) -ForegroundColor Green
    $currentversions = Find-Module -Name $InstalledModules.name
    $onlineversions = $onlineversions + $currentversions
}

if ($InstalledModules.Count -gt 1) {
    $startnumber = 0
    $endnumber = 62
    $onlineversions = $null
    while ($InstalledModules.Count -gt $onlineversions.Count) {
        Write-Host ("Checking online versions for installed modules [{0}..{1}/{2}]" -f $startnumber, $endnumber, $InstalledModules.Count) -ForegroundColor Green
        $currentversions = Find-Module -Name $InstalledModules.name[$startnumber..$endnumber]
        $startnumber = $startnumber + 63
        $endnumber = $endnumber + 63
        $onlineversions = $onlineversions + $currentversions
    }
}
if (-not $onlineversions) {
    Write-Warning ("No modules were found to check for updates, please check your NameFilter. Exiting...")
    return
}

#Loop through all modules and check for newer versions and add those to $total
$number = 1
Write-Host ("Checking for updated versions") -ForegroundColor Green
$total = foreach ($module in $InstalledModules) {
    Write-Progress ("[{0}/{1} Checking module {2}" -f $number, $InstalledModules.count, $module.name)
    try {
        $PsgalleryModule = $onlineversions | Where-Object name -eq $module.Name
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

#Output $total to display updates for installed modules if any
if ($total.Count -gt 0) {
    Write-Host ("Found {0} updated modules" -f $total.Count) -ForegroundColor Green
    $total | Format-Table -AutoSize
}
else {
    Write-Host ("No updated modules were found")
}
