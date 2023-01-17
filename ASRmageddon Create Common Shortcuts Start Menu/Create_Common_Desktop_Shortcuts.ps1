$programs = @{
    "Adobe Acrobat"  = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
    "Excel"          = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
    "Firefox"        = "C:\Program Files\Mozilla Firefox\firefox.exe"
    "Google Chrome"  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "Microsoft Edge" = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    "OneNote"        = "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE"
    "Outlook"        = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
    "Remote Desktop" = "C:\Program Files\Remote Desktop\msrdcw.exe"
    "TeamViewer"     = "C:\Program Files\TeamViewer\TeamViewer.exe"
    "Word"           = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.exe"
}


#Check for shortcuts on Desktop, if program is available and the shortcut isn't... Then recreate the shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$programs.GetEnumerator() | ForEach-Object {
    if (Test-Path -Path $_.Value) {
        if (-not (Test-Path -Path "$($DesktopPath)\$($_.Key).lnk")) {
            write-host ("Shortcut for {0} not found in {1}, creating it now..." -f $_.Key, $_.Value)
            $shortcut = "$($DesktopPath)\$($_.Key).lnk"
            $target = $_.Value
            $description = $_.Key
            $workingdirectory = (Get-ChildItem $target).DirectoryName
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcut)
            $Shortcut.TargetPath = $target
            $Shortcut.Description = $description
            $shortcut.WorkingDirectory = $workingdirectory
            $Shortcut.Save()
        }
    }
}