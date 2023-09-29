#Requires -RunAsAdministrator
function Compact-VHDX {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the machine from which space of the VHDX(s) should be recovered")][string]$VMName
    )
      
    #Validate if hyper-v module is available, install when needed
    if (-not (Get-Module -listAvailable -Name Hyper-V)) {
        Write-Warning "Hyper-V module is not installed, installing now..."
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -NoRestart:$true
    }

    #Check if specified VMName is valid if specified
    if ($VMName) {
        if (-not (Hyper-V\Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
            Write-Warning ("Specified VM {0} was not found, aborting..." -f $VMName)
            return
        }
    }
    
    #Validate if the Virtual machine specified is running, abort if yes
    if ($VMName) {
        if ((Hyper-V\Get-VM -Name $VMName).State -eq 'Running') {
            Write-Warning ("Specified VM {0} is found but is running, please shutdown VM first. Aborting..." -f $VMName)
            return
        }
    }

    #Validate if Virtual machines are running when $VMName was not specified, abort if yes
    if (-not ($VMName)) {
        if (Hyper-V\Get-VM  | Where-Object State -eq Running) {
            Write-Warning ("Hyper-V VM(s) are running, aborting...")
            Write-Host ("Shutdown VM(s):") -ForegroundColor Red
            Hyper-V\Get-VM | Where-Object State -eq Running | Select-Object Name, State | Sort-Object Name | Format-Table
            return
        }
    }
    
    #Gather all VHDXs from the VMs (or VM is $VMName was specified which don't have a parent/snapshot
    if (-not ($VMName)) {
        $vhds = Hyper-V\Get-VM | Hyper-V\Get-VMHardDiskDrive | Where-Object Path -Match '.vhdx' | Sort-Object VMName, Path
    }
    else {
        $vhds = Hyper-V\Get-VM $VMName | Hyper-V\Get-VMHardDiskDrive | Where-Object Path -Match '.vhdx' | Sort-Object Path
    }

    if ($null -eq $vhds) {
        Write-Warning ("No disk(s) found without parent/snapshot configuration, aborting....")
    }

    #Gather current size of VHDX files
    $oldsize = foreach ($vhd in $vhds) {
        if ((Hyper-V\Get-VHD $vhd.path).VhdType -eq 'Dynamic') {
            [PSCustomObject]@{
                VHD     = $vhd.Path
                OldSize = [math]::round((Get-Item $vhd.Path).Length / 1GB, 3)
            }
        }
    }

    #Compress all files
    foreach ($vhd in $vhds) {
        if ((Hyper-V\Get-VHD  $vhd.path).VhdType -eq 'Dynamic') {
            Write-Host ("`nProcessing {0} from VM {1}..." -f $vhd.Path, $vhd.VMName) -ForegroundColor Gray
            try {
                Hyper-V\Mount-VHD -Path $vhd.Path -ReadOnly -ErrorAction Stop
                Write-Host "Mounting VHDX" -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error mounting {0}, please check access or if file is locked..." -f $vhd.Path )
                continue
            }

            try {
                Hyper-V\Optimize-VHD -Path $vhd.Path -Mode Full
                Write-Host ("Compacting VHDX") -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error compacting {0}, dismounting..." -f $vhd.Path)
                Hyper-V\Dismount-VHD $vhd.Path
                return
            }

            try { 
                Hyper-V\Dismount-VHD $vhd.Path -ErrorAction Stop
                Write-Host ("Dismounting VHDX`n") -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error dismounting {0}, please check Disk Management and manually dismount..." -f $vhd.Path)
                return
            }        
        }
    }

    #Report on new VHDX sizes
    $report = foreach ($vhd in $vhds) {
        if ((Hyper-V\Get-VHD  $vhd.path).VhdType -eq 'Dynamic') {
            [PSCustomObject]@{
                'Old Size (Gb))'       = ($oldsize | Where-Object VHD -eq $vhd.Path).OldSize
                'New Size (Gb)'        = [math]::round((Get-Item $vhd.Path).Length / 1GB, 3)
                'Space recovered (Gb)' = ($oldsize | Where-Object VHD -eq $vhd.Path).OldSize - [math]::round((Get-Item $vhd.Path).Length / 1GB, 3)
                VM                     = $vhd.VMName
                VHD                    = $vhd.Path
            }
        }
    }
    
    #Show overview
    if ($null -ne $report) {
        return $report | Format-Table -AutoSize
    }
    else {
        Write-Warning ("No dynamic disk(s) found to recover hard-disk space from, aborting....")
    }
}