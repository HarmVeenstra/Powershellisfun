#Create an empty $passwords array which will contain all information
$passwords = @()
 
#Set the output location for .csv file
$output = 'd:\temp\ssid_passwords.csv'
 
#Retrieve all WLAN profiles, loop through them and try to get the passsword
$wlanprofiles = (netsh wlan show profiles) | select-string ': '
if ($null -ne $wlanprofiles) {
    foreach ($wlanprofile in $wlanprofiles | Sort-Object) {
        try {
            $profile_information = netsh wlan show profile name="$($wlanprofile.ToString().Split(':')[1].SubString(1))" key=clear
            write-host Retrieving password for SSID $wlanprofile.ToString().Split(':')[1].SubString(1) -ForegroundColor Green
            $password = [PSCustomObject]@{
                'SSID'                = $wlanprofile.ToString().Split(':')[1].SubString(1)
                'Authentication Type' = ($profile_information | select-string 'Authentication' | Select-Object -First 1).Tostring().Split(':')[1].Substring(1)
                'Password'            = ($profile_information | select-string 'Key Content').Tostring().Split(':')[1].Substring(1)
            }
            $passwords += $password
        }
        catch {
            #If retrieving the password fails, add the reason why to $passwords in the password field
            $authenticationtype = ($profile_information | select-string 'Authentication' | Select-Object -First 1).Tostring().Split(':')[1].Substring(1)
            write-host "Could not retrieve password for SSID $($wlanprofile.ToString().Split(':')[1].SubString(1)), check $($output)" -ForegroundColor Red
            $password = [PSCustomObject]@{
                'SSID'                = $wlanprofile.ToString().Split(':')[1].SubString(1)
                'Authentication Type' = ($profile_information | select-string 'Authentication' | Select-Object -First 1).Tostring().Split(':')[1].Substring(1)
                'Password'            = "Could not retrieve password for the SSID because it's an $($authenticationtype) network"
            }
            $passwords += $password
        }
    }
     
    #Export to $output path and open Excel (Or prompt to associate the .csv file, choose Notepad/Wordpad etc. to view the contents)
    $passwords | export-csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' -Path $output
    Invoke-Item $output
}
else {
    Write-Host "No WLAN profiles found, please check if $($env:COMPUTERNAME) has a Wi-Fi adapter or any saved networks" -ForegroundColor Red
}