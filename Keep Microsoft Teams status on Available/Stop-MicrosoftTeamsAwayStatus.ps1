while ($true) {
    try {
        Get-Process -Name 'ms-teams' -ErrorAction stop | Out-Null
        Write-Host ("{0} - Microsoft Teams is running..." -f $(get-date)) -ForegroundColor Green
        $wshell = New-Object -ComObject wscript.shell
        $wshell.sendkeys("{NUMLOCK}{NUMLOCK}")
        Write-Host ("{0} - Pressed NUMLOCK twice and waiting for 60 seconds" -f $(get-date)) -ForegroundColor Green
        Start-Sleep -Seconds 60          
    }
    catch {
        Write-Warning ("{0} - Microsoft Teams is not running, sleeping for 15 seconds..." -f $(get-date))
        Start-Sleep -Seconds 15
    }
}