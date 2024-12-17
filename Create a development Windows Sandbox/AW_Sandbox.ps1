param(
    [parameter(Mandatory = $true)][string]$RecastComputerName,
    [parameter(Mandatory = $false)][string]$MappedFolder = 'C:\RecastSandbox',
    [parameter(Mandatory = $false)][string]$LogonCommand = 'Recast.ps1',
    [parameter(Mandatory = $false)][string]$Deployment = 'Sandbox'
)
 
#Check if Windows Sandbox is already running. Exit if yes
if (Get-Process -Name 'WindowsSandbox' -ErrorAction SilentlyContinue) {
    Write-Warning ("Windows Sandbox is already running, exiting...")
    return
}
 
#Validate if $mappedfolder exists, create the folder if it doesn't exist.
if ($MappedFolder) {
    if (Test-Path $MappedFolder -ErrorAction SilentlyContinue) {
        Write-Host ("Specified {0} folder exists, continuing..." -f $MappedFolder) -ForegroundColor Green
    }
    else {
        Write-Host ("Creating Specified Sandbox folder {0} now..." -f $MappedFolder) -ForegroundColor Green
        New-Item -Path $MappedFolder -ItemType Directory -Force:$true -Confirm:$false | Out-Null
    }
}
 
#Create .wsb config file, overwrite the existing file if present, and check if specified logoncommand exist
try {
    $wsblocation = "$($MappedFolder)\WindowsSandbox.wsb"
    Tee-Object -FilePath $wsblocation -Append:$false -ErrorAction Stop
    $wsb = @()
    $wsb += "<Configuration>"
    $wsb += "<MappedFolders>"
    $wsb += "<MappedFolder>"
    $wsb += "<HostFolder>$($MappedFolder)</HostFolder>"
    $wsb += "<ReadOnly>false</ReadOnly>"
    $wsb += "</MappedFolder>"
    $wsb += "</MappedFolders>"
    $LogonCommandFull = 'Powershell.exe -ExecutionPolicy bypass -File C:\users\wdagutilityaccount\desktop\' + $(Get-ChildItem -Path $($wsblocation) -Directory).Directory.Name + '\' + $logoncommand
    $wsb += "<LogonCommand>"
    $wsb += "<Command>$($LogonCommandFull)</Command>"
    $wsb += "</LogonCommand>"
    $wsb += "</Configuration>"
}
catch {
    Write-Warning ("Error creating {0}, check permissions. Exiting..." -f $wsblocation)
    return
}
 
#Copy Recast Agent.json and Agentregistration.cer to $mappedfolder and download bootstrapper, exit if not exist
if ((Test-Path -Path $env:ProgramData\Liquit\Agent\Agent.json) -and (Test-Path -Path $env:ProgramData\Liquit\Agent\AgentRegistration.cer)) {
    try {
        Copy-Item $env:ProgramData\Liquit\Agent\Agent.json -Destination $MappedFolder -Force:$true -Confirm:$false -ErrorAction Stop
        Copy-Item $env:ProgramData\Liquit\Agent\AgentRegistration.cer -Destination $MappedFolder -Force:$true -Confirm:$false -ErrorAction Stop
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest https://download.liquit.com/extra/Bootstrapper/AgentBootstrapper-Win-2.1.0.2.exe -UseBasicParsing -OutFile "$($MappedFolder)\AgentBootstrapper-Win.exe" -ErrorAction Stop
        $ProgressPreference = 'Continue'
    }
    catch {
        Write-Warning ("Error downloading or saving bootstrapper, check internet access! Exiting...")
        return
    }
}
else {
    Write-Warning ("No Recast Agent files found in {0}, these are required and exiting now..." -f "$($env:ProgramData)\Liquit\Agent")
    return
}
 
#Update Agent.json to point to Sandbox deployment (Default) or to the one specified manually using $deployment variable
$json = (Get-Content $MappedFolder\Agent.json -Raw) | ConvertFrom-Json
if ($json.deployment.autoStart.deployment -ne $Deployment) {
    try {
        $json.deployment.autoStart.deployment = $Deployment
        $json | ConvertTo-Json -Depth 10 | Out-File "$($MappedFolder)\Agent.json" -Force:$true -Encoding utf8 -Append:$false
    }
    catch {
        Write-Warning ("Error updating {0}, exiting..." -f "$($MappedFolder)\Agent.json")
        return
    }
}
 
#Create RecastComputerName.ps1 script, which will run when the Recast Sandbox starts and after every reboot (Add the rename to HKCU)
try {
    'Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$false -ErrorAction Stop
    'Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value "RecastComputerName"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
    'Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "RecastComputerRename" -value "LogonScript"' | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$true -ErrorAction Stop
}
catch {
    Write-Warning ("Error creating {0}, exiting..." -f "$($MappedFolder)\RecastComputerName.ps1")
    return
}
 
#Create Recast.ps1 script, which will install Recast agent in Windows Sandbox
#Transcript logging will be in either 'Processing.txt' or 'Done.txt' when done on the desktop
try {
    'Start-Transcript c:\users\wdagutilityaccount\desktop\Processing.txt' | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$false -ErrorAction Stop
    "Set-Location 'C:\users\wdagutilityaccount\desktop\{0}'" -f (Get-Item $MappedFolder).Name | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$true -ErrorAction Stop
    '.\RecastComputerName.ps1' | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$true -ErrorAction Stop
    'Start-Process -FilePath .\AgentBootstrapper-Win.exe -ArgumentList "/startDeployment /waitForDeployment /logPath=.\Install /certificate=.\AgentRegistration.cer" -Wait' | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$true -ErrorAction Stop
    'Stop-Transcript' | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$true -ErrorAction Stop
    'Rename-Item -Path c:\users\wdagutilityaccount\desktop\Processing.txt -NewName C:\users\wdagutilityaccount\desktop\Done.txt' | Out-File -FilePath "$($MappedFolder)\$($LogonCommand)" -Append:$true -ErrorAction Stop
}
catch {
    Write-Warning ("Error creating {0}, exiting..." -f "$($MappedFolder)\$($LogonCommand)")
    return
}
 
#Rename RecastComputerName to the value from $RecastComputerName in the RecastComputerName.ps1 script and save
try {
    $RecastScriptContents = Get-Content -Path "$($MappedFolder)\RecastComputerName.ps1" -ErrorAction Stop
    $RecastScriptContents = $RecastScriptContents -replace "RecastComputerName", "$($RecastComputerName)"
    $RecastScriptContents -replace "LogonScript", "Powershell.exe -ExecutionPolicy bypass -File C:\users\wdagutilityaccount\desktop\$($MappedFolder.Split(':\')[2])\RecastComputerName.ps1" | Out-File -FilePath "$($MappedFolder)\RecastComputerName.ps1" -Append:$false -ErrorAction Stop
}
catch {
    Write-Warning ("Error updating {0}, exiting..." -f "$($MappedFolder)\RecastComputerName.ps1")
    return
}
 
#Create sandbox .wsb file in $mappedfolder and start Windows Sandbox using it
try {
    $wsb | Out-File $wsblocation -Force:$true -ErrorAction Stop
    Write-Host ("Saved configuration in {0} and starting Windows Sandbox..." -f $wsblocation) -ForegroundColor Green
    Invoke-Item $wsblocation -ErrorAction Stop
    Write-Host ("Done!") -ForegroundColor Green
}
catch {
    Write-Warning ("Error starting Windows Sandbox, check permissions. Exiting")
    return
}
