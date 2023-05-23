Start-Transcript -Path c:\windows\temp\printers.log
#Read printers.csv as input
$Printers = Import-Csv .\printers.csv -Delimiter ';'

#Add all printer drivers by scanning for the .inf files and installing them using pnputil.exe
$infs = Get-ChildItem -Path . -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Fullname

$totalnumberofinfs = $infs.Count
$currentnumber = 1
Write-Host ("[Install printer driver(s)]`n") -ForegroundColor Green
Foreach ($inf in $infs) {
    Write-Host ("[{0}/{1}] Adding inf file {2}" -f $currentnumber, $totalnumberofinfs, $inf) -ForegroundColor Green
    try {
        c:\windows\sysnative\Pnputil.exe /a $inf | Out-Null
    }
    catch {
        try {
            c:\windows\system32\Pnputil.exe /a $inf | Out-Null
        }
        catch {
            C:\Windows\SysWOW64\pnputil.exe /a $inf | Out-Null
        }
    }
    $currentnumber++
}

#Add all installed drivers to Windows using the CSV list for the correct names
$totalnumberofdrivers = ($printers.drivername | Select-Object -Unique).count
$currentnumber = 1
Write-Host ("`n[Add printerdriver(s) to Windows]") -ForegroundColor Green
foreach ($driver in $printers.drivername | Select-Object -Unique) {
    Write-Host ("[{0}/{1}] Adding printerdriver {2}" -f $currentnumber, $totalnumberofdrivers, $driver) -ForegroundColor Green
    Add-PrinterDriver -Name $driver
    $currentnumber++
}

#Loop through all printers in the csv-file and add the Printer port, the printer and associate it with the port and set the color options to 0 which is black and white (1 = automatic and 2 = color)
$totalnumberofprinters = $Printers.Count
$currentnumber = 1
Write-Host ("`n[Add printer(s) to Windows]") -ForegroundColor Green
foreach ($printer in $printers) {
    Write-Host ("[{0}/{1}] Adding printer {2}" -f $currentnumber, $totalnumberofprinters, $printer.Name) -ForegroundColor Green
    #Set options for adding printers and their ports
    $PrinterAddOptions = @{
        ComputerName = $env:COMPUTERNAME
        Comment      = $Printer.Comment
        DriverName   = $Printer.DriverName
        Location     = $Printer.Location
        Name         = $Printer.Name
        PortName     = $Printer.Name
    }

    $PrinterConfigOptions = @{
        Color         = 0
        DuplexingMode = 'TwoSidedLongEdge'
        PrinterName   = $Printer.Name
    }

    $PrinterPortOptions = @{
        ComputerName       = $env:COMPUTERNAME
        Name               = $Printer.Name
        PrinterHostAddress = $Printer.PortName
        PortNumber         = '9100'
    }

    #Add Printerport, remove existing one and the corresponding printer if it already exists 
    if (Get-PrinterPort -ComputerName $env:COMPUTERNAME | Where-Object Name -EQ $printer.Name) {  
        Write-Warning ("Port for Printer {0} already exists, removing existing port and printer first" -f $printer.Name)
        Remove-Printer -Name $printer.Name -ComputerName $env:COMPUTERNAME -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 10
        Remove-PrinterPort -Name $printer.Name -ComputerName $env:COMPUTERNAME -Confirm:$false
    }

    #Add printer and configure it with the required options
    Add-PrinterPort @PrinterPortOptions
    Add-Printer @PrinterAddOptions -ErrorAction SilentlyContinue
    Set-PrintConfiguration @PrinterConfigOptions
    $currentnumber++
}
Stop-Transcript