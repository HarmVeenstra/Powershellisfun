#Used https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-userdevicesettings for the method of setting a mobile number for MFA 
#Check if necessary modules are installed, install missing modules if not
if (-not ((Get-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Signins, Microsoft.Graph.Users -ListAvailable).count -eq 3)) {
    Write-Warning ("One or more required modules were not found, installing now...")
    try {
        Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Signins, Microsoft.Graph.Users -Confirm:$false -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
    }
    catch {
        Write-Warning ("Error installing required modules, exiting...")
        return
    }
}
else {
    try {
        Import-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.Signins, Microsoft.Graph.Users -ErrorAction Stop
    }
    catch {
        Write-Warning { "Error importing required modules, exiting..." }
        return
    }
}

# Connect to tenant, make sure your account has enough permissons in Microsoft Graph
# Use https://developer.microsoft.com/en-us/graph/graph-explorer to grant permissions 
# in https://graph.microsoft.com/v1.0/users/objectid/authentication/microsoftAuthenticatorMethods
# and https://graph.microsoft.com/v1.0/users/
Connect-MgGraph -Scopes UserAuthenticationMethod.ReadWrite.All, User.Read.All -NoWelcome

# Loop through the users (No guest accounts) who have registered MFA without a recovery phonenumber
# and add it if a mobile phone number is present in Azure AD for the user.
# The ID 28c10230-6103-485e-b985-444c60001490 is filtered because it's the standard Password.
foreach ($user in Get-MgBetaUser -All | Where-Object UserPrincipalName -NotMatch '#EXT#') {
    if ($null -ne (Get-MgBetaUserAuthenticationMethod -UserId $user.UserPrincipalName | Where-Object ID -ne 28c10230-6103-485e-b985-444c60001490) `
            -and $null -eq (Get-MgBetaUserAuthenticationPhoneMethod -UserId $user.UserPrincipalName)) {
        if ($null -ne $user.MobilePhone) {
            Write-Host "$($user.UserPrincipalName) has registered MFA but has no mobile phone Authentication Method, adding $($user.MobilePhone) now" -ForegroundColor Green
            New-MgBetaUserAuthenticationPhoneMethod -UserId $user.UserPrincipalName -phoneType "Mobile" -phoneNumber $user.MobilePhone | Out-Null           
        }
        else {
            Write-Host "$($user.UserPrincipalName) has MFA configured without mobile phone number Authentication Method but has no known mobile phone number to add, skipping..." -ForegroundColor Red
        }
    }
}