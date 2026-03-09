<#
    .SYNOPSIS
    Exports a per‑user Microsoft 365 license and service‑plan overview using Microsoft Graph.

    .DESCRIPTION
    Lists all licenses and service plans assigned to each user.
    Supports filtering by:
    - License SKU (friendly name)
    - Service plan name
    - User UPN
    If no -Filter* is used, all licenses will be reported.

    .PARAMETER FilterLicenseSKU
    The SKU of the license to search for (friendly name). If not used, all licenses will be reported.

    .PARAMETER FilterServicePlan
    The name of the service plan to search for (matches friendly OR internal name). If not used, all licenses will be reported.

    .PARAMETER FilterUser
    The username (UPN/userPrincipalName) of the user to search for. If not used, all users will be reported.

    .EXAMPLE
    .\Microsoft_365_License_Overview_per_user.ps1

    .EXAMPLE
    .\Microsoft_365_License_Overview_per_user.ps1 -FilterLicenseSKU 'Windows 10 Enterprise E3'

    .EXAMPLE
    .\Microsoft_365_License_Overview_per_user.ps1 -FilterServicePlan 'Universal Print'

    .EXAMPLE
    .\Microsoft_365_License_Overview_per_user.ps1 -FilterUser 'joe.smith'
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
            Write-Verbose "Installing $mod module..."
            Install-Module $mod -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module $mod -ErrorAction Stop
    }

    # Connect to Graph (reuse existing session if possible)
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes 'Directory.Read.All', 'User.Read.All', 'Organization.Read.All' -NoWelcome -ContextScope Process -ErrorAction Stop
    }

    # Download and cache the SKU reference CSV from Microsoft Docs, which contains mappings of SKUs and service plans to friendly names. This is needed because Graph returns only internal IDs for SKUs and service plans.
    Write-Verbose 'Downloading SKU reference CSV...'
    [string]$csvLink = (Invoke-WebRequest -DisableKeepAlive -Uri 'https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference' -UseBasicParsing).Links.href -match '\.csv$'
    $tempCsv = [IO.Path]::ChangeExtension((New-TemporaryFile).FullName, '.csv')
    Invoke-WebRequest -Uri $csvLink -OutFile $tempCsv -UseBasicParsing

    # Build lookup tables:
    #   SKU: String_Id (SkuPartNumber) -> Product_Display_Name (friendly SKU name)
    #   Service plan: Service_Plan_Id (GUID) -> full CSV row (for friendly + internal names)
    $skuLookup = @{}
    $planLookup = @{}

    Import-Csv -Path $tempCsv -Encoding Default | ForEach-Object {
        # SKU lookup (one entry per String_Id, last wins if duplicates)
        if ($_.String_Id -and $_.Product_Display_Name) {
            $skuLookup[$_.String_Id] = $_.Product_Display_Name
        }

        # Service plan lookup by Service_Plan_Id (this matches Graph ServicePlanId)
        if ($_.Service_Plan_Id) {
            $planLookup[$_.Service_Plan_Id] = $_
        }
    }

    Remove-Item $tempCsv -ErrorAction SilentlyContinue

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

    # Prepare output file
    $outFile = [IO.Path]::ChangeExtension((New-TemporaryFile).FullName, '.csv')
    # Write header once to the outFile
    'User;LicenseSKU;ServiceplanFriendly;ServiceplanInternal;AppliesTo;ProvisioningStatus' | Out-File -FilePath $outFile -Encoding utf8

    # Process each user
    foreach ($user in $users) {
        Write-Verbose "Processing $($user.UserPrincipalName)..."
        $licenseDetails = Get-MgUserLicenseDetail -UserId $user.Id
        if (-not $licenseDetails) { continue }

        foreach ($detail in $licenseDetails) {
            # Resolve friendly SKU name from CSV, fall back to SkuPartNumber
            Clear-Variable skuName -ErrorAction SilentlyContinue
            $skuName = $skuLookup[$detail.SkuPartNumber]
            if (-not $skuName) { $skuName = $detail.SkuPartNumber }

            # Filter on SKU name if requested (friendly name)
            if ($FilterLicenseSKU -and $skuName -notmatch $FilterLicenseSKU) { continue }

            foreach ($plan in $detail.ServicePlans) {
                # Lookup service plan info 
                $planInfo = $planLookup[$plan.ServicePlanId]

                # Extract friendly + internal names
                $friendlyPlanName = $null
                $internalPlanName = $null

                if ($planInfo) {
                    $friendlyPlanName = $planInfo.Service_Plans_Included_Friendly_Names
                    $internalPlanName = $planInfo.Service_Plan_Name
                }

                # Fallbacks if CSV is missing a row for this plan
                if (-not $friendlyPlanName) { $friendlyPlanName = $plan.ServicePlanName }
                if (-not $internalPlanName) { $internalPlanName = $plan.ServicePlanName }

                # Filter on ServicePlan name if requested
                if ($FilterServicePlan) {
                    if ($friendlyPlanName -notmatch $FilterServicePlan -and
                        $internalPlanName -notmatch $FilterServicePlan) {
                        continue
                    }
                }

                # Write output row
                $line = '{0};{1};{2};{3};{4};{5}' -f `
                    $user.UserPrincipalName,
                $skuName,
                $friendlyPlanName,
                $internalPlanName,
                $plan.AppliesTo,
                $plan.ProvisioningStatus

                $line | Out-File -FilePath $outFile -Append -Encoding utf8
            }
        }
    }

    # Summarize output
    $outputLength = (Get-Content $outFile).Count
    if ($outputLength -eq 1) {
        Write-Output "No matching licenses found."
        Remove-Item $outFile -ErrorAction SilentlyContinue | Out-Null
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
