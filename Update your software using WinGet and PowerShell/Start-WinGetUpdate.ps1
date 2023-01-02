function Start-WinGetUpdate {
    param (
        [switch]$SkipVersionCheck
    )

    #Check if script was started as Administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Warning ("{0} needs admin privileges, exiting now...." -f $MyInvocation.MyCommand)
        return
    }

    #Check if WinGet is installed, install it if not or skip when SkipVersionCheck was used
    #https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox
    if (-not $SkipVersionCheck) {
        if ((Get-AppxPackage -Name Microsoft.DesktopAppInstaller).version -lt '1.19.3531.0') {
            try {
                Write-Warning ("Required Winget version 1.4.3531 or higher was not found and installing now")
                Write-Host ("Downloading required files....") -ForegroundColor Green
                $ProgressPreference = "SilentlyContinue"
                Invoke-WebRequest -Uri https://github.com/microsoft/winget-cli/releases/download/v1.4.3531/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle -OutFile "$($env:TEMP)\MicrosoftDesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ErrorAction Stop
                Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "$($env:TEMP)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction Stop
                Write-Host ("Installing components....") -ForegroundColor Green
                #No ErrorAction Stop on VCLibs installation because of in use error when running in Windows Terminal
                Add-AppxPackage "$($env:TEMP)\Microsoft.VCLibs.x64.14.00.Desktop.appx" -ErrorAction SilentlyContinue
                Add-AppxPackage "$($env:TEMP)\MicrosoftDesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -ErrorAction Stop
            }
            catch {
                Write-Warning ("Error downloading/installing WinGet, please check internet access and permissoins...")
                return
            }
        }
        else {
            Write-Host ("WinGet is up-to-date, continuing...") -ForegroundColor Green
        }
    }

    #Start WinGet and silently update  software if possible
    Write-Host ("Starting update of software (If any)...") -ForegroundColor Green
    WinGet.exe upgrade --all --silent --force --accept-source-agreements --disable-interactivity --include-unknown
}