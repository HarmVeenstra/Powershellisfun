Start-Transcript -Path c:\windows\temp\remove_printers.log

#Read printers.csv as input
$Printers = Import-Csv .\printers.csv

#Loop through all printers in the csv-file and remove the printers listed
foreach ($printer in $printers) {
    #Set options
    $PrinterRemoveOptions = @{
        Confirm = $false
        Name    = $Printer.Name
    }

    $PrinterPortRemoveOptions = @{
        Confirm      = $false
        Computername = $env:COMPUTERNAME
        Name         = $Printer.Name
    }

    #Remove printers and their ports
    Remove-Printer @PrinterRemoveOptions
    Start-Sleep -Seconds 10
    Remove-PrinterPort @PrinterPortRemoveOptions
}

#Remove drivers from the system
foreach ($driver in $printers.drivername | Select-Object -Unique) {
    $PrinterDriverRemoveOptions = @{
        Confirm               = $false
        Computername          = $env:COMPUTERNAME
        Name                  = $driver
        RemoveFromDriverStore = $true
    }
    Remove-PrinterDriver @PrinterDriverRemoveOptions
}

Stop-Transcript