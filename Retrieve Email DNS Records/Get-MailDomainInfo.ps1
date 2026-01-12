function Get-MailDomainInfo {
    param(
        [parameter(Mandatory = $true)][string[]]$DomainName,
        [parameter(Mandatory = $false)][string]$DNSserver = '1.1.1.1'
    )
     
    $info = foreach ($domain in $DomainName) {        
        #Check if domain name is valid, output warning it not and continue to the next domain (if any)
        try {      
            #Check if DnsClient-PS module is installed
            if (-not (Get-Module -Name DnsClient-PS -ListAvailable -ErrorAction SilentlyContinue)) {
                try {
                    Install-Module DnsClient-PS -Scope CurrentUser -Confirm:$false -Force:$true -ErrorAction Stop
                    Import-Module DnsClient-PS -ErrorAction Stop
                    Write-Host ("Installed required module DnsClient-PS, continuing...")
                }
                catch {
                    Write-Warning ("Error installing required DnsClient-PS module for Linux/macOS DNS queries, exiting...")
                    return
                }
            }

            #Test if Domain name exists
            Resolve-Dns -Query $domain -NameServer $DNSserver -ErrorAction Stop | Out-Null

            #Set $erorfind to desired error output. 'not enabled', for example
            $errorfinding = 'Not enabled'

            #Retrieve all mail DNS records
            $autodiscoverA = (Resolve-Dns -Query "autodiscover.$($domain)" -QueryType A -NameServer $DNSserver -ErrorAction SilentlyContinue).IPAddress
            $autodiscoverCNAME = if ((Resolve-Dns -Query "autodiscover.$($domain)" -QueryType CNAME -NameServer $DNSserver -ErrorAction SilentlyContinue).Answers) { (Resolve-Dns -Query "autodiscover.$($domain)" -QueryType CNAME -NameServer $DNSserver -ErrorAction SilentlyContinue).Answers.canonicalname.tostring() }
            $dkim1 = (Resolve-Dns -Query "selector1._domainkey.$($domain)" -QueryType CNAME -NameServer $DNSserver -ErrorAction SilentlyContinue).AllRecords.domainname.original[0].tostring().TrimEnd('.')
            $dkim2 = (Resolve-Dns -Query "selector2._domainkey.$($domain)" -QueryType CNAME -NameServer $DNSserver -ErrorAction SilentlyContinue).AllRecords.domainname.original[0].tostring().TrimEnd('.')
            $dmarc = (Resolve-Dns -Query "_dmarc.$($domain)" -QueryType TXT -NameServer $DNSserver -ErrorAction SilentlyContinue).answers.escapedtext
            $dnssec = (Resolve-Dns -Query $domain -QueryType DNSKEY -ErrorAction SilentlyContinue).Answers
            $mx = (Resolve-Dns -Query $domain -QueryType MX -NameServer $DNSserver -ErrorAction SilentlyContinue).Answers.Exchange
            $spf = (Resolve-Dns -Query $domain -QueryType TXT -NameServer $DNSserver -ErrorAction SilentlyContinue).Answers.escapedtext | Select-String 'v=spf'
            $includes = ((Resolve-Dns -Query $domain -QueryType TXT -NameServer $DNSserver -ErrorAction SilentlyContinue).Answers.escapedtext | Select-String 'v=spf').line.split(' ') | Select-String -Pattern 'Include:'
 
            if ($dkim1.length -le 1 -and $dkim2.Length -le 1) {
                $dkim = $errorfinding
            }
            else {
                $dkim = "$($dkim1), $($dkim2)"
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

            if ($null -eq $autodiscoverCNAME) {
                $autodiscoverCNAME = $errorfinding
            }

            if (($autodiscoverA).count -gt 1 -or $null -ne $autodiscoverCNAME) {
                $autodiscoverA = $errorfinding
            }

            if ($null -eq $includes) {
                $includes = $errorfinding
            }
            else {
                $foundincludes = foreach ($include in $includes) {
                    if ((Resolve-Dns -NameServer $DNSserver -Query $include.ToString() -ErrorAction SilentlyContinue)) {
                        [PSCustomObject]@{
                            SPFIncludes = $include.ToString().Split(':')[1] + " : " + (Resolve-Dns -NameServer $DNSserver -Query $include.ToString().Split(':')[1] -QueryType txt).answers.escapedtext
                        }
                    }
                    else {
                        [PSCustomObject]@{
                            SPFIncludes = $errorfinding
                        }
                    }
                }
            }
    
            if ($dnssec.length -lt 1) {
                $dnssec = $errorfinding
            }
            else {
                $dnssec = 'Enabled'
            }
 
            [PSCustomObject]@{
                'Domain Name'             = $domain
                'Autodiscover IP-Address' = $autodiscoverA
                'Autodiscover CNAME '     = "$($autodiscoverCNAME.TrimEnd('.'))"
                'DKIM Record'             = $dkim
                'DMARC Record'            = "$($dmarc)"
                'DNSSEC'                  = $dnssec
                'MX Record(s)'            = if ($mx -ne $errorfinding) { ($mx).Value.TrimEnd('.') -join ', ' } else { $errorfinding }
                'SPF Record'              = "$($spf)"
                'SPF Include values'      = if ("$($foundincludes.SPFIncludes)") { "$($foundincludes.SPFIncludes)" -replace "all", "all`n`b" } else { $errorfinding }
            }
        }
        catch {
            Write-Warning ("{0} not found" -f $domain)
        }     
    }
    return $info 
}