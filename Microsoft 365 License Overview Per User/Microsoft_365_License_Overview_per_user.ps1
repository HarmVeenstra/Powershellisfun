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
    Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All
}
 
#Create table of users and licenses (https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference)
#Download csv with all SKU's
$ProgressPreference = "SilentlyContinue"
Write-Host ("Downloading license overview from Microsoft") -ForegroundColor Green
$csvlink = ((Invoke-WebRequest -Uri https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference -UseBasicParsing).Links | where-Object Href -Match 'CSV').href
Invoke-WebRequest -Uri $csvlink -OutFile $env:TEMP\licensing.csv
$skucsv = Import-Csv -Path $env:TEMP\licensing.csv
$UsersLicenses = foreach ($user in Get-MgUser -All | Sort-Object UserPrincipalName) {
    if ((Get-MgUserLicenseDetail -UserId $user.UserPrincipalname).count -gt 0) {
        Write-Host ("Processing user {0}" -f $user.UserPrincipalName) -ForegroundColor Green
        foreach ($License in Get-MgUserLicenseDetail -UserId $user.UserPrincipalname) {
            $SKUfriendlyname = $skucsv | Where-Object String_Id -Contains $License.SkuPartNumber | Select-Object -First 1
            $SKUserviceplan = $skucsv | Where-Object GUID -Contains $License.SkuId | Sort-Object Service_Plans_Included_Friendly_Names
            foreach ($serviceplan in $SKUserviceplan) {
                [PSCustomObject]@{
                    User        = "$($User.UserPrincipalName)"
                    LicenseSKU  = "$($SKUfriendlyname.Product_Display_Name)"
                    Serviceplan = "$($serviceplan.Service_Plans_Included_Friendly_Names)"
                }
            }
        }
    }   
}
 
#Output all license information to c:\temp\userslicenses.csv and open it
$UsersLicenses | Sort-Object User, LicenseSKU, Serviceplan | Export-Csv -NoTypeInformation -Delimiter ',' -Encoding UTF8 -Path c:\temp\userslicenses.csv
Invoke-Item c:\temp\userslicenses.csv