$printers = @(
    'Contoso-General'
    'Contoso-HP'
    'Contoso-MFP'
)

#Check every printer if it's installed
$numberofprintersfound = 0
foreach ($printer in $printers) {
    try {
        Get-Printer -Name $printer -ErrorAction Stop
        $numberofprintersfound++
    }
    catch {
        "Printer $($printer) not found"
    }
}

#If all printers are installed, exit 0
if ($numberofprintersfound -eq $printers.count) {
    write-host "($numberofprintersfound) printers were found"
    exit 0
}
else {
    write-host "Not all $($printers.count) printers were found"
    exit 1
}