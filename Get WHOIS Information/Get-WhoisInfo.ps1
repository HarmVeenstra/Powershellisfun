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
            $PublicIPaddressOrName = (Invoke-WebRequest -uri https://api.ipify.org?format=json -UseBasicParsing | ConvertFrom-Json -ErrorAction Stop).ip
            $whoiswebresult = Invoke-Restmethod -Uri "https://www.whois.com/whois/$($PublicIPaddressOrName)" -TimeoutSec 15 -ErrorAction SilentlyContinue
            $whoisinfo = ConvertFrom-HTMLClass -Class 'whois-data' -Content $whoiswebresult -ErrorAction SilentlyContinue
            write-host ("Getting WHOIS details for {0}" -f $PublicIPaddressOrName) -ForegroundColor Green
        }
        #Get results from the Public IP or name specified
        else {
            $ProgressPreference = "SilentlyContinue"
            if ((($PublicIPaddressOrName).Split('.').Length -eq 4)) {
                $whoiswebresult = Invoke-Restmethod -Uri "https://www.whois.com/whois/$($PublicIPaddressOrName)" -TimeoutSec 15 -ErrorAction SilentlyContinue
                $whoisinfo = ConvertFrom-HTMLClass -Class 'whois-data' -Content $whoiswebresult -ErrorAction SilentlyContinue
                write-host ("Getting WHOIS details for {0}" -f $PublicIPaddressOrName) -ForegroundColor Green
            }
            else {
                $whoiswebresult = Invoke-Restmethod -Uri "https://www.who.is/whois/$($PublicIPaddressOrName)" -TimeoutSec 30 -ErrorAction SilentlyContinue
                $whoisinfo = ConvertFrom-HTMLClass -Class 'df-raw' -Content $whoiswebresult -ErrorAction SilentlyContinue
                write-host ("Getting WHOIS details for {0}" -f $PublicIPaddressOrName) -ForegroundColor Green
            }
        }
    
        Return $whoisinfo   
    }
    catch {
        Write-Warning ("Error getting WHOIS details")
    }
}