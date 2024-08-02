#Install WinGet, used https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox
Start-Transcript C:\users\wdagutilityaccount\desktop\Installing.txt
$progressPreference = 'silentlyContinue'
Write-Information "Downloading WinGet and its dependencies..."
Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile $env:temp\Microsoft.VCLibs.x64.14.00.Desktop.appx
Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile $env:temp\Microsoft.UI.Xaml.2.8.x64.appx
Add-AppxPackage $env:temp\Microsoft.VCLibs.x64.14.00.Desktop.appx
Add-AppxPackage $env:temp\Microsoft.UI.Xaml.2.8.x64.appx
Add-AppxPackage $env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle

#Install software
$SoftwareToInstall = "Notepad++.Notepad++", "Microsoft.VisualStudioCode"
foreach ($Software in $SoftwareToInstall) {
    WinGet.exe install $software --silent --force --accept-source-agreements --disable-interactivity --source winget
}
Stop-Transcript
Rename-Item -Path C:\users\wdagutilityaccount\desktop\Installing.txt -NewName C:\users\wdagutilityaccount\desktop\Done.txt