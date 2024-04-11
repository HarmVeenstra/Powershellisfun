# Detection
if (Get-CIMInstance -Class Win32_Service | Select-Object Name, PathName, DisplayName, StartMode | Where-Object { $_.PathName -notmatch '"' -and $_.PathName -match ' ' }) {
    Write-Host ("Service found without quotes")
    exit 1
}
else {
    Write-Host ("No Service found without quotes")
    exit 
}