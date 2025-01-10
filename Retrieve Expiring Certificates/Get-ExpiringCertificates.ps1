param (
    [Parameter(Mandatory = $false)][int]$Days = 14
)

#Create a list of certificates for both Computer and User Account expiring in $days
$ExperingCerts = foreach ($Certificate in (Get-ChildItem Cert:).Location ) {
    foreach ($ExpiringCert in Get-ChildItem -Path "Cert:\$($Certificate)\My" | Where-Object NotAfter -LT (Get-Date).AddDays("$($Days)")) {
        [PSCustomObject]@{
            Store            = $Certificate
            DaysUntilExpired = ($ExpiringCert.NotAfter - (Get-Date)).Days
            ExpirationDate   = $ExpiringCert.NotAfter
            Friendlyname     = if ($Expiringcert.FriendlyName) { $ExperingCert.FriendlyName } else { "<None" }
            Issuer           = $ExpiringCert.Issuer
            Subject          = $Expiringcert.Subject.Split('=,')[1]
            ThumbPrint       = $ExpiringCert.Thumbprint
        }
    }
}

#Output to screen if found
if ($ExperingCerts) {
    Write-Warning ("Expired/Expering Certificates found!")
    $ExperingCerts | Sort-Object ExpirationDate | Format-Table -AutoSize
}
else {
    Write-Host ("No expired/expiring Certificates found") -ForegroundColor Green
}