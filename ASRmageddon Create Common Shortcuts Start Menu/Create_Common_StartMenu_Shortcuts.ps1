$programs = @{
    "Access"                                  = @("C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE", "None")
    "Adobe Acrobat"                           = @("C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe", "None")
    "Cisco Webex Meetings"                    = @("C:\Program Files (x86)\Webex\Webex\Applications\ptoneclk.exe", "Cisco Webex Meetings")
    "Cisco AnyConnect Secure Mobility Client" = @("C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe", "Cisco\Cisco AnyConnect Secure Mobility Client")
    "Excel"                                   = @("C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE", "None")
    "Firefox Private Browsing"                = @("C:\Program Files\Mozilla Firefox\private_browsing.exe", "None")
    "Firefox"                                 = @("C:\Program Files\Mozilla Firefox\firefox.exe", "None")
    "Google Chrome"                           = @("C:\Program Files\Google\Chrome\Application\chrome.exe", "None")
    "Microsoft Edge"                          = @("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", "None")
    "Notepad++"                               = @("C:\Program Files\Notepad++\notepad++.exe", "None")
    "OneNote"                                 = @("C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE", "None")
    "Outlook"                                 = @("C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE", "None")
    "PowerPoint"                              = @("C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE", "None")
    "Project"                                 = @("C:\Program Files\Microsoft Office\root\Office16\WINPROJ.EXE", "None")
    "Publisher"                               = @("C:\Program Files\Microsoft Office\root\Office16\MSPUB.EXE", "None")
    "Remote Desktop"                          = @("C:\Program Files\Remote Desktop\msrdcw.exe", "None")
    "TeamViewer"                              = @("C:\Program Files\TeamViewer\TeamViewer.exe", "None")
    "Visio"                                   = @("C:\Program Files\Microsoft Office\root\Office16\VISIO.EXE", "None")
    "Word"                                    = @("C:\Program Files\Microsoft Office\root\Office16\WINWORD.exe", "None")
}



#Check for shortcuts in Start Menu, if program is available and the shortcut isn't... Then recreate the shortcut
$programs.GetEnumerator() | ForEach-Object {
    if (Test-Path -Path $_.Value[0]) {
        #start with empty $create variable
        $create = $null

        #Shortcut variables for root of Start Menu folder
        if ($_.Value[1] -eq 'None') {
            if (-not (Test-Path -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Key).lnk")) {
                write-host ("Shortcut for {0} not found with path {1}, creating it now..." -f $_.Key, $_.Value[0])
                $create = "Yes"
                $shortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Key).lnk"
                $target = $_.Value[0]                
            }
        }

        #Shortcut variables for subfolder(s) inside the Start Menu folder
        if ($_.Value[1] -ne 'None') {
            if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Value[1])\$($_.Key).lnk")) {
                if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Value[1])")) {
                    write-host ("Specified folder {0} doesn't exist for the {1} shortcut, creating now..." -f $_.Value[1], $_.Key)
                    New-Item -ItemType Directory -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Value[1])" -Force | Out-Null
                    write-host ("Creating shortcut for {0} with path {1} in folder {2}..." -f $_.Key, $_.Value[0], $_.Value[1])
                }
                else {
                    write-host ("Shortcut for {0} not found with path {1} in existing folder {2}, creating it now..." -f $_.Key, $_.Value[0], $_.Value[1])
                }
                $create = "Yes"
                $shortcut = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$($_.Value[1])\$($_.Key).lnk"
                $target = $_.Value[0]                
            }
        }

        #If $create is Yes, set Shortcut variables and create shortcut
        if ($create -eq 'Yes') {     
            $description = $_.Key
            $workingdirectory = (Get-ChildItem $target).DirectoryName
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcut)
            $Shortcut.TargetPath = "$target"
            $Shortcut.Description = $description
            $shortcut.WorkingDirectory = $workingdirectory
            $Shortcut.Save()
        }
    }
}
