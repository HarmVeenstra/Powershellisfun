#Use -Filter parameter to only search for specific licenses. 
#For example .\Microsoft_365_License_Overview_per_user.ps1' -FilterLicenseSKU 'Windows 10 Enterprise E3' or
#For example .\Microsoft_365_License_Overview_per_user.ps1' -FilterServicePlan 'Universal Print'
#If -Filter is not used, #all licenses will be reported
[CmdletBinding(DefaultParameterSetName = 'All')]
param (
    [parameter(parameterSetName = "LicenseSKU")][string]$FilterLicenseSKU,
    [parameter(parameterSetName = "ServicePlan")][string]$FilterServicePlan,
    [parameter(Mandatory = $false)][string]$FilterUser
)

#Connect to MSGraph if not connected
Write-Host ("Checking MSGraph module") -ForegroundColor Green
try {
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Users -ErrorAction Stop
    Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All -ErrorAction Stop | Out-Null
}
catch {
    if (-not (get-module -ListAvailable | Where-Object Name -Match 'Microsoft.Graph.Identity.DirectoryManagement')) {
        Write-Host Installing Microsoft.Graph.Identity.DirectoryManagement module.. -ForegroundColor Green
        Install-Module Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Users
        Install-Module Microsoft.Graph.Users
        Import-Module Microsoft.Graph.Identity.DirectoryManagement
        Import-Module Microsoft.Graph.Users
    }
    Connect-Graph -Scopes User.Read.All, Organization.Read.All
}
 
#Create table of users and licenses (https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference)
#Download csv with all SKU's
$ProgressPreference = "SilentlyContinue"
Write-Host ("Downloading license overview from Microsoft") -ForegroundColor Green
$csvlink = ((Invoke-WebRequest -Uri https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference -UseBasicParsing).Links | where-Object Href -Match 'CSV').href
Invoke-WebRequest -Uri $csvlink -OutFile $env:TEMP\licensing.csv -UseBasicParsing
$skucsv = Import-Csv -Path $env:TEMP\licensing.csv -Encoding Default
if ($null -eq $FilterUser) {
    $users = Get-MgUser -All | Sort-Object UserPrincipalName
}
else {
    $users = Get-MgUser -All | Where-Object UserPrincipalName -Match $FilterUser | Sort-Object UserPrincipalName
}
$UsersLicenses = foreach ($user in $users) {
    if ((Get-MgUserLicenseDetail -UserId $user.UserPrincipalname).count -gt 0) {
        Write-Host ("Processing user {0}" -f $user.UserPrincipalName) -ForegroundColor Green
        $Licenses = Get-MgUserLicenseDetail -UserId $user.UserPrincipalname
        foreach ($License in $Licenses) {
            $SKUfriendlyname = $skucsv | Where-Object String_Id -Contains $License.SkuPartNumber | Select-Object -First 1
            $SKUserviceplan = $skucsv | Where-Object GUID -Contains $License.SkuId | Sort-Object Service_Plans_Included_Friendly_Names
            foreach ($serviceplan in $SKUserviceplan) {
                if ($FilterLicenseSKU) {
                    if ("$($SKUfriendlyname.Product_Display_Name)" -match $FilterLicenseSKU) {
                        [PSCustomObject]@{
                            User               = "$($User.UserPrincipalName)"
                            LicenseSKU         = "$($SKUfriendlyname.Product_Display_Name)"
                            Serviceplan        = "$($serviceplan.Service_Plans_Included_Friendly_Names)"
                            AppliesTo          = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).AppliesTo | Select-Object -First 1
                            ProvisioningStatus = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).ProvisioningStatus | Select-Object -First 1
                        }
                    }
                }
                elseif ($FilterServicePlan) {
                    if ("$($serviceplan.Service_Plans_Included_Friendly_Names)" -match $FilterServicePlan) {
                        [PSCustomObject]@{
                            User               = "$($User.UserPrincipalName)"
                            LicenseSKU         = "$($SKUfriendlyname.Product_Display_Name)"
                            Serviceplan        = "$($serviceplan.Service_Plans_Included_Friendly_Names)"
                            AppliesTo          = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).AppliesTo | Select-Object -First 1
                            ProvisioningStatus = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).ProvisioningStatus | Select-Object -First 1
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        User               = "$($User.UserPrincipalName)"
                        LicenseSKU         = "$($SKUfriendlyname.Product_Display_Name)"
                        Serviceplan        = "$($serviceplan.Service_Plans_Included_Friendly_Names)"
                        AppliesTo          = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).AppliesTo | Select-Object -First 1
                        ProvisioningStatus = ($licenses.ServicePlans | Where-Object ServicePlanId -eq $serviceplan.Service_Plan_Id).ProvisioningStatus | Select-Object -First 1
                    }
                }
            }
        }
    }   
}
 
#Output all license information to c:\temp\userslicenses.csv and open it
if ($UsersLicenses.count -gt 0) {
    $UsersLicenses | Sort-Object User, LicenseSKU, Serviceplan | Export-Csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path c:\temp\userslicenses.csv
    Invoke-Item c:\temp\userslicenses.csv
}
else {
    Write-Warning ("No licenses found, check permissions and/or -Filter value")
}