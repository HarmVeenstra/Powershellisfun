#Used https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-userdevicesettings for the method of setting a mobile number for MFA 
# Install the needed Microsoft.Graph modules
Install-module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Signins, Microsoft.Graph.Users -ErrorAction SilentlyContinue

# Connect to tenant, make sure your account has enough permissons in Microsoft Graph
# Use https://developer.microsoft.com/en-us/graph/graph-explorer to grant permissions 
# in https://graph.microsoft.com/v1.0/users/objectid/authentication/microsoftAuthenticatorMethods
# and https://graph.microsoft.com/v1.0/users/
Connect-MgGraph -Scopes UserAuthenticationMethod.ReadWrite.All, User.Read.All
Select-MgProfile -Name beta

# Loop through the users (No guest accounts) who have registered MFA without a recovery phonenumber
# and add it if a mobile phone number is present in Azure AD for the user.
# The ID 28c10230-6103-485e-b985-444c60001490 is filtered because it's the standard Password.
foreach ($user in Get-MgUser -All | Where-Object UserPrincipalName -NotMatch '#EXT#') {
    if ($null -ne (Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName | Where-Object ID -ne 28c10230-6103-485e-b985-444c60001490) `
            -and $null -eq (Get-MgUserAuthenticationPhoneMethod -UserId $user.UserPrincipalName)) {
        if ($null -ne $user.MobilePhone) {
            Write-Host "$($user.UserPrincipalName) has registered MFA but has no mobile phone Authentication Method, adding $($user.MobilePhone) now" -ForegroundColor Green
            New-MgUserAuthenticationPhoneMethod -UserId $user.UserPrincipalName -phoneType "Mobile" -phoneNumber $user.MobilePhone | Out-Null           
        }
        else {
            write-host "$($user.UserPrincipalName) has MFA configured without mobile phone number Authentication Method but has no known mobile phone number to add, skipping..." -ForegroundColor Red
        }
    }
}