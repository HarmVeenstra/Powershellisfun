$drivers = Import-Csv .\Drivers.csv -Delimiter ','
foreach ($driver in $drivers) {
    Remove-PrinterDriver -Name $driver.name -Confirm:$false
    Start-Sleep -Seconds 5
    C:\Windows\Sysnative\pnputil.exe -d $driver.Path
}
remove-Item -Path c:\programdata\customer\Printers -Recurse -Force:$true -Confirm:$false