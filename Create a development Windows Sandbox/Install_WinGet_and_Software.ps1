#Install WinGet, used https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox
Start-Transcript C:\users\wdagutilityaccount\desktop\Installing.txt
$progressPreference = 'silentlyContinue'
Write-Information "Downloading WinGet and its dependencies..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force:$true -Verbose
Install-Module Microsoft.WinGet.Client -Force:$true -Confirm:$false -Verbose
Import-Module Microsoft.WinGet.Client -Verbose
Repair-WinGetPackageManager -Force:$true -Verbose

#Install software
$SoftwareToInstall = "Notepad++.Notepad++", "Microsoft.VisualStudioCode"
foreach ($Software in $SoftwareToInstall) {
    WinGet.exe install $software --silent --force --accept-source-agreements --disable-interactivity --source winget
}
Stop-Transcript
Rename-Item -Path C:\users\wdagutilityaccount\desktop\Installing.txt -NewName C:\users\wdagutilityaccount\desktop\Done.txt