<#
.SYNOPSIS
This script will download the license overview from Microsoft and then create a table of users and licenses.

.DESCRIPTION
Use -Filter* parameter to only search for specific licenses.
If -Filter* is not used, all licenses will be reported.

.PARAMETER FilterLicenseSKU
The SKU of the license to search for. If not used, all licenses will be reported.

.PARAMETER FilterServicePlan
The name of the service plan to search for. If not used, all licenses will be reported.

.PARAMETER FilterUser
The username (UPN/userPrincipalName) of the user to search for. If not used, all users will be reported.

.EXAMPLE
.\Microsoft_365_License_Overview_per_user.ps1

.EXAMPLE
.\Microsoft_365_License_Overview_per_user.ps1' -FilterLicenseSKU 'Windows 10 Enterprise E3'

.EXAMPLE
.\Microsoft_365_License_Overview_per_user.ps1' -FilterServicePlan 'Universal Print'

.EXAMPLE
.\Microsoft_365_License_Overview_per_user.ps1' -FilterUser 'joe.smith'
#>

[CmdletBinding(DefaultParameterSetName = 'None')]
param (
    [Parameter(ParameterSetName = 'LicenseSKU')][string]$FilterLicenseSKU,
    [Parameter(ParameterSetName = 'ServicePlan')][string]$FilterServicePlan,
    [Parameter()][string]$FilterUser
)

try {
    # Load required Graph modules (install if missing)
    $required = @('Microsoft.Graph.Identity.DirectoryManagement', 'Microsoft.Graph.Users')
    foreach ($mod in $required) {
        if (-not (Get-Module -ListAvailable -Name $mod)) {
            Write-Verbose "Installing $mod module..." -Verbose
            Install-Module $mod -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module $mod -ErrorAction Stop
    }

    # Connect to Graph (reuse existing session if possible)
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'User.Read.All', 'Organization.Read.All' -NoWelcome -ContextScope Process -ErrorAction Stop
    }

    # Download and cache the SKU reference CSV as a hashtable
    Write-Verbose 'Downloading SKU reference CSV…'
    [string]$csvLink = (Invoke-WebRequest -DisableKeepAlive -Uri 'https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference' -UseBasicParsing).Links.href -match '\.csv$'
    $tempCsv = [IO.Path]::ChangeExtension((New-TemporaryFile).FullName, '.csv')
    Invoke-WebRequest -Uri $csvLink -OutFile $tempCsv -UseBasicParsing

    # Build two lookup tables: SKU‑>DisplayName and ServicePlan‑>SKU object
    $skuLookup = @{}
    $planLookup = @{}
    Import-Csv -Path $tempCsv -Encoding Default | ForEach-Object {
        $skuLookup[$_.String_Id] = $_.Product_Display_Name
        $planLookup[$_.GUID] = $_   # keep the whole row for later Service_Plans
    }
    Remove-Item $tempCsv

    # Stream users from Graph
    Write-Verbose 'Fetching users from Graph…'
    $userQuery = @{
        All      = $true
        Property = @('id', 'userPrincipalName')
    }
    if ($FilterUser) {
        # Graph supports simple OData filter on UPN; adjust as needed
        $userQuery.Filter = "startswith(userPrincipalName,'$FilterUser')"
    }
    $users = Get-MgUser @userQuery

    $outFile = [IO.Path]::ChangeExtension((New-TemporaryFile).FullName, '.csv')

    # Write header once to the outFile
    'User;LicenseSKU;Serviceplan;AppliesTo;ProvisioningStatus' | Out-File -FilePath $outFile -Encoding utf8

    # Process each user
    foreach ($user in $users) {
        Write-Verbose "Processing $($user.UserPrincipalName)..."
        $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id
        if (-not $licenseDetails) { continue }

        foreach ($detail in $licenseDetails) {
            Clear-Variable skuName -ErrorAction SilentlyContinue
            $skuName = $skuLookup[$detail.SkuPartNumber]
            if (-not $skuName) { $skuName = $detail.SkuPartNumber }

            # Pre‑filter on SKU name if requested
            if ($FilterLicenseSKU -and $skuName -notmatch $FilterLicenseSKU) { continue }

            foreach ($plan in $detail.ServicePlans) {
                $planInfo = $planLookup[$plan.ServicePlanId]

                # Pre‑filter on ServicePlan name if requested
                if ($FilterServicePlan -and $planInfo.Service_Plans_Included_Friendly_Names -notmatch $FilterServicePlan) {
                    continue
                }

                $line = '{0};{1};{2};{3};{4}' -f `
                    $user.UserPrincipalName,
                $skuName,
                $planInfo.Service_Plans_Included_Friendly_Names,
                $plan.AppliesTo,
                $plan.ProvisioningStatus
                $line | Out-File -FilePath $outFile -Append -Encoding utf8
            }
        }
    }

    $outputLength = (Get-Content $outFile).Count
    if ($outputLength -eq 1) {
        Remove-Item $outFile
        Write-Output "No matching licenses found."
        exit 0
    }
    elseif ($outputLength -gt 1) {
        Write-Output "$($outputLength - 1) matching licenses found."
        # Open the CSV (optional – only if running interactively)
        if ($Host.UI.SupportsVirtualTerminal) {
            Invoke-Item $outFile
        }
        else {
            Write-Output "CSV written to $outFile"
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    # Disconnect from Graph
    Disconnect-MgGraph | Out-Null
}
