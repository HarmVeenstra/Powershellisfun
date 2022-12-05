$drivers = Import-Csv .\Drivers.csv -Delimiter ','
foreach ($driver in $drivers) {
    if (Test-Path C:\Windows\Sysnative\pnputil.exe) {
        C:\Windows\Sysnative\pnputil.exe -a $driver.Path
    }
    else {
        C:\Windows\Sytem32\pnputil.exe -a $driver.Path
    }
    Start-Sleep -Seconds 5
    Add-PrinterDriver -Name $driver.name
}
New-Item -Path c:\programdata\customer\Printers\printers.txt -Force:$true -Confirm:$false