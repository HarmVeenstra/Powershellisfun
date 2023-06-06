#Parameter usage:
# -All changes all configured profiles except the Default Profile
# -DefaultProfile changes the Default Profile settings. Every new profile will inherit the wallpaper setting from it
# -Profiles can be used for specifying one or multiple profiles separated by ','. Example Set-WindowsTerminalBackgroundImage "PowerShell 5" or Set-WindowsTerminalBackgroundImage "PowerShell 5", "Azure Cloud Shell"

[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'All')]
    [Switch]$All,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'DefaultProfile')]
    [Switch]$DefaultProfile,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Profiles')]
    [String[]]$Profiles,
       
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DefaultProfile')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Profiles')]
    [String]$RandomBackgroundFolder,
    
    [Parameter(Mandatory = $false, ParameterSetName = 'All')]
    [Parameter(Mandatory = $false, ParameterSetName = 'DefaultProfile')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Profiles')]
    [String]$BackgroundPath
)

#Check if RandomWallpaperFolder and WallpaperPath were used at the same time. Exit if they were
if ($RandomBackgroundFolder -and $BackgroundPath) {
    Write-Warning ("RandomBackgroundFolder and BackgroundPath parameters can't be used both, Set-WindowsTerminalBackgroundImage is exiting")
    break
}

#Check $BackgroundPath location
if ($BackgroundPath) {
    if (-not (Get-ChildItem -Path $BackgroundPath -ErrorAction SilentlyContinue | where-object Extension -In '.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.ico')) {
        Write-Warning ("Specified Wallpaper {0} has no .jpg, .jpeg, .png, .bmp, .gif, .tiff, .ico extension, check spelling or permissions. Set-WindowsTerminalBackgroundImage is exiting..." -f $BackgroundPath)
        break
    }
}

#Check $RandomBackgroundFolder for files (≥ 1) and set $BackgroundPath to random wallpaper
if ($RandomBackgroundFolder) {
    if (-not ((Get-ChildItem -Path $RandomBackgroundFolder -Include *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico -Recurse -ErrorAction SilentlyContinue).count -ge 1 )) {
        Write-Warning ("No Wallpapers found in {0}. (Searched for *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico files). Set-WindowsTerminalBackgroundImage is exiting..." -f $RandomBackgroundFolder)
        break
    }
    else {
        Write-Host ("{0} Wallpapers were found in {1}, continuing... " -f (Get-ChildItem -Path $RandomBackgroundFolder -Include *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico -Recurse).count, $RandomBackgroundFolder) -ForegroundColor Green
    }
}
    
#Retrieve Settings.json location
try {
    $json = Get-Content $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\Settings.json -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Warning ("Windows Terminal Settings.json was not found. Is Windows Terminal installed? Check permissions if it is, Set-WindowsTerminalBackgroundImage is exiting...")
    break
}

#Loop through all specified Profiles in $profiles and change the wallpaper to the one specified in $BackgroundPath or random one from $RandomBackgroundFolder
#Check if the profile exists and skip if not found
if ($Profiles) {
    foreach ($Profile in $Profiles) {
        if ($profilesettings = $json.profiles.list | Where-Object name -eq $profile -ErrorAction Stop) {
            if ($RandomBackgroundFolder) {
                $BackgroundPath = (Get-ChildItem -Path $RandomBackgroundFolder -Include *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico -Recurse | Get-Random).Fullname
            }
            $profilesettings | Add-Member -NotePropertyName 'backgroundImage' -NotePropertyValue $BackgroundPath -Force:$true
            Write-Host ("Changing Wallpaper for Profile {0} to {1}" -f $Profile, $BackgroundPath) -ForegroundColor Green
        }
        else {
            Write-Warning ("Specified Profile {0} was not found, Set-WindowsTerminalBackgroundImage is skipping profile..." -f $Profile)
        }
    }
}

#Loop through all Profiles in and change the wallpaper to the one specified in $BackgroundPath or the random one from $RandomBackgroundFolder
if ($All) {
    foreach ($Profile in $json.profiles.list) {
        $profilesettings = $json.profiles.list | Where-Object name -eq $profile.name -ErrorAction Stop
        if ($RandomBackgroundFolder) {
            $BackgroundPath = (Get-ChildItem -Path $RandomBackgroundFolder -Include *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico -Recurse | Get-Random).Fullname
        }
        $profilesettings | Add-Member -NotePropertyName 'backgroundImage' -NotePropertyValue $BackgroundPath -Force:$true
        Write-Host ("Changing Wallpaper for Profile {0} to {1}" -f $Profile.name, $BackgroundPath) -ForegroundColor Green
    }
}

#Change the wallpaper for the Default Profile to the one specified in $BackgroundPath or the random one from $RandomBackgroundFolder
if ($DefaultProfile) {
    if ($RandomBackgroundFolder) {
        $BackgroundPath = (Get-ChildItem -Path $RandomBackgroundFolder -Include *.jpg, *.jpeg, *.png, *.bmp, *.gif, *.tiff, *.ico -Recurse | Get-Random).Fullname
    }
    $json.profiles.defaults | Add-Member -NotePropertyName 'backgroundImage' -NotePropertyValue $BackgroundPath -Force:$true
    Write-Host ("Changing Wallpaper for Default Profile to {0}" -f $BackgroundPath) -ForegroundColor Green
}

#Save modified Settings.json, overwriting the existing one
try {
    $json | ConvertTo-Json -Depth 10 | Out-File $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\Settings.json -Force -Encoding utf8
}
catch {
    Write-Warning ("Error saving {0}, check permissions..." -f "$($env:LOCALAPPDATA)\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\Settings.json")
}