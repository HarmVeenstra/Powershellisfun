#Function to retreive a new Message Of The Day (MOTD) in your PowerShell session
function New-MOTD {
    param (
        [parameter(Mandatory = $false)][string]$Quoteonly
    )
    #Retrieve quote from goldenquotes.net
    #Get random numbers for the page number and quote number
    $randompage = Get-Random -Minimum 1 -Maximum 7
    $randomquote = Get-Random -Minimum 1 -Maximum 100
    try {
        $page = Invoke-RestMethod -Uri "https://www.thegoldenquotes.net/best-100-public-domain-quotes-of-all-time-collection-0$($randompage)/"
        $convertedpage = ConvertFrom-HTMLClass -Class "siteorigin-widget-tinymce" -Content $page -ErrorAction SilentlyContinue
        $quote = "Message Of The Day:`n" + $($convertedpage)[$($randomquote)].substring(2)
        return $quote
    }
    #Show an error is there is an issue
    catch {
        Write-Host "Error retrieving MOTD, please try again later..." -ForegroundColor Red
    }
}