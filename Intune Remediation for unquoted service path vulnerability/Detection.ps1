# Detection
if (Get-CIMInstance -Class Win32_Service | Select-Object Name, PathName, DisplayName, StartMode | Where-Object { $_.StartMode -eq 'Auto' -and $_.PathName -notmatch 'Windows' -and $_.PathName -notmatch '"' }) {
    Write-Host ("Service found without quotes")
    exit 1
}
else {
    Write-Host ("No Service found without quotes")
    exit 
}