function Get-WhoisInfo {
    param(
        [parameter(Mandatory = $false)][string]$PublicIPaddressOrName
    )

    #Check if the module PSParseHTML is installed and install
    #the module if it's not installed
    if (-not (Get-Command ConvertFrom-HTMLClass -ErrorAction SilentlyContinue)) {
        Install-Module PSParseHTML -SkipPublisherCheck -Force:$true -Confirm:$false
    }

    try {
        #Get results from your own Public IP Address
        if (-not ($PublicIPaddressOrName)) {
            $ProgressPreference = "SilentlyContinue"
            $PublicIPaddressOrName = (Invoke-WebRequest -uri https://api.ipify.org?format=json | ConvertFrom-Json -ErrorAction Stop).ip
            $whoiswebresult = Invoke-Restmethod -Uri "https://who.is/whois-ip/ip-address/$($PublicIPaddressOrName)" -ErrorAction SilentlyContinue
            $whoisinfo = ConvertFrom-HTMLClass -Class 'col-md-12 queryResponseBodyKey' -Content $whoiswebresult -ErrorAction SilentlyContinue
            write-host Getting WHOIS details for $PublicIPaddressOrName -ForegroundColor Green
        }
        #Get results from the Public IP or name specified
        else {
            $ProgressPreference = "SilentlyContinue"
            if ((($PublicIPaddressOrName).Split('.').Length -eq 4)) {
                $whoiswebresult = Invoke-Restmethod -Uri "https://who.is/whois-ip/ip-address/$($PublicIPaddressOrName)" -ErrorAction SilentlyContinue
                $whoisinfo = ConvertFrom-HTMLClass -Class 'col-md-12 queryResponseBodyKey' -Content $whoiswebresult -ErrorAction SilentlyContinue
                write-host Getting WHOIS details for $PublicIPaddressOrName -ForegroundColor Green
            }
            else {
                $whoiswebresult = Invoke-Restmethod -Uri "https://www.who.is/whois/$($PublicIPaddressOrName)" -ErrorAction SilentlyContinue
                $whoisinfo = ConvertFrom-HTMLClass -Class 'col-md-12 queryResponseBodyValue' -Content $whoiswebresult -ErrorAction SilentlyContinue
                write-host Getting WHOIS details for $PublicIPaddressOrName -ForegroundColor Green
            }
        }
    
        Return $whoisinfo   
    }
    catch {
        write-host Error getting WHOIS details -ForegroundColor Red
    }
}