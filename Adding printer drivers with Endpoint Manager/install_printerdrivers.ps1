$drivers = Import-Csv .\Drivers.csv -Delimiter ','
foreach ($driver in $drivers) {
    try {
        c:\windows\sysnative\pnputil.exe -a $driver.Path
    }
    catch {
        try {
            c:\windows\system32\pnputil.exe -a $driver.Path
        }
        catch {
            C:\Windows\SysWOW64\pnputil.exe -a $driver.Path
        }
    }
    Start-Sleep -Seconds 5
}
New-Item -Path c:\programdata\customer\Printers\printers.txt -Force:$true -Confirm:$false