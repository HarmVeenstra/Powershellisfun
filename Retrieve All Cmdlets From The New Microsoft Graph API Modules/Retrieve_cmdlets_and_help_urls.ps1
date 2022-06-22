#Set Total variable to null
$total = @()
 
#Set CSV location
$csvlocation = 'd:\temp\Microsoft.Graph.Cmdlets.csv'
 
#Get a list of all available Microsoft.Graph modules
Write-host Getting a list of available online Microsoft.Graph modules... -ForegroundColor Green
$OnlineMicrosoftGraphModules = find-module -name Microsoft.Graph* | Where-Object Name -NotMatch 'Microsoft.Graph.PlusPlus' | Sort-Object Name
 
#Get a list of all installed Microsoft.Graph Modules
Write-host Getting a list of installed Microsoft.Graph modules... -ForegroundColor Green
$InstalledMicrosoftGraphModules = Get-InstalledModule -Name Microsoft.Graph*
 
#Install and import all Microsoft.Graph modules except the PlusPlus module which is for AzureAD 'work or school' accounts and 'personal' Microsoft accounts
Write-Host "Installing all Microsoft.Graph Modules but skipping is already installed..." -ForegroundColor Green
foreach ($module in $OnlineMicrosoftGraphModules) {
    if (-not ($InstalledMicrosoftGraphModules -match $module.Name)) {
        write-host "Installing $($module.Name)..." -ForegroundColor Green
        Install-Module -Name $module.Name -ErrorAction SilentlyContinue
    }
}
 
#Resfresh the list of all installed Microsoft.Graph Modules after installing all Microsft Graph modules
Write-host Resfreshing the list of installed Microsoft.Graph modules... -ForegroundColor Green
$InstalledMicrosoftGraphModules = Get-InstalledModule -Name Microsoft.Graph*
 
#Remove oldest version of Microsoft.Graph modules if there are more versions installed
Foreach ($Module in $InstalledMicrosoftGraphModules | Sort-Object Name) {
    Write-Host Checking for older versions of the $Module.Name PowerShell Module and removing older versions if found... -ForegroundColor Green
    $AllVersions = Get-InstalledModule -Name $Module.Name -ErrorAction:SilentlyContinue | Sort-Object PublishedDate -Descending
    $MostRecentVersion = $AllVersions[0].Version
    if ($AllVersions.Count -gt 1 ) {
        Foreach ($Version in $AllVersions) {
            if ($Version.Version -ne $MostRecentVersion) {
                Write-Host "Uninstalling previous version" $Version.Version "of Module" $Module.Name -ForegroundColor Yellow
                Uninstall-Module -Name $Module.Name -RequiredVersion $Version.Version -Force:$True
            }
        }
    }
}
 
#retrieve all cmdlets together with the synopsis and add them to $total
foreach ($module in $InstalledMicrosoftGraphModules) { 
    Write-Host "Processing $($module.Name)..." -ForegroundColor Green
    $cmdlets = get-command -Module $module.Name
    foreach ($cmdlet in $cmdlets) {
        #Retrieve Synopsis (Remove Read-Only, Read-Wite, Nullable and Supports $expand if found) and URL to docs.microsoft.com for the cmdlet
        $help = Get-Help $cmdlet
        $synopsis = $help.Synopsis.replace('Read-only.', '').replace('Read-Write.', '').replace('Nullable.', '').replace('Supports $expand.', '').replace('Not nullable.', '').replace('\r', " ")
        $synopsis = $synopsis -replace '\n', ' ' -creplace '(?m)^\s*\r?\n', ''
        #Set variable for non matching cmdlet name and synopsis content
        $cmdletoldname = $cmdlet.Name.Replace('-', '-Mg')
        $url = $help.relatedLinks.navigationLink.uri
        #Set Synopsis or URL to "Not Available" when no data is found
        if ($null -eq $synopsis -or $synopsis.Length -le 2 -or $synopsis -match $cmdletoldname -or $synopsis -match $cmdlet.Name) { $synopsis = "Not available" }
        if ($null -eq $url) { $url = "Not available" }
        $foundcmdlets = [PSCustomObject]@{
            Source      = $cmdlet.Source
            Version     = $cmdlet.Version
            Cmdlet      = $cmdlet.Name
            Synopsis    = $synopsis
            URL         = $url
        }
        $total += $foundcmdlets
    }
}
 
#Save all results to the CSV location specified in the variable $CSVlocation
Write-Host Exporting results to $csvlocation -ForegroundColor Green
try {
    $total | Sort-Object Source, Cmdlet | Export-Csv -Path $csvlocation -NoTypeInformation -Delimiter ';' -Encoding UTF8
}
catch {
    write-host "Error saving results to $($csvlocation), please check if path is accessible" -ForegroundColor Red
}