function Get-CoinMarketCap {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Enter the coin that you want to search for, i.e. BTC")][string]$Search
    )

    #Set values for API call
    $params = @{
        uri     = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest'
        Method  = 'Get'
        Headers = @{
            "Content-Type"      = 'Accept: application/json'
            "X-CMC_PRO_API_KEY" = 'xxxxxxxx'
        }
    }

    #retrieve data
    $data = Invoke-RestMethod @params
    if ($null -eq $Search) {
        $coins = $data.data | Sort-Object cmc_rank | Select-Object -First 10
    }
    else {
        $coins = $data.data | Where-Object Symbol -EQ $Search
        if ($null -eq $coins) {
            Write-Warning ("Specified {0} coin was not found, exiting..." -f $Search)
            return
        }
    }

    $total = foreach ($coin in $coins) {
        [PSCustomObject]@{
            "Rank"               = $coin.cmc_rank
            "Name"               = $coin.Name
            "Symbol"             = $coin.Symbol
            "Price in USD"       = $coin.quote.usd.Price
            "1 hour difference"  = "$($coin.quote.usd.percent_change_1h)%"
            "24 hour difference" = "$($coin.quote.usd.percent_change_24h)%"
            "7 day difference"   = "$($coin.quote.usd.percent_change_7d)%"
        }
    }
    return $total | Format-Table -AutoSize
}