param (
    [parameter(Mandatory = $true)][string]$Id,
    [parameter(Mandatory = $false)][switch]$Install,
    [parameter(Mandatory = $false)][switch]$Uninstall
)

#Start Transcript logging to C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$Id_Custom.txt
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($Id)_Custom.txt" -Append:$true -Force:$true

#Add the command in the try section and use -ErrorAction Stop behind the command(s)
# For example, "Remove-Item "C:\Users\Public\Desktop\Firefox.lnk" -Force:$true -Confirm:$false -ErrorAction Stop"
# Or "if (Get-Process -Name 'Greenshot' -ErrorAction SilentlyContinue) {Stop-Process -Name 'greenshot' -Force:$true -ErrorAction Stop}"

#For install
if ($Install) {
    try {
        
        Write-Host ("{0} - Executed Custom install command(s)" -f $(Get-Date -Format "dd-MM-yy HH:MM") )
        Stop-Transcript
    }
    catch {
        Write-Warning ("{0} - Error executing Custom install command(s), check syntax/permissions!" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
        Stop-Transcript
    }
}

#For Uninstall
if ($Uninstall) {
    try {
        
        Write-Host ("{0} - Executed Custom uninstall command(s)" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
        Stop-Transcript
    }
    catch {
        Write-Warning ("{0} - Error executing Custom uninstall command(s), check syntax/permissions!" -f $(Get-Date -Format "dd-MM-yy HH:MM"))
        Stop-Transcript
    }
}