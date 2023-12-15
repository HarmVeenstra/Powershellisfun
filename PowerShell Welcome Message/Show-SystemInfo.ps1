#Variables
$OS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version
$CPU = $((Get-CimInstance -ClassName Win32_Processor).name)
$Disks = foreach ($disk in Get-CimInstance -Class win32_logicaldisk) {
  [PSCustomObject]@{
    Drive = $disk.DeviceID
    Total = [math]::Round($disk.Size / 1GB, 2)
    Free  = [math]::Round($disk.FreeSpace / 1GB, 2) 
  }
}
$Memory = "$(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object {"{0:N2}" -f ([math]::round(($_.Sum/1GB),2))})Gb/$([math]::round((Get-CIMInstance Win32_OperatingSystem).FreePhysicalMemory / 1024 / 1024, 2))Gb"
$processes = (Get-Process).count
$Networkadapters = foreach ($adapter in Get-NetAdapter | Where-Object Status -eq Up | Sort-Object Name, Type) {
  foreach ($ipinterface in Get-NetIPAddress | Where-Object InterfaceAlias -eq $adapter.Name) {
    [PSCustomObject]@{
      Adapter = $adapter.name
      Type    = $ipinterface.AddressFamily
      Address = $ipinterface.IPAddress
    }
  }
}
$usersloggedin = (Get-CimInstance -Query "select * from win32_process where name='explorer.exe'").ProcessID.count

#Screen ouput
Write-Host "Welcome to the $($host.Name) of $($env:COMPUTERNAME) ($($OS.Caption) $($OS.Version))`n" -ForegroundColor Green
Write-Host "System information as of $(Get-Date -Format 'dd-MM-yyyy HH:MM')`n" -ForegroundColor Green
Write-Host "CPU:`t`t`t`t$($CPU)" -ForegroundColor Green
foreach ($disk in $Disks) {
  Write-Host "Disk $($disk.Drive) Total/Free:`t`t$($disk.Total)/$($disk.free)" -ForegroundColor Green
}
Write-Host "Memory usage (Total/Free):`t$($Memory)" -ForegroundColor Green
Write-Host "Processes:`t`t`t$($processes)" -ForegroundColor Green
Write-Host "Users logged in:`t`t$($usersloggedin)" -ForegroundColor Green
foreach ($adapter in $Networkadapters | Sort-Object Adapter, Type) {
  Write-Host "Adapter $($adapter.Adapter):`t`t$($adapter.Type) - $($adapter.Address)" -ForegroundColor Green
}