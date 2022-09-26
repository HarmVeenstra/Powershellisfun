#Connect to MSOL if not connected
Write-Host ("Checking MSOnline module") -ForegroundColor Green
try {
    Get-MsolDomain -ErrorAction Stop | Out-Null
}
catch {
    if (-not (get-module -ListAvailable | Where-Object Name -Match 'MSOnline')) {
        Write-Host Installing MSOnline module.. -ForegroundColor Green
        Install-Module MSOnline
    }
    Connect-MsolService
}
 
#Create table of users and licenses (https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference)
#Download csv with all SKU's
$ProgressPreference = "SilentlyContinue"
Write-Host ("Downloading license overview from Microsoft") -ForegroundColor Green
$csvlink = ((Invoke-WebRequest -Uri https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference).Links | where-Object Href -Match 'CSV').href
Invoke-WebRequest -Uri $csvlink -OutFile $env:TEMP\licensing.csv
$skucsv = Import-Csv -Path $env:TEMP\licensing.csv
$UsersLicenses = @()
foreach ($user in Get-MsolUser -All | Sort-Object UserPrincipalName) {
    if ($user.isLicensed -eq $True) {
        foreach ($License in $User.licenses) {
            $SKUfriendlyname = $skucsv | Where-Object String_Id -Contains $License.AccountSkuId.Split(':')[1] | Select-Object Product_Display_Name -First 1
            $SKUserviceplan = $skucsv | Where-Object String_Id -Contains $License.AccountSkuId.Split(':')[1] | Sort-Object Service_Plans_Included_Friendly_Names
            foreach ($serviceplan in $SKUserviceplan) {
                $Licenses = [PSCustomObject]@{
                    User        = $User.UserPrincipalName
                    LicenseSKU  = $SKUfriendlyname.Product_Display_Name
                    Serviceplan = $serviceplan.Service_Plans_Included_Friendly_Names
                }
                $UsersLicenses += $Licenses
            }
        }
    }   
}
 
#Output all license information to c:\temp\userslicenses.csv and open it
$UsersLicenses | Sort-Object User, LicenseSKU, Serviceplan | Export-Csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path c:\temp\userslicenses.csv
Invoke-Item c:\temp\userslicenses.csv