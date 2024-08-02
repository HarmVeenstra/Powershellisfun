param(
    [parameter(Mandatory = $false)][string]$MappedFolder = 'C:\WindowsSandbox',
    [parameter(Mandatory = $false)][string]$LogonCommand = 'Install_WinGet_and_Software.ps1'
)

#Check if Windows Sandbox is already running. Exit if yes
if (Get-Process -Name 'WindowsSandbox' -ErrorAction SilentlyContinue) {
    Write-Warning ("Windows Sandbox is already running, exiting...")
    return
}

#Validate if $mappedfolder exists
if ($MappedFolder) {
    if (Test-Path $MappedFolder -ErrorAction SilentlyContinue) {
        Write-Host ("Specified {0} path exists, continuing..." -f $MappedFolder) -ForegroundColor Green
    }
    else {
        Write-Warning ("Specified {0} path doesn't exist, exiting..." -f $MappedFolder)
        return
    }
}

#Create .wsb config file, overwrite  existing file if present and check if specified logoncommand exist
$wsblocation = "$($MappedFolder)\WindowsSandbox.wsb"
if (-not (Test-Path "$($MappedFolder)\$($LogonCommand)")) {
    Write-Warning ("Specified LogonCommand {0} doesn't exist in {1}, exiting..." -f $MappedFolder, $LogonCommand)
    return
}

Tee-Object -FilePath $wsblocation -Append:$false

$wsb = @()
$wsb += "<Configuration>"
$wsb += "<MappedFolders>"
$wsb += "<MappedFolder>"
$wsb += "<HostFolder>$($MappedFolder)</HostFolder>"
$wsb += "<ReadOnly>true</ReadOnly>"
$wsb += "</MappedFolder>"
$wsb += "</MappedFolders>"

$LogonCommandFull = 'Powershell.exe -ExecutionPolicy bypass -File C:\users\wdagutilityaccount\desktop\' + $(Get-childitem -Path $($wsblocation) -Directory).Directory.Name + '\' + $logoncommand
$wsb += "<LogonCommand>"
$wsb += "<Command>$($LogonCommandFull)</Command>"
$wsb += "</LogonCommand>"

$wsb += "</Configuration>"
    
#Create sandbox .wsb file in $mappedfolder and start Windows Sandbox using it
$wsb | Out-File $wsblocation -Force:$true
Write-Host ("Saved configuration in {0} and Starting Windows Sandbox..." -f $wsblocation) -ForegroundColor Green
Invoke-Item $wsblocation

Write-Host ("Done!") -ForegroundColor Green