function Install-SysInternalsSuite {
    param (
        [parameter(Mandatory = $true)][string]$InstallPath
    )

    # Test admin privileges without using -Requires RunAsAdministrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Warning ("{0} needs to be started with admin privileges, exiting now...." -f $MyInvocation.MyCommand)
        return
    }

    # Create the installation folder if not already present
    if (-not (Test-Path -Path $InstallPath)) {   
        try {
            New-Item -ItemType Directory -Path $InstallPath -ErrorAction Stop | Out-Null
            Write-Host ("Specified installation path {0} not found, creating now...." -f $InstallPath) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Install path {0} not found, creating now...." -f $InstallPath)
            Write-Warning ("Error creating path {0}, check path and permissions. Exiting now..." -f $InstallPath)
            return
        }
    }
    else {
        Write-Host ("Specified installation path {0} found, continuing...." -f $InstallPath) -ForegroundColor Green
    }

    # Check if the previous download folder is present. Remove it first if it is
    if (Test-Path -Path $env:temp\SysInternalsSuite) {
        Write-Warning ("Previous extracted version found in {0}, removing it now..." -f $env:temp)
        Remove-Item -Path $env:temp\SysInternalsSuite -Force:$true -Confirm:$false -Recurse 
    }
    else {
        Write-Host ("No previous download found in {0}\SysInternalsSuite, continuing..." -f $env:temp) -ForegroundColor Green
    }

    # Download and extract the latest version
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -Uri https://download.sysinternals.com/files/SysinternalsSuite.zip -OutFile $ENV:TEMP\SysInternalsSuite.zip -UseBasicParsing -ErrorAction Stop
        Write-Host ("Downloading latest version to {0}\SysinternalsSuite.zip" -f $env:temp) -ForegroundColor Green
        Expand-Archive -LiteralPath $ENV:TEMP\SysInternalsSuite.zip -DestinationPath $env:temp\SysInternalsSuite -Force:$true -ErrorAction Stop
        Write-Host ("Extracting files to {0}\SysInternalsSuite" -f $env:temp) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error downloading/extracting the SysInternalsSuite, exiting...")
        return
    }

    # Loop through the files and only overwrite older versions and report updated programs on-screen. 
    # Additional files which were not present in the installation folder will be added
    $totalfiles = (Get-ChildItem -Path $env:temp\SysInternalsSuite).count
    $updated = 0
    foreach ($file in Get-ChildItem -Path $env:temp\SysInternalsSuite) {
        if ((Test-Path -Path "$($InstallPath)\$($file.Name)") -and (Test-Path -Path "$($env:temp)\SysInternalsSuite\$($file.name)")) {
            $currentversion = (Get-Item "$($InstallPath)\$($file.Name)").VersionInfo
            $downloadversion = (Get-Item "$($env:temp)\SysInternalsSuite\$($file.name)").VersionInfo
            if ($currentversion.ProductVersion -lt $downloadversion.ProductVersion) {
                try {
                    Copy-Item -LiteralPath "$($env:temp)\SysInternalsSuite\$($file.name)" -Destination "$($InstallPath)\$($file.Name)" -Force:$true -Confirm:$false -ErrorAction Stop
                    Write-Host ("- Updating {0} from version {1} to version {2}" -f $file.Name, $currentversion.ProductVersion, $downloadversion.ProductVersion) -ForegroundColor Green
                    ++$updated
                }
                catch {
                    Write-Warning ("Error overwriting {0}, please check permissions or perhaps the file is in use?" -f $file.name)
                }
            }
        }
        else {
            try {
                Copy-Item -LiteralPath "$($env:temp)\SysInternalsSuite\$($file.name)" -Destination "$($InstallPath)\$($file.Name)" -Force:$true -Confirm:$false -ErrorAction Stop
                Write-Host ("- Copying new file {0} to {1}" -f $file.Name, $InstallPath) -ForegroundColor Green
                ++$updated
            }
            catch {
                Write-Warning ("Error copying {0}, please check permissions" -f $file.name)
            }
        }
    }

    # Add installation folder to Path for easy access if not already present
    if ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path -split ';' -notcontains $InstallPath) { 
        Write-Host ("Adding {0} with the SysInternalsSuite to the System Path" -f $InstallPath) -ForegroundColor Green
        $OldPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
        $NewPath = $OldPath + ";$($InstallPath)"
        Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $NewPath
    }
    else {
        Write-Host ("The installation folder {0} is already present in the System Path, skipping adding it..." -f $InstallPath) -ForegroundColor Green
    }

    # Cleanup files
    if (Test-Path -Path $env:temp\SysInternalsSuite) {
        Write-Host ("Cleaning extracted version in {0}" -f $env:temp) -ForegroundColor Green
        Remove-Item -Path $env:temp\SysInternalsSuite -Force:$true -Confirm:$false -Recurse 
    }
    if (Test-Path -Path $env:temp\SysInternalsSuite.zip) {
        Write-Host ("Cleaning downloaded SysinternalsSuite.zip file in {0}" -f $env:temp) -ForegroundColor Green
        Remove-Item -Path $env:temp\SysInternalsSuite.zip -Force:$true -Confirm:$false
    }

    # Display totals and exit
    Write-Host ("Updated {0} files in {1} from the downloaded {2} files" -f $updated, $InstallPath, $totalfiles) -ForegroundColor Green
    return
}