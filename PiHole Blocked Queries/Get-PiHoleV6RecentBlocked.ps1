param(
  [parameter(mandatory = $false)][String]$AppPassword = 'XXXX',
  [parameter(mandatory = $false)][String]$Address = 'XXXX',
  [parameter(mandatory = $false)][String]$Port = 'XXXX'
)
  
#Connecting to PiHole using $AppPassword, and retrieve API key for this session
try {
  $request = @{
    'password' = $AppPassword
  }
  $API = (Invoke-RestMethod -Uri "http://$($Address):$($Port)/api/auth" -Method Post -Body $($Request | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop).session.sid
}
catch {
  Write-Warning ("Could not connect to PiHole using App Password, check address/port/AppPassword. Exiting...")
  return
}

#Connecting to PiHole and retrieving blocked items using $AppPassword, $Address and $Port
Write-Host ("Connecting to {0} and retrieving recently blocked queries. (Use CTRL-C to stop)" -f $Address) -ForegroundColor Green
while ($true) {
  try {
    $Recent = (Invoke-RestMethod -Uri "http://$($Address):$($Port)/api/stats/recent_blocked?sid=$($API)" -ErrorAction Stop).blocked
    if ($Recent -ne $Previous) {
      Write-Host ("PiHole blocked {0} at {1}" -f $($Recent), $(Get-Date -Format "dd-MM-yy HH:MM:ss:ff")) 
      $Previous = $Recent
    }
  }
  catch {
    Write-Warning ("Error reading data from {0} on port {1}, check token/network access. Exiting..." -f $Address, $Port)
    return  
  }
}