function Get-IntuneNonCompliantDevices {
    param(
        [parameter(Mandatory = $false)][string]$outputfile
    )

    #Check if filename is correct
    if ($outputfile) {
        if (-not ($outputfile.EndsWith('.csv') -or $outputfile.EndsWith('.xlsx'))) {
            Write-Warning ("The specified {0} output file should use the .csv or .xlsx extension, exiting..." -f $outputfile)
            return
        }
    
        #Check access to the path, and if the file already exists, append if it does or test the creation of a new one
        if (-not (Test-Path -Path $outputfile)) {
            try {
                New-Item -Path $outputfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
                Remove-Item -Path $outputfile -Force:$true -Confirm:$false | Out-Null
                Write-Host ("Specified {0} filename is correct, and the path is accessible, continuing..." -f $outputfile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("Path to specified {0} filename is not accessible, correct or file is in use, exiting..." -f $outputfile)
                return
            }
        }
        else {
            Write-Warning ("Specified file {0} already exists, overwriting it..." -f $outputfile)
        }
    }

    #Check if necessary modules are installed, install missing modules if not
    if (-not ((Get-Module Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement -ListAvailable).count -eq 2)) {
        Write-Warning ("One or more required modules were not found, installing now...")
        try {
            Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement -Confirm:$false -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing required modules, exiting...")
            return
        }
    }
    else {
        try {
            Import-Module Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement -ErrorAction Stop
        }
        catch {
            Write-Warning { "Error importing required modules, exiting..." }
            return
        }
    }

    #Connect MgGraph
    try {
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
        Write-Host ("Connected to Microsoft Graph, continuing...") -ForegroundColor Green
    } 
    catch {
        Write-Warning ("Error connecting Microsoft Graph, check Permissions/Account. Exiting...")
        return
    }

    #Gon-compliant devices and determine why they are not compliant
    $total = foreach ($policywithnoncompliance in Get-MgBetaDeviceManagementDeviceCompliancePolicySettingStateSummary | Where-Object { $_.NonCompliantDeviceCount -gt 0 -or $_.ConflictDeviceCount -gt 0 -or $_.NotApplicableDeviceCount -gt 0 }) {
        Foreach ($setting in $policywithnoncompliance) {
            $devices = Get-MgBetaDeviceManagementDeviceCompliancePolicySettingStateSummaryDeviceComplianceSettingState -DeviceCompliancePolicySettingStateSummaryId $setting.id | Where-Object State -EQ NonCompliant
            foreach ($device in $devices) {
                [PSCustomObject]@{
                    State            = $device.State
                    GracePeriodUntil = $device.ComplianceGracePeriodExpirationDateTime
                    DeviceName       = $device.DeviceName
                    DeviceModel      = $device.DeviceModel
                    Setting          = $device.Setting
                    UserOrDevice     = If ($device.UserPrincipalName) { $device.UserPrincipalName } else { $device.DeviceName }
                }
            }
        }
    }

    #Return in table if $outputfile was not specified
    if (-not $outputfile) {
        $total | Sort-Object State, DeviceName, Setting, UserOrDevice | Format-Table -AutoSize
    }

    #Export results to either CSV of XLSX, install ImportExcel module if needed
    if ($outputfile.EndsWith('.csv')) {
        try {
            New-Item -Path $outputfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $total | Sort-Object State, DeviceName, Setting, UserOrDevice | Export-Csv -Path $outputfile -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            Write-Host ("`nExported results to {0}" -f $outputfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $outputfile)
            return
        }
    }
    
    if ($outputfile.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because xlsx is corrupted if not
            New-Item -Path $outputfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $outputfile -Force:$true -Confirm:$false | Out-Null
            
            #Install ImportExcel module if needed
            write-host ("`nChecking if ImportExcel PowerShell module is installed...") -ForegroundColor Green
            if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                Install-Module ImportExcel -Scope CurrentUser -Force:$true
                Import-Module ImportExcel
            }
            #Export results to path
            $total | Sort-Object State, DeviceName, Setting, UserOrDevice | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $outputfile
            Write-Host ("`nExported results to {0}" -f $outputfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $outputfile)
            return
        }
    }
}