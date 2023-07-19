param(
    [parameter(Mandatory = $true)][string]$Output
)
#Exit if incorrect extension was used
if (($Output.EndsWith('.csv') -ne $true) -and ($Output.EndsWith('.xlsx') -ne $true)) {
    Write-Warning ("Specified file {0} does not have the .csv or .xlsx extension. Exiting..." -f $Output)
    return
}

#Create list of available modules, loop through them and get the cmdlets and functions
$modules = Get-Module -ListAvailable | Select-Object -Unique | Sort-Object Name
if ($modules.count -gt 0) {
    $modulecounter = 1
    $total = foreach ($module in $modules) {
        Write-Host ("[{0}/{1}] Processing module {2}" -f $modulecounter, $modules.count, $module.name) -ForegroundColor Green
        $cmdlets = Get-Command -module $module.Name | Sort-Object Name
        $cmdletcounter = 1
        foreach ($cmdlet in $cmdlets) {
            Write-Host ("`t [{0}/{1}] Processing cmdlet/function {2}" -f $cmdletcounter, $cmdlets.count, $cmdlet.name)
            #Retrieve Synopsis (Remove Read-Only, Read-Wite, Nullable and Supports $expand if found) and URL for the cmdlet/function
            $help = Get-Help $cmdlet
            $synopsis = $help.Synopsis.replace('Read-only.', '').replace('Read-Write.', '').replace('Nullable.', '').replace('Supports $expand.', '').replace('Not nullable.', '').replace('\r', " ")
            $synopsis = $synopsis -replace '\n', ' ' -creplace '(?m)^\s*\r?\n', ''
            #Set variable for non matching cmdlet name and synopsis content
            $url = $help.relatedLinks.navigationLink.uri
            #Set Synopsis or URL to "Not Available" when no data is found
            if ($null -eq $synopsis -or $synopsis.Length -le 2 -or $synopsis -match $cmdlet.Name) { $synopsis = "Not available" }
            if ($null -eq $url -or -not $url.Contains('https')) { $url = "Not available" }
            [PSCustomObject]@{
                Source   = $cmdlet.Source
                Version  = $cmdlet.Version
                Cmdlet   = $cmdlet.Name
                Synopsis = $synopsis
                URL      = $url
            }
            $cmdletcounter++
        }
        $modulecounter++
    }
}
else {
    Write-Warning ("No modules found to process? Check permissions. Exiting...")
    return
}

if ($total.count -gt 0) {

    #Output to .csv or .xlsx file
    if ($Output.EndsWith('.csv')) {
        try {
            New-Item -Path $Output -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $total | Sort-Object Source, Version, Cmdlet | Export-Csv -Path $Output -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("`nExported results to {0}" -f $Output) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Output)
            return
        }
    }

    if ($Output.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because xlsx is corrupted if not
            New-Item -Path $Output -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $Output -Force:$true -Confirm:$false | Out-Null
    
            #Install ImportExcel module if needed
            if (-not (Get-Module -Name importexcel -ListAvailable)) {
                Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                Install-Module ImportExcel -Scope CurrentUser -Force:$true
                Import-Module ImportExcel
            }
            Import-Module ImportExcel
            $total | Sort-Object Source, Version, Cmdlet | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $Output
            Write-Host ("`nExported results to {0}" -f $Output) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Output)
            return
        }
    }
}