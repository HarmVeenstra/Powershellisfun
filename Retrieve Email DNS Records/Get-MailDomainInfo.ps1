function Get-MailDomainInfo {
    param(
        [parameter(Mandatory = $true)][string]$DomainName,
        [parameter(Mandatory = $false)][string]$DNSserver
    )
     
    #Use DNS server 1.1.1.1 when parameter DNSserver is not used
    if (-not ($DNSserver)) {
        $DNSserver = '1.1.1.1'
    }
 
    #Retrieve all mail DNS records
    $autodiscoverA = (Resolve-DnsName -Name "autodiscover.$($domainname)" -Type A -Server $DNSserver -ErrorAction SilentlyContinue).IPAddress
    $autodiscoverCNAME = (Resolve-DnsName -Name "autodiscover.$($domainname)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue).NameHost
    $dkim1 = Resolve-DnsName -Name "selector1._domainkey.$($domainname)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
    $dkim2 = Resolve-DnsName -Name "selector2._domainkey.$($domainname)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
    $domain = Resolve-DnsName -Name $DomainName -Server $DNSserver -ErrorAction SilentlyContinue
    $dmarc = (Resolve-DnsName -Name "_dmarc.$($DomainName)" -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue).Strings
    $mx = (Resolve-DnsName -Name $DomainName -Type MX -Server $DNSserver -ErrorAction SilentlyContinue).NameExchange
    $spf = (Resolve-DnsName -Name $DomainName -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue | Where-Object Strings -Match 'v=spf').Strings
 
    #Set variables to Not enabled or found if they can't be retrieved
    #and stop script if domainname is not valid 
    $errorfinding = 'Not enabled'
    if ($null -eq $domain) {
        Write-host $DomainName not found -ForegroundColor Red
        Break
    }
 
    if ($null -eq $dkim1 -and $null -eq $dkim2) {
        $dkim = $errorfinding
    }
    else {
        $dkim = "$($dkim1.Name) , $($dkim2.Name)"
    }
 
    if ($null -eq $dmarc) {
        $dmarc = $errorfinding
    }
 
    if ($null -eq $mx) {
        $mx = $errorfinding
    }
 
    if ($null -eq $spf) {
        $spf = $errorfinding
    }
 
    if (($autodiscoverA).count -gt 1) {
        $autodiscoverA = $errorfinding
    }
 
    if ($null -eq $autodiscoverCNAME) {
        $autodiscoverCNAME = $errorfinding
    }
 
    $info = [PSCustomObject]@{
        'Domain Name'             = $DomainName
        'Autodiscover IP-Address' = $autodiscoverA
        'Autodiscover CNAME '     = $autodiscoverCNAME
        'DKIM Record'             = $dkim
        'DMARC Record'            = $dmarc
        'MX Record(s)'            = $mx -join ', '
        'SPF Record'              = $spf
    }
         
    return $info
      
}