param(
  [parameter(mandatory = $false)][String]$Token = 'XXXX',
  [parameter(mandatory = $false)][String]$Address = 'XXXX',
  [parameter(mandatory = $false)][String]$Port = 'XXXX'
)
  
#Connecting to PiHole and retrieving blocked items using $Token, $Address and $Port 
Write-Host ("Connecting to {0} and retrieving recently blocked queries. (Use CTRL-C to stop)" -f $Address) -ForegroundColor Green
while ($true) {
  try {
    $Recent = Invoke-RestMethod -Uri "http://$($Address):$($Port)/admin/api.php?auth=$Token&recentBlocked" -ErrorAction Stop
    if ($Recent -ne $Previous) {
      Write-Host ("PiHole blocked {0} at {1}" -f $Recent, $(Get-Date -Format "dd-MM-yy HH:MM:ss:ff")) 
      $Previous = $Recent
    }
  }
  catch {
    Write-Warning ("Error reading data from {0} on port {1}, check token/network access. Exiting..." -f $Address, $Port)
    return  
  }
}