#Requires -RunAsAdministrator
function Compact-VHDX {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the machine(s) from which space of the VHDX(s) should be recovered")][string[]]$VMName
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
        foreach ($vm in $VMName) {
            if ((Hyper-V\Get-VM -Name $VM).State -eq 'Running') {
                Write-Warning ("One or more of the specified VM(s) {0} were found but are running, please shutdown VM(s) first. Aborting..." -f $VM)
                return
            }
        }
    }
    
    #Gather all VHDXs from the VMs (or VM is $VMName was specified which don't have a parent/snapshot
    if (-not ($VMName)) {
        $vhds = Hyper-V\Get-VM | Hyper-V\Get-VMHardDiskDrive | Where-Object Path -Like '*.vhdx' | Sort-Object VMName, Path
    }
    else {
        $vhds = Hyper-V\Get-VM $VMName | Hyper-V\Get-VMHardDiskDrive | Where-Object Path -Like '*.vhdx' | Sort-Object Path
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
        if (-not (Hyper-V\Get-VM $vhd.VMName  | Where-Object State -eq Running)) {
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
        else {
            Write-Warning ("VM {0} is Running, skipping..." -f $vhd.VMName)
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