$drivers = Import-Csv .\Drivers.csv -Delimiter ','
foreach ($driver in $drivers) {
    pnputil.exe -a $driver.Path
    Start-Sleep -Seconds 5
    Add-PrinterDriver -Name $driver.name
}
New-Item -Path c:\programdata\customer\Printers\printers.txt -Force:$true -Confirm:$false