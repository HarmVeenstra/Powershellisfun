function Get-MailDomainInfo {
    param(
        [parameter(Mandatory = $true)][string[]]$DomainName,
        [parameter(Mandatory = $false)][string]$DNSserver
    )
     
    #Use DNS server 1.1.1.1 when parameter DNSserver is not used
    if (-not ($DNSserver)) {
        $DNSserver = '1.1.1.1'
    }

    $info = foreach ($domain in $DomainName) {
 
        #Retrieve all mail DNS records
        $autodiscoverA = (Resolve-DnsName -Name "autodiscover.$($domain)" -Type A -Server $DNSserver -ErrorAction SilentlyContinue).IPAddress
        $autodiscoverCNAME = (Resolve-DnsName -Name "autodiscover.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue).NameHost
        $dkim1 = Resolve-DnsName -Name "selector1._domainkey.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
        $dkim2 = Resolve-DnsName -Name "selector2._domainkey.$($domain)" -Type CNAME -Server $DNSserver -ErrorAction SilentlyContinue
        $domaincheck = Resolve-DnsName -Name $domain -Server $DNSserver -ErrorAction SilentlyContinue
        $dmarc = (Resolve-DnsName -Name "_dmarc.$($domain)" -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue | Where-Object Strings -Match 'DMARC').Strings
        $mx = (Resolve-DnsName -Name $domain -Type MX -Server $DNSserver -ErrorAction SilentlyContinue).NameExchange
        $spf = (Resolve-DnsName -Name $domain -Type TXT -Server $DNSserver -ErrorAction SilentlyContinue | Where-Object Strings -Match 'v=spf').Strings
 
        #Set variables to Not enabled or found if they can't be retrieved
        #and stop script if domaincheck is not valid 
        $errorfinding = 'Not enabled'
        if ($null -eq $domaincheck) {
            Write-Warning ("{0} not found" -f $domaincheck)
            return
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
 
        [PSCustomObject]@{
            'Domain Name'             = $domain
            'Autodiscover IP-Address' = $autodiscoverA
            'Autodiscover CNAME '     = $autodiscoverCNAME
            'DKIM Record'             = $dkim
            'DMARC Record'            = "$($dmarc)"
            'MX Record(s)'            = $mx -join ', '
            'SPF Record'              = "$($spf)"
        }
    }
         
    return $info
      
}