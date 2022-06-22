#Read printers.csv as input
$Printers = Get-Content .\printers.csv | ConvertFrom-Csv
 
#Loop through all printers in the csv-file and add the Printer port, the printer and associate it with the port and set the color options to 0 which is black and white (1 = automatic and 2 = color)
foreach ($printer in $printers) {
    #Use Splatting for the options
    $PrinterPortOptions = @{
        Name               = $Printer.Name
        PrinterHostAddress = $Printer.PortName
        PortNumber         = '9100'
    }
 
    $PrinterAddOptions = @{
        Comment    = $Printer.Comment
        DriverName = $Printer.DriverName
        Location   = $Printer.Location
        Name       = $Printer.Name
        PortName   = $Printer.Name
    }
 
    $PrinterConfigOptions = @{
        Color       = 0
        DuplexingMode = 'TwoSidedLongEdge'
        PrinterName = $Printer.Name
    }
 
    #Add Printerport, printer and configure it with the options required
    Add-PrinterPort @PrinterPortOptions
    Add-Printer @PrinterAddOptions
    Set-PrintConfiguration @PrinterConfigOptions
}
 
#Add check file to c:\programdata for detection
New-Item -Path C:\ProgramData\Contoso\Printers.txt -ItemType File -Confirm:$false -Force:$true