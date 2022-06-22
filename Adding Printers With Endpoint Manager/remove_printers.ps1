#Read printers.csv as input
$Printers = Get-Content .\printers.csv | ConvertFrom-Csv
 
#Loop through all printers in the csv-file and remove the printers listed
foreach ($printer in $printers) {
    #Use Splatting for the options
     
    $PrinterRemoveOptions = @{
        Confirm = $false
        Name    = $Printer.Name
    }
 
    $PrinterRemoveOptions = @{
        Confirm = $false
        Name    = $Printer.Name
    }
 
    #Remove printers and their ports
    Remove-Printer @PrinterRemoveOptions
    Start-Sleep -Seconds 60
    Remove-PrinterPort @PrinterRemoveOptions
}
 
#Remove check file
Remove-Item -Path C:\ProgramData\Contoso\Printers.txt -Confirm:$false -Force:$true