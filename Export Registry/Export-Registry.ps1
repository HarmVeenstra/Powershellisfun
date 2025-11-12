function Export-Registry {
    param (
        [parameter(Mandatory = $true, HelpMessage = "Enter the path to start from, for example HKLM:SOFTWARE\Microsoft\Policies")][string]$Path,
        [parameter(Mandatory = $true)][string]$Outfile
    )
    
    #Test if $Path is accessible
    if (Test-Path $path -ErrorAction stop) {
        Write-Host ("Path {0} is valid, continuing..." -f $Path) -ForegroundColor Green
    }
    else {
        Write-Warning ("Could not access path {0}, check syntax and permissions. Exiting..." -f $path)
        return
    }

    #Check file extension, if it's not .csv or .xlsx exit
    if (-not ($Outfile.EndsWith('.csv') -or $Outfile.EndsWith('.xlsx'))) {
        Write-Warning ("The specified {0} output file should use the .csv or .xlsx extension, exiting..." -f $Outfile)
        return
    }


    #Set $keys variable
    Write-Host ("Retrieving keys from {0}" -f $Path) -ForegroundColor Green
    $keys = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue

    $total = foreach ($key in $keys) {
        foreach ($property in $key) {
            Write-Host ("Processing {0}" -f $property) -ForegroundColor Green
            foreach ($name in $key.Property) {
                try {   
                    [PSCustomObject]@{
                        Name     = $property.Name
                        Property = "$($name)"
                        Value    = Get-ItemPropertyValue -Path $key.PSPath -Name $name
                        Type     = $key.GetValueKind($name)
                    }
                }
                catch {
                    Write-Warning ("Error processing {0} in {1}" -f $property, $key.name)
                }
            }
        }
    }
    
    #Export results to either CSV of XLSX, install ImportExcel module if needed
    if ($Outfile.EndsWith('.csv')) {
        try {
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $total | Sort-Object Name, Property | Export-Csv -Path $Outfile -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }
    
    if ($Outfile.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because xlsx is corrupted if not
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $Outfile -Force:$true -Confirm:$false | Out-Null
            
            #Install ImportExcel module if needed
            write-host ("Checking if ImportExcel PowerShell module is installed...") -ForegroundColor Green
            if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                Install-Module ImportExcel -Scope CurrentUser -Force:$true
                Import-Module ImportExcel
            }

            #Export results to path
            $total | Sort-Object name, Property | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $Outfile
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }
}