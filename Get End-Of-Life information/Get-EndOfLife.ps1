param (
    [Parameter(Mandatory = $false, ParameterSetName = ('AllProducts'))][switch]$AllProducts,    
    [Parameter(Mandatory = $true, ParameterSetName = ('Product'))][ValidateNotNullOrEmpty()][string[]]$Product,
    [Parameter(Mandatory = $true, ParameterSetName = ('File'))][ValidateNotNullOrEmpty()][string]$File
)

#Check if Out-ConsoleGridView is installed if running from PowerShell v7
if ($host.Version.Major -ge 7) {
    try {
        Import-Module Microsoft.PowerShell.ConsoleGuiTools -ErrorAction Stop
    }
    catch {
        Write-Warning ("Microsoft.PowerShell.ConsoleGuiTools module was not installed, installing now...")
        try {
            Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing Microsoft.PowerShell.ConsoleGuiTools module, exiting...")
            return
        }
    }
}

#Retrieve all product data based, and output to Out-ConsoleGridView or Out-GridView for selection
if ($AllProducts) {
    try {
        $results = Invoke-RestMethod -Uri "https://endoflife.date/api/all.json" -Method Get -ContentType 'application/json' -ErrorAction Stop
    }
    catch {
        Write-Warning ("Could not retrieve product details, check internet access. Exiting...")
        return
    }
    if ($results.count -ge 1) {
        if ($host.Version.Major -ge 7) {
            $Product = $results | Out-ConsoleGridView -Title 'Select one or more products for determing End Of Life' -OutputMode Multiple -ErrorAction Stop
        }
        else {
            $Product = $results | Out-GridView -Title 'Select one or more products for determing End Of Life' -PassThru -ErrorAction Stop
        }
    }
    else {
        Write-Warning ("No product results found")
        return
    }
}

#Retrieve details for all selected products
if ($Product) {
    $total = foreach ($item in $Product) {
        try {
            $results = Invoke-RestMethod -Uri "https://endoflife.date/api/$($item).json" -Method Get -ContentType 'application/json' -ErrorAction Stop
            foreach ($result in $results) {
                [PSCustomObject]@{
                    Product         = $item
                    Cycle           = $result.cycle
                    ReleaseDate     = $result.releaseDate
                    EOL             = $result.eol
                    Latest          = $result.Latest
                    LTS             = $result.LTS
                    Support         = $result.support
                    ExtendedSupport = $result.extendedSupport
                    Link            = $result.link
                }
            }
        }
        catch {
            Write-Warning ("Could not retrieve details for product {0}, check spelling / internet access. Exiting..." -f $item)
            return
        }

    }
    if ($total.count -ge 1) {
        if ($host.Version.Major -ge 7) {
            $total | Out-ConsoleGridView -Title ("Details for End Of Life of product(s) {0}" -f $Product)
            return
        }
        else {
            $total | Out-GridView -Title ("Details for End Of Life of product(s) {0}" -f $Product)
            return
        }
    }
    else {
        Write-Warning ("No results to display for product(s) {0}" -f $Product)
    }
}

#Output all data to specified file
if ($File) {
    If (-not ($file.EndsWith('.xlsx'))) {
        Write-Warning ("Filename should end with .xlsx, exiting...")
        return
    }
    try {    
        #Install ImportExcel module if needed
        if (-not (Get-Module -Name importexcel -ListAvailable)) {
            Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
            Install-Module ImportExcel -Scope CurrentUser -Force:$true -ErrorAction Stop
            Import-Module ImportExcel -ErrorAction Stop
        }
    }
    catch {
        Write-Warning ("`nCould not import Excel PowerShell module, exiting...")
        return
    }
}

#Collect all end of life information and add to $total
try {
    $results = Invoke-RestMethod -Uri "https://endoflife.date/api/all.json" -Method Get -ContentType 'application/json' -ErrorAction Stop
}
catch {
    Write-Warning ("Could not retrieve product details, check internet access. Exiting...")
    return
}
$total = foreach ($product in $results) {
    foreach ($item in $Product) {
        try {
            $results = Invoke-RestMethod -Uri "https://endoflife.date/api/$($item).json" -Method Get -ContentType 'application/json' -ErrorAction Stop
            foreach ($result in $results) {
                [PSCustomObject]@{
                    Product         = $item
                    Cycle           = $result.cycle
                    ReleaseDate     = $result.releaseDate
                    EOL             = $result.eol
                    Latest          = $result.Latest
                    LTS             = $result.LTS
                    Support         = $result.support
                    ExtendedSupport = $result.extendedSupport
                    Link            = $result.link
                }
            }
        }
        catch {
            Write-Warning ("Could not retrieve details for product {0}, check spelling / internet access. Exiting..." -f $item)
            return
        }
    }
}

#Export all data to specified xlsx file
try {
    #Test path and remove empty file afterwards because xlsx is corrupted if not
    New-Item -Path $File -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
    Remove-Item -Path $File -Force:$true -Confirm:$false | Out-Null
    $total | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $File
    Write-Host ("`nExported results to {0}" -f $File) -ForegroundColor Green
    return
}
catch {
    Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $File)
    return
}