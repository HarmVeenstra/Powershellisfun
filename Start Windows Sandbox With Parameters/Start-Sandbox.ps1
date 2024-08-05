#https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-configure-using-wsb-file
function Start-Sandbox {
    param(
        [parameter(Mandatory = $false)][string]$MappedFolder,
        [parameter(Mandatory = $false)][int]$MemoryInMB = '2048',
        [parameter(Mandatory = $false)][string]$LogonCommand,
        [switch]$vGPUdisable,
        [switch]$AudioInputDisable,
        [switch]$ClipboardRedirectionDisable,
        [switch]$MappedFolderWriteAccess,
        [switch]$NetworkingDisable,
        [switch]$PrinterRedirectionEnable,
        [switch]$ProtectedClientEnable,
        [switch]$VideoInputEnable
    )

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
    #Set Read-Only or Read-Write
    if ($MappedFolderWriteAccess) {
        $WriteAccess = 'false'
    }
    else {
        $WriteAccess = 'true'
    }
    #Create .wsb config file
    $wsb = @()
    $wsblocation = "$($env:Temp)\sandbox.wsb"
    $wsb += "<Configuration>"
    if ($vGPUdisable) {
        $wsb += "<VGpu>Disable</VGpu>"
    }

    if ($AudioInputDisable) {
        $wsb += "<AudioInput>Disable</AudioInput>"
    }

    if ($ClipboardRedirectionDisable) {
        $wsb += "<ClipboardRedirection>Disable</ClipboardRedirection>"
    }

    if ($MappedFolder) {
        $wsb += "<MappedFolders>"
        $wsb += "<MappedFolder>"
        $wsb += "<HostFolder>$($MappedFolder)</HostFolder>"
        $wsb += "<ReadOnly>$($WriteAccess)</ReadOnly>"
        $wsb += "</MappedFolder>"
        $wsb += "</MappedFolders>"
    }

    if ($null -ne $MemoryInMB) {
        $wsb += "<MemoryInMB>$($MemoryInMB)</MemoryInMB>"
        if ($MemoryInMB -lt 2048) {
            Write-Warning ("{0} Mb(s) specified, Windows Sandbox will automatically allocate more if needed..." -f $MemoryInMB)
        }
    }

    if ($NetworkingDisable) {
        $wsb += "<Networking>Disable</Networking>"
    }

    if ($LogonCommand) {
        $wsb += "<LogonCommand>"
        $wsb += "<Command>$($LogonCommand)</Command>"
        $wsb += "</LogonCommand>"
    }

    if ($PrinterRedirectionEnable) {
        $wsb += "<PrinterRedirection>Enable</PrinterRedirection>"
    }

    if ($ProtectedClientEnable) {
        $wsb += "<ProtectedClient>Enable</ProtectedClient>"
    }

    if ($VideoInputEnable) {
        $wsb += "<VideoInput>Enable</VideoInput>"
    }

    $wsb += "</Configuration>"
    
    #Create sandbox .wsb file in $env:\temp and start Windows Sandbox using it
    $wsb | Out-File $wsblocation -Force:$true
    Write-Host ("Starting Sandbox...") -ForegroundColor Green
    Invoke-Item $wsblocation
    #Wait for Windows Sandbox to start and delete the sandbox config file
    Start-Sleep -Seconds 5
    Remove-Item -Force:$true -Confirm:$false -Path $wsblocation
    Write-Host ("Done!") -ForegroundColor Green
}