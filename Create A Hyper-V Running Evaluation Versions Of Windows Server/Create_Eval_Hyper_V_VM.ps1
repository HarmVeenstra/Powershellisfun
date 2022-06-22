#Requires -RunAsAdministrator
 
#Start a stopwatch to measure the deployment time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
 
#Detect if Hyper-V is installed
if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled') {
    Write-host 'Hyper-V Role and/or required PowerShell module is not installed, please install before running this script...' -ForegroundColor Red
}
else {
    Write-host 'Hyper-V Role is installed, continuing...' -ForegroundColor Green
}
 
#Retrieve all Server Operating System VHD links from the Microsoft Evaluation Center
$totalfound = @()
$totalcount = $null
 
$urls = @(
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019',
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022'
)
  
#Loop through the urls, search for VHD download links and add to totalfound array and display number of downloads
$ProgressPreference = "SilentlyContinue"
foreach ($url in $urls) {
    try {
        $content = Invoke-WebRequest -Uri $url -ErrorAction Stop
        $downloadlinks = $content.links | Where-Object { `
                $_.'aria-label' -match 'Download' `
                -and $_.'aria-label' -match 'VHD'
        }
        $count = $DownloadLinks.href.Count
        $totalcount += $count
        Write-host "Processing $($url), Found $($Count) Download(s)..." -ForegroundColor Green
        foreach ($DownloadLink in $DownloadLinks) {
            $found = [PSCustomObject]@{
                Title  = $content.ParsedHtml.title.Split('|')[0]
                Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
                Tag    = $DownloadLink.'data-bi-tags'.Split('"')[3].split('-')[0]
                Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
                Link   = $DownloadLink.href
            }
            $totalfound += $found
        }
    }
    catch {
        Write-host $url is not accessible -ForegroundColor Red
        break
    }
}
 
#Select VHD from the list
$VHD = $totalfound | Out-GridView -OutputMode Single -Title 'Please select the VHD file to use and click OK' | Select-Object Name, Link
if (($VHD.Name).Count -ne '1') {
    Write-host 'No VHD file selected, script aborted...' -ForegroundColor Red
    break
}
 
#Set VM Parameters
$VMname = Read-Host 'Please enter the name of the VM to be created, for example W2K22SRV'
if ((Get-VM -Name $VMname -ErrorAction SilentlyContinue).count -ge 1) {
    write-host "$($VMname) already exists on this system, aborting..." -ForegroundColor Red
    break
} 
$VMCores = Read-Host 'Please enter the amount of cores, for example 2'
[int64]$VMRAM = 1GB * (read-host "Enter Maximum Memory in Gb's, for example 4")
$VMdir = (get-vmhost).VirtualMachinePath + $VMname
$SwitchName = Get-VMSwitch | Out-GridView -OutputMode Single -Title 'Please select the VM Switch and click OK' | Select-Object Name
if (($SwitchName.Name).Count -ne '1') {
    Write-host 'No Virtual Switch selected, script aborted...' -ForegroundColor Red
    break
}
 
#Create VM directory
try {
    New-Item -ItemType Directory -Path $VMdir -Force:$true -ErrorAction SilentlyContinue | Out-Null
}
catch {
    write-host "Couldn't create $($VMdir) folder, please check VM Name for illegal characters or permissions on folder..." -ForegroundColor Red
    break
}
finally {
    if (test-path -Path $VMdir -ErrorAction SilentlyContinue) { 
        Write-Host "Using $($VMdir) as Virtual Machine location... " -ForegroundColor Green
    }
}
 
#Download VHD file to the VirtualMachinePath\VMname
write-host "Downloading $($vhd.Name) to $($VMdir)..." -ForegroundColor Green
$VHDFile = "$($VMdir)\$($VMname)" + ".vhd"
$VMPath = (Get-VMHost).VirtualMachinePath + '\'
Invoke-WebRequest -Uri $vhd.Link -OutFile $VHDFile
 
#Create VM with the specified values
try {
    New-VM -Name $VMname -SwitchName $SwitchName.Name -Path $VMPath -Generation 1 -NoVHD:$true -Confirm:$false -ErrorAction Stop | Out-Null  
}
catch {
    Write-Host "Error creating $($VMname), please check logs and make sure $($VMname) doesn't already exist..." -ForegroundColor Red
}
finally {
    if (Get-VM -Name $VMname -ErrorAction SilentlyContinue | Out-Null) {
        write-host "Created $($VMname)..." -ForegroundColor Green
    }
}
 
#Configure settings on the VM, CPU/Memory/Disk/BootOrder
try {
    Write-Host "Configuring settings on $($VMname)..." -ForegroundColor Green
    Set-VM -name $VMname -ProcessorCount $VMCores -DynamicMemory -MemoryMinimumBytes 64MB -MemoryMaximumBytes $VMRAM -MemoryStartupBytes 512MB  -ErrorAction SilentlyContinue | Out-Null 
    Add-VMHardDiskDrive -VMName $VMname -Path $VHDFile -ControllerType IDE -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Host "Error setting VM parameters, check $($VMname) settings..." -ForegroundColor Red
    break
}
 
#The end, stop stopwatch and display the time that it took to deploy
$stopwatch.Stop()
Write-Host "Done, the deployment took $($stopwatch.Elapsed.Hours) hours, $($stopwatch.Elapsed.Minutes) minutes and $($stopwatch.Elapsed.Seconds) seconds" -ForegroundColor Green