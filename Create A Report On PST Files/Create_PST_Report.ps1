#Set total variable to null
$total = @()
 
#Fill the locationstoscan variable with all locations that need to be scanned
$locationstoscan = "D:\Exports", "D:\Temp"
 
#Loop through the locations and add the PST information to the total variable
foreach ($location in $locationstoscan) {
    write-host Processing $share -ForegroundColor Green
    $psts = Get-ChildItem -Recurse -Path $location -Filter *.pst -ErrorAction SilentlyContinue | Sort-Object Fullname
    foreach ($pst in $psts) {
        $csv = [PSCustomObject]@{
            Filename           = $pst.FullName
            "Size In Mb"       = [math]::Round($pst.Length / 1Mb, 2)
            "Last Access Time" = $pst.LastAccessTime            
            "Last Write by"    = (Get-Acl $pst.FullName).Owner        
            "Last Write Time"  = $pst.LastWriteTime
        }
        $total += $csv
    }
}
 
#Export all results to a pst.csv file in c:\temp sorted on FileName
$total | Sort-Object Filename | export-csv -NoTypeInformation -Delimiter ';' -Path D:\Temp\pst.csv