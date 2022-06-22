function Get-WhoisInfo {
    param(
        [parameter(Mandatory = $false)][string]$PublicIPaddressOrName
    )
 
    try {
        #Get results from your own Public IP Address
        if (-not ($PublicIPaddressOrName)) {
            $ProgressPreference = "SilentlyContinue"
            $PublicIPaddressOrName = (Invoke-WebRequest -uri https://api.ipify.org?format=json | ConvertFrom-Json -ErrorAction Stop).ip
            $whoiswebresult = Invoke-Restmethod -Uri "https://www.whois.com/whois/$($PublicIPaddressOrName)"
            $whoisinfo = ConvertFrom-HTMLClass -Class whois-data -Content $whoiswebresult -ErrorAction SilentlyContinue
            write-host Getting WHOIS details for $PublicIPaddressOrName -ForegroundColor Green
        }
        #Get results from the Public IP or name specified
        else {
            $ProgressPreference = "SilentlyContinue"
            $whoiswebresult = Invoke-Restmethod -Uri "https://www.whois.com/whois/$($PublicIPaddressOrName)" -ErrorAction SilentlyContinue
            $whoisinfo = ConvertFrom-HTMLClass -Class whois-data -Content $whoiswebresult -ErrorAction SilentlyContinue
            write-host Getting WHOIS details for $PublicIPaddressOrName -ForegroundColor Green
        }
     
        Return $whoisinfo  
    }
    catch {
        write-host Error getting WHOIS details -ForegroundColor Red
    }
}