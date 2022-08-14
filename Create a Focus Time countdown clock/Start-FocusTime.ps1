function Start-FocusTime {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the amount of minutes you want to focus in")][string]$Minutes

    )

    #Get a list from your Task Manager for the correct names, look for them in the Details pane and add them without the extension
    #For example Outlook instead of Outlook.exe
    $ProgramsToKill = @(
        "Outlook",
        "Spotify",
        "Teams"
    )
    
    #Close all programs in the $ProgramsToKill variable
    Write-Host ("Starting Focus Time for {0} minutes, please close and save open document (if any) in the following programs:" -f $Minutes) -ForegroundColor Green
    $ProgramsToKill -join ', ' | Sort-Object
    Read-Host -Prompt "Press Enter to continue" 
    Write-Host "Closing programs if active..." -ForegroundColor Green
    foreach ($program in $ProgramsToKill) {
        if (Get-Process $program -ErrorAction SilentlyContinue) {
            try {
                Get-Process $Program | Stop-Process -Force:$true -Confirm:$false -ErrorAction Stop
                Write-Host ("Closing {0}" -f $program) -ForegroundColor Green
            }
            catch {
                Write-Warning ("Could not close {0}, please close it manually..." -f $program)
            }
        }
    }

    #Start countdown, countdown to zero and restart programs again
    #Used countdown procedure from https://www.powershellgallery.com/packages/start-countdowntimer/1.0/Content/Start-CountdownTimer.psm1
    $t = New-TimeSpan -Minutes $Minutes
    $origpos = $host.UI.RawUI.CursorPosition
    $spinner = @('|', '/', '-', '\')
    $spinnerPos = 0
    $remain = $t
    $d = ( get-date) + $t
    [int]$TickLength = 1
    $remain = ($d - (get-date))
    Write-Host ("Starting focus time for {0} minutes" -f $Minutes) -ForegroundColor Green
    while ($remain.TotalSeconds -gt 0) {
        Write-Host (" {0} " -f $spinner[$spinnerPos % 4]) -ForegroundColor Green -NoNewline
        write-host (" {0}D {1:d2}h {2:d2}m {3:d2}s " -f $remain.Days, $remain.Hours, $remain.Minutes, $remain.Seconds) -NoNewline
        $host.UI.RawUI.CursorPosition = $origpos
        $spinnerPos += 1
        Start-Sleep -seconds $TickLength
        $remain = ($d - (get-date))
    }
    $host.UI.RawUI.CursorPosition = $origpos
    Write-Host " * "  -ForegroundColor Green -NoNewline
    write-host " Countdown finished, restarting programs..." -ForegroundColor Green
    
    foreach ($program in $ProgramsToKill) {
        try {
            Write-Host ("Starting {0}" -f $program) -ForegroundColor Green
            Start-Process $program
        }
        catch {
            Write-Warning ("Could not start {0}, please start it manually..." -f $program)
        }
    }
}