#Retrieve quote from goldenquotes.net
#Get random numbers for the page number and quote number
$randompage = Get-Random -Minimum 1 -Maximum 7
$randomquote = Get-Random -Minimum 1 -Maximum 100

#Check if the module PSParseHTML is installed and install
#the module if it's not installed
if (-not (Get-Command ConvertFrom-HTMLClass -ErrorAction SilentlyContinue)) {
    Install-Module PSParseHTML -SkipPublisherCheck -Force:$true -Confirm:$false
}

#Get a random quote and display it
try {
    $page = Invoke-RestMethod -Uri "https://www.thegoldenquotes.net/best-100-public-domain-quotes-of-all-time-collection-0$($randompage)/"
    $convertedpage = ConvertFrom-HTMLClass -Class "siteorigin-widget-tinymce" -Content $page -ErrorAction SilentlyContinue
    $quote = "Message Of The Day:`n" + $($convertedpage)[$($randomquote)].substring(2)
    return $quote
}
#Show an error is there is an issue
catch {
    Write-Warning ("Error retrieving MOTD, please try again later...")
}
