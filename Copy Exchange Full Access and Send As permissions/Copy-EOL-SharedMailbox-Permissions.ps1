[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)][string]$SourceUser,
    [Parameter(Mandatory = $true)][string[]]$TargetUser,
    [Parameter(Mandatory = $false)][bool]$Automapping = $true
)

#Check for Exchange Online Management Module
if (Get-Module -Name ExchangeOnlineManagement -ListAvailable) {
    Write-Host ("Exchange Online PowerShell module was found, continuing script" ) -ForegroundColor Green
}
else {
    Write-Host ("Exchange Online PowerShell module was not found, installing and continuing script") -ForegroundColor Green
    try {
        Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser -Force:$true -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Warning ("Error installing Exchange Online PowerShell Module, exiting...")
        return
    }
}
#Connect to Exchange Online
Write-Host ("Connecting to Exchange Online, please enter the correct credentials") -ForegroundColor Green
try {
    Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    Write-Host ("Connected to Exchange Online, continuing script...") -ForegroundColor Green
}
catch {
    Write-Warning ("Error connecting to Exchange Online, exiting...") 
    return
}

#Check if Source and TargetUser are valid
try {
    Get-Mailbox -Identity $SourceUser -ErrorAction Stop | Out-Null
    Write-Host ("Source user {0} is valid, contiuing..." -f $SourceUser) -ForegroundColor Green
}
catch {
    Write-Warning ("Source user {0} is not valid, exiing..." -f $SourceUser)
    return
}

foreach ($user in $TargetUser) {
    try {
        Get-Mailbox -Identity $user -ErrorAction Stop | Out-Null
        Write-Host ("Source user {0} is valid, continuing..." -f $user) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Source user {0} is not valid, exiing..." -f $user)
        return
    }
}

#Retrieve all Shared mailboxes that the source user has permissions on
Write-Host ("Retrieving all Shared Mailboxes that {0} has Full Access and Send As permissions on and adding them to the TargetUser(s)" -f $SourceUser) -ForegroundColor Green
$sharedmailboxes = Get-Mailbox | Where-Object RecipientTypeDetails -eq SharedMailbox | Sort-Object Name
foreach ($mailbox in $sharedmailboxes) {
    Write-Host ("- Checking Shared Mailbox {0} for permissions" -f $mailbox.Name)
    foreach ($user in $TargetUser) {
        if ((Get-MailboxPermission $mailbox).user -contains $SourceUser) {
            if ((Get-MailboxPermission $mailbox).user -contains $user) {
                Write-Warning ("Specified user {0} already has access, skipping..." -f $user)
            }
            else {
                try {
                    Add-MailboxPermission -Identity $mailbox -User $user -AccessRights FullAccess -InheritanceType All -AutoMapping $Automapping -Confirm:$false -ErrorAction Stop | Out-Null
                    Add-RecipientPermission -Identity $mailbox.PrimarySmtpAddress -Trustee $user -AccessRights SendAs -Confirm:$false -ErrorAction Stop | Out-Null
                    Write-Host ("- Added Full Access and Send As permissions on {0} for {1}" -f $mailbox, $user) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error setting Full Access and Send As permissions on {0}" -f $mailbox.Name)
                }
            }
        }
    }
}