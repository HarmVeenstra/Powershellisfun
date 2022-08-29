#Connect to MgGraph using ClientID, TenantID and Certificate Thumbprint
#(Retrieve these ID's from the Azure App Registration)
#Install the Graph.Authentication module if not installed
try {
    Connect-MgGraph -ClientId d52e60f2-xxxx-4cd3-xxxx-27b7da3xxxx -TenantId 9f7xxxa0-xxxx-454c-8500-04df1f0xxxx -CertificateThumbprint BFFE739D4B8C272DF8BF0FF9Fxxxxxxxxx -ContextScope CurrentUser -Environment Global | Out-Null
}
catch {
    install-module Microsoft.Graph.Authentication
    Connect-MgGraph -ClientId d52e60f2-xxxx-4cd3-xxxx-27b7da3xxxx -TenantId 9f7xxxa0-xxxx-454c-8500-04df1f0xxxx -CertificateThumbprint BFFE739D4B8C272DF8BF0FF9Fxxxxxxxxx -ContextScope CurrentUser -Environment Global | Out-Null
}
 
#Install the ServiceAnnouncement module if not installed
try {
    Import-Module Microsoft.Graph.Devices.ServiceAnnouncement -ErrorAction Stop    
}
catch {
    install-module Microsoft.Graph.Devices.ServiceAnnouncement
}
 
#Display non-resolved Issues sorted on StartDateTime, display error when unable to retrieve
try {
    $issues = Get-MgServiceAnnouncementIssue | Where-Object IsResolved -ne True | Select-Object StartDateTime, Id, ImpactDescription, Feature, Classification, Status | Sort-Object StartDateTime
}
catch {
    write-host "Error retrieving Announcements, try again later..." -ForegroundColor Red
}

#Display the issues if found, display no issues found it not
if ($issues.count -gt 0) {
    $issues
}
else {
    Write-Host "No 365 Service Health Issues found!" -Foregroundcolor Green
}