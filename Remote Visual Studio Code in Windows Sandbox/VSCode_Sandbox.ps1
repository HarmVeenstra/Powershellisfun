#Requires -RunAsAdministrator

# Check if Windows Sandbox is installed
try {
    Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Out-Null
    Write-Host ("Windows Sandbox Feature is installed, continuing...") -ForegroundColor Green
}
catch {
    Write-Warning ("Windows Sandbox Feature is not installed, exiting...")
    break
}

# Check if VSCode is installed, exit if not
if (code --help) {
    Write-Host ("Visual Studio Code is already installed, continuing...") -ForegroundColor Green
}
else {
    Write-Warning ("Visual Studio Code is not installed, exiting...")
    break
}

# Check if Remote-SSH extension is installed, install if not
if ((code --list-extensions | Select-String 'ms-vscode-remote.remote-ssh').Length -gt 0) {
    Write-Host ("Remote-SSH extension is already installed. Continuing...") -ForegroundColor Green
}
else {
    Write-Warning ("Remote-SSH extension is not installed. Installing now...")
    code --install-extension ms-vscode-remote.remote-ssh | Out-Null
}

# Create a C:\VSCodeSandbox folder if it does not exist
if (-not (Test-Path -Path C:\VSCodeSandbox)) {
    New-Item -Type Directory -Path C:\VSCodeSandbox -Force:$true -Confirm:$false | Out-Null
    Write-Host ("Created C:\VSCodeSandbox folder") -ForegroundColor Green
}
else {
    Write-Host ("Folder C:\VSCodeSandbox already exists, continuing...") -ForegroundColor Green
}

# Install OpenSSH Client if needed
if (-not (Test-Path -Path C:\Windows\System32\OpenSSH\ssh-keygen.exe)) {
    Add-WindowsCapability -Online -Name OpenSSH.Client* -ErrorAction Stop
    Get-Service ssh-agent | Set-Service -StartupType Automatic
    Start-Service ssh-agent
    Write-Host ("Installing OpenSSH client...") -ForegroundColor Green
}
else {
    Write-Host ("OpenSSH client found, continuing...") -ForegroundColor Green
}

# Create SSH keys for connecting to Windows Sandbox
if (-not (Test-Path -Path $env:USERPROFILE\.ssh\vscodesshfile*)) {
    try {
        if (-not (Test-Path -Path $env:USERPROFILE\.ssh)) {
            New-Item -ItemType Directory -Path $env:USERPROFILE\.ssh | Out-Null
        }
        C:\Windows\System32\OpenSSH\ssh-keygen.exe -t ed25519 -f $env:USERPROFILE\.ssh\vscodesshfile -q -N """"
        Get-Service ssh-agent | Set-Service -StartupType Automatic
        Start-Service ssh-agent
        C:\Windows\System32\OpenSSH\ssh-add.exe $env:USERPROFILE\.ssh\vscodesshfile *> $null
        Copy-Item $env:USERPROFILE\.ssh\vscodesshfile.pub C:\VSCodeSandbox -Force:$true -Confirm:$false
        Write-Host ("Creating SSH Keys, importing private key and copying .pub file to C:\VSCodeSandbox...") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error Creating SSH keys, check logs. Exiting...")
        break
    }
}
else {
    Write-Host ("SSH keys found, continuing...") -ForegroundColor Green
}

# Remove previous ip.txt
if (Test-Path -Path C:\VSCodeSandbox\IP.txt) {
    Remove-Item -Path C:\VSCodeSandbox\IP.txt -Force:$true -Confirm:$false
}

# Create a VSCode.wsb file in C:\Windows\Temp\VSCodeSandbox
$wsb = @"
<Configuration>
    <VGpu>Enable</VGpu>
    <Networking>Enable</Networking>
    <MappedFolders>
        <MappedFolder>
              <HostFolder>C:\VSCodeSandbox</HostFolder>
              <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
    <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -sta -WindowStyle Hidden -noprofile -executionpolicy unrestricted -file "C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox\vscode_sandbox.ps1" </Command>
    </LogonCommand>
</Configuration>
"@
$wsb | Out-File C:\VSCodeSandbox\vscode.wsb -Force:$true -Confirm:$false

# Create the vscode_sandbox.ps1 for installation of OpenSSH Server, creation of local vscode admin account and vscodesshfile SSH Key
# Logging can be found in C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox\sandbox_transcript.txt if needed in the Windows Sandbox VM
$vscode_sandbox = @"
Start-Transcript C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox\sandbox_transcript.txt
Invoke-Webrequest -Uri https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64-v9.2.2.0.msi -OutFile C:\Windows\Temp\OpenSSH-Win64.msi
msiexec.exe /i C:\Windows\Temp\OpenSSH-Win64.msi /qn
New-LocalUser -Name vscode -Password ("vscode" | ConvertTo-SecureString -AsPlainText -Force)
Add-LocalGroupMember -Group Administrators -Member vscode
if (-not (Test-Path C:\ProgramData\ssh)) {New-Item -Type Directory -Path C:\ProgramData\ssh}
Copy-Item C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox\vscodesshfile.pub C:\ProgramData\ssh\administrators_authorized_keys
(Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4).IPAddress | Out-File C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox\IP.txt -Force
Stop-Transcript
"@
$vscode_sandbox | Out-File C:\VSCodeSandbox\vscode_sandbox.ps1 -Force:$true -Confirm:$false

# Start Windows Sandbox using the VSCode.wsb file
Write-Host ("Starting Windows Sandbox...") -ForegroundColor Green
C:\VSCodeSandbox\vscode.wsb

# Wait for installation of OpenSSH server and creation of IP.txt
while (-not (Test-Path -Path C:\VSCodeSandbox\IP.txt)) {
    Write-Host ("Waiting for installation of OpenSSH in Windows Sandbox...") -ForegroundColor Green
    Start-Sleep 10
}
Write-Host ("Installation done, continuing...") -ForegroundColor Green

# Start new VSCode session to Sandbox using SSH key, retrieve current IP of Sandbox from C:\VSCodeSandbox\IP.txt for connection
$ip = get-content C:\VSCodeSandbox\IP.txt
Write-Host ("Starting Visual Studio Code and connecting to Windows Sandbox...") -ForegroundColor Green
code --remote ssh-remote+vscode@$($ip) C:\Users\WDAGUtilityAccount\Desktop\VSCodeSandbox