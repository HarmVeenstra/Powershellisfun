#Inspired by and based on https://www.alitajran.com/export-conditional-access-named-locations-powershell/
param (
    [Parameter(Mandatory = $false)][string]$FileName
)

#Check if required Microsoft.Graph.Authentication, and Microsoft.Graph.Identity.SignIns Modules are installed
#and install them if needed
if (-not (Get-InstalledModule Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns)) {
    try {
        Install-Module -Name Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns -Scope CurrentUser -ErrorAction Stop
    }
    catch {
        Write-Warning ("Error installing required modules, exiting...")
        return
    }
}

#Connect using Microsoft Graph
try {
    Connect-MgGraph -Scopes Policy.Read.All -NoWelcome -ErrorAction Stop
} 
catch {
    Write-Warning ("Error connecting, check connection/permissions. Exiting...")
    return
}

#Retrieve all Named Locations and Conditional Access Policies
try {
    $NamedLocations = Get-MgIdentityConditionalAccessNamedLocation -All -ErrorAction Stop
    $Policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
}
catch {
    Write-Warning ("Could not retrieve Conditional Access Policies, check permissions!")
    Write-Warning ("Specified account should be member of one of the following roles:")
    Write-Warning ("Security Reader, Company Administrator, Security Administrator, Conditional Access Administrator, Global Reader, Devices Admin, Entra Network Access Administrator")
    Write-Warning ("Exiting...")
    return
}

#Exit if no Named Locations were found
if ($null -eq $NamedLocations) {
    Write-Warning ("No Named Locations were found in this tenant, exiting...")
    return
}

#Get all specific cultures and store them in $cultures
$cultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::SpecificCultures)

#Create a dictionary for country code to full country name mapping
$countryNames = @{}
foreach ($culture in $cultures) {
    $region = [System.Globalization.RegionInfo]::new($culture.Name)
    if (-not $countryNames.ContainsKey($region.TwoLetterISORegionName)) {
        $countryNames[$region.TwoLetterISORegionName] = $region.EnglishName
    }
}

#Loop through all Named Locations and store information in $Total
$total = foreach ($NamedLocation in $NamedLocations) {
    #Determine if a lookup method is being used
    $LookupMethod = if ($NamedLocation.AdditionalProperties.countryLookupMethod -eq 'authenticatorAppGps') { "Authenticator App GPS" } else { "Client IP Address" }
    if ($null -eq $LookupMethod) { $LookupMethod = 'N.A.' }

    #Determine if IP Ranges were used
    $IPRanges = if ($NamedLocation.AdditionalProperties.ipRanges) { "$($NamedLocation.AdditionalProperties.ipRanges.cidrAddress)" } else { "N.A." }

    #Determine in which Conditional Access Policy the Named Location was used, if any
    $UsedExclude = @()
    $UsedInclude = @()
    foreach ($Policy in $Policies) {
        if ($Policy.Conditions.Locations.ExcludeLocations | Select-String $NamedLocation.Id) {
            $UsedExclude += $Policy.DisplayName
        }
        if ($Policy.Conditions.Locations.IncludeLocations | Select-String $NamedLocation.Id) {
            $UsedInclude += $Policy.DisplayName
        }
    }

    #Prepare a list to hold country names
    $Countries = [System.Collections.Generic.List[string]]::new()
    foreach ($CountryCode in $NamedLocation.AdditionalProperties.countriesAndRegions) {
        if ($CountryNames.ContainsKey($CountryCode)) {
            $Countries.Add($CountryNames[$CountryCode])
        }
        else {
            $Countries.Add($CountryCode)
        }
    }

    #Create a list of findings
    [PSCustomObject]@{
        Name                            = $NamedLocation.DisplayName
        Type                            = if ($NamedLocation.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.countryNamedLocation') { "Country" } else { "IP Ranges" }
        Trusted                         = if ($NamedLocation.AdditionalProperties.isTrusted) { "True" } else { "False" }
        LookupMethod                    = $LookupMethod
        'Unknown Countries and Regions' = if (-not ($NamedLocation.AdditionalProperties.includeUnknownCountriesAndRegions)) { "False" } else { "True" }
        "IP Ranges"                     = $IPRanges -replace ' ', ', '
        Countries                       = if ($Countries.Length -gt 0) { $Countries -join ', ' } else { "None" }
        "Excluded in CA Policy"         = if ($UsedExclude.Length -gt 0) { $UsedExclude -join ', ' } else { "N.A." }
        "Included in CA Policy"         = if ($UsedInclude.Length -gt 0) { $UsedInclude -join ', ' } else { "N.A." }
        Created                         = $NamedLocation.CreatedDateTime
        Modified                        = $NamedLocation.ModifiedDateTime
    }
}

#Display results in a Console GridView, output to an XLSX file is $Filename was used
try {
    Import-Module Microsoft.PowerShell.ConsoleGuiTools -ErrorAction Stop
    $Total | Sort-Object Name | Out-ConsoleGridView -Title 'List of all Named Locations, press Esc to exit'
}
catch {
    Write-Warning ("The Microsoft.PowerShell.ConsoleGuiTools was not found, installing now...")
    try {
        Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force:$true -ErrorAction Stop 
        $Total | Sort-Object Name | Out-ConsoleGridView -Title 'List of all Named Locations, press Esc to exit'
    }
    catch {
        Write-Warning ("Could not install the Microsoft.PowerShell.ConsoleGuiTools Module, results will not be outputted on screen")
        Write-Warning ("Alternatively, you can use the -FileName Parameter to export the results to Excel")
    }
}

if ($FileName) {
    if ($FileName.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because the XLSX is corrupted if not
            New-Item -Path $FileName -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $FileName -Force:$true -Confirm:$false | Out-Null
            
            #Install ImportExcel module if needed
            if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                try {
                    Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                    Install-Module ImportExcel -Scope CurrentUser -Force:$true -ErrorAction Stop
                    Import-Module ImportExcel -ErrorAction Stop
                }
                catch {
                    Write-Warning ("Could not install ImportExcel PowerShell Module, exiting...")
                    return
                }
            }
        
            #Export results to path
            $Total | Sort-Object Name | Export-Excel -AutoSize -AutoFilter -Path $FileName
            Write-Host ("`nExported above results to {0}" -f $FileName) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $FileName)
            return
        }
    }
    else {
        Write-Warning ("Specified Filename {0} doesn't end with .xlsx, skipping creation of Excel file" -f $FileName)
        return
    }
}