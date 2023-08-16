#Requires -RunAsAdministrator

#ISO Paths
$ISOPath = 'D:\ISO'
$IntuneISO = 'D:\ISO\intune.iso'

#Start a stopwatch to measure the deployment time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#Detect if Hyper-V is installed
if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled') {
    Write-Warning ("Hyper-V Role and/or required PowerShell module is not installed, please install before running this script...")
}
else {
    Write-host ("Hyper-V Role is installed, continuing...") -ForegroundColor Green
}


#Set VM Parameters
$VMname = Read-Host 'Please enter the name of the VM to be created, for example W11Intune'
if ((Get-VM -Name $VMname -ErrorAction SilentlyContinue).count -ge 1) {
    Write-Warning ("VM {0} already exists on this system, aborting..." -f $VMname)
    return
}

$VMCores = Read-Host 'Please enter the amount of cores, for example 2'
[int64]$VMRAM = 1GB * (read-host "Enter Memory in Gb's, for example 4")
[int64]$VMDISK = 1GB * (read-host "Enter HDD size in Gb's, for example 40")
$VMdir = (get-vmhost).VirtualMachinePath + "\Virtual Machines\" + $VMname
$VMDiskDir = (get-vmhost).VirtualHardDiskPath

$ISO = Get-Childitem $ISOPath *.ISO | Out-GridView -OutputMode Single -Title 'Please select the ISO from the list and click OK'
if (($ISO.FullName).Count -ne '1') {
    Write-Warning ("No ISO, script aborted...")
    return
}

$SwitchName = Get-VMSwitch | Out-GridView -OutputMode Single -Title 'Please select the VM Switch and click OK' | Select-Object Name
if (($SwitchName.Name).Count -ne '1') {
    Write-Warning ("No Virtual Switch selected, script aborted...")
    return
}

#Create VM directory
try {
    New-Item -ItemType Directory -Path $VMdir -Force:$true -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Warning ("Couldn't create {0} folder, please check VM Name for illegal characters or permissions on folder..." -f $VMdir)
    return
}
finally {
    if (test-path -Path $VMdir -ErrorAction SilentlyContinue) {
        Write-Host ("Using {0} as Virtual Machine location..." -f $VMdir) -ForegroundColor Green
    }
}

#Create VM with the specified values
try {
    New-VM -Name $VMname `
    -SwitchName $SwitchName.Name `
    -Path $VMdir `
    -Generation 2 `
    -Confirm:$false `
    -NewVHDPath "$($VMDiskDir)\$($VMname).vhdx" `
    -NewVHDSizeBytes ([math]::Round($vmdisk * 1024) / 1KB) `
    -ErrorAction Stop `
    | Out-Null
}
catch {
    Write-Warning ("Error creating {0}, please check logs and make sure {0} doesn't already exist..." -f $VMname)
    return
}
finally {
    if (Get-VM -Name $VMname -ErrorAction SilentlyContinue | Out-Null) {
        write-host ("Created {0})..." -f $VMname) -ForegroundColor Green
    }
}

#Configure settings on the VM, CPU/Memory/Disk/BootOrder/TPM/Checkpoints
try {
    Write-Host ("Configuring settings on {0}..." -f $VMname) -ForegroundColor Green

    #VM Settings
    Set-VM -name $VMname `
        -ProcessorCount $VMCores `
        -StaticMemory `
        -MemoryStartupBytes $VMRAM `
        -CheckpointType ProductionOnly `
        -AutomaticCheckpointsEnabled:$false `
        -ErrorAction SilentlyContinue `
    | Out-Null

    #Add Harddisk
    Add-VMHardDiskDrive -VMName $VMname -Path "$($VMDiskDir)\$($VMname).vhdx" -ControllerType SCSI -ErrorAction SilentlyContinue | Out-Null

    #Add DVD with iso and set it as bootdevice
    Add-VMDvdDrive -VMName $VMName -Path $ISO.FullName -Passthru -ErrorAction SilentlyContinue | Out-Null
    $DVD = Get-VMDvdDrive -VMName $VMname
    $VMHD = Get-VMHardDiskDrive -VMName $VMname
    Set-VMFirmware -VMName $VMName -FirstBootDevice $VMHD
    Set-VMFirmware -VMName $VMName -FirstBootDevice $DVD
    Set-VMFirmware -VMName $VMname -EnableSecureBoot:On

    #Enable TPM
    Set-VMKeyProtector -VMName $VMname -NewLocalKeyProtector
    Enable-VMTPM -VMName $VMname

    #Enable all integration services
    Enable-VMIntegrationService -VMName $VMname -Name 'Guest Service Interface' , 'Heartbeat', 'Key-Value Pair Exchange', 'Shutdown', 'Time Synchronization', 'VSS'

}
catch {
    Write-Warning ("Error setting VM parameters, check settings of VM {0} ..." -f $VMname)
    return
}

#Start VM and wait until VM is at language selection screen
Write-Host ("Starting VM {0}, press Enter to continue when you are on the language selection screen after completing the inital setup steps. `nConnecting to console now...." -f $VMname) -ForegroundColor Green
Start-VM -VMName $VMname
vmconnect.exe localhost $VMName
Pause

#Add Intune ISO
Set-VMDvdDrive -VMName $VMname -Path $IntuneISO
Write-Host ("Press Shift-F10 on the console of VM {0}, switch to d:\ and run d:\autopilot.cmd to upload hardware hash to Intune. The VM will shutdown when done!" -f $VMname) -ForegroundColor Green
Write-Host ("Press Enter when the VM has shutdown to stop this script and disconnect the Intune ISO file from VM {0}" -f $VMname) -ForegroundColor Green
pause
Write-Host ("Ejecting Intune ISO file from VM {0}" -f $VMname) -ForegroundColor Green
Set-VMDvdDrive -VMName $VMname -Path $null

#The end, stop stopwatch and display the time that it took to deploy
$stopwatch.Stop()
Write-Host "Done, the deployment took $($stopwatch.Elapsed.Hours) hours, $($stopwatch.Elapsed.Minutes) minutes and $($stopwatch.Elapsed.Seconds) seconds" -ForegroundColor Green
