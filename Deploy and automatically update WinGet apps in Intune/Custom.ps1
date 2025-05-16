param (
    [parameter(Mandatory = $true)][string]$Id,
    [parameter(Mandatory = $false)][switch]$Install,
    [parameter(Mandatory = $false)][switch]$Uninstall
)

#Start Transcript logging to c:\program data\wingetintune\$id_Custom.txt
Start-Transcript -Path "C:\ProgramData\WinGetIntune\$($id)_Custom.txt" -Append:$true -Force:$true

#Add the command in the try section and use -ErrorAction Stop behind the command(s)
# For example, "Remove-Item "C:\Users\Public\Desktop\Firefox.lnk" -Force:$true -Confirm:$false -ErrorAction Stop"
# Or "if (Get-Process -Name 'Greenshot' -ErrorAction SilentlyContinue) {Stop-Process -Name 'greenshot' -Force:$true -ErrorAction Stop}"

#For install
if ($Install) {
    try {
        
        Write-Host ("Executed Custom install command")
        Stop-Transcript
    }
    catch {
        Write-Warning ("Error executing Custom install command, check spelling/permissions!")
        Stop-Transcript
    }
}

#For Uninstall
if ($Uninstall) {
    try {
        
        Write-Host ("Executed Custom Unistall command")
        Stop-Transcript
    }
    catch {
        Write-Warning ("Error executing Custom uninstall command, check spelling/permissions!")
        Stop-Transcript
    }
}