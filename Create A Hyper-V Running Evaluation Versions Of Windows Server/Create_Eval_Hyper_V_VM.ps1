#Requires -RunAsAdministrator
 
#Start a stopwatch to measure the deployment time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
 
#Detect if Hyper-V is installed
if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online).State -ne 'Enabled') {
    Write-Warning ("Hyper-V Role and/or required PowerShell module is not installed, please install before running this script...")
}
else {
    Write-Host ("Hyper-V Role is installed, continuing...") -ForegroundColor Green
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
        Write-host ("Processing {0}, Found {1} Download(s)..." -f $url, $count) -ForegroundColor Green
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
        Write-Warning ("{0} is not accessible" -f $url)
        break
    }
}
 
#Select VHD from the list
$VHD = $totalfound | Out-GridView -OutputMode Single -Title 'Please select the VHD file to use and click OK' | Select-Object Name, Link
if (($VHD.Name).Count -ne '1') {
    Write-Warning ("No VHD file selected, script aborted...")
    break
}
 
#Set VM Parameters
$VMname = Read-Host 'Please enter the name of the VM to be created, for example W2K22SRV'
if ((Get-VM -Name $VMname -ErrorAction SilentlyContinue).count -ge 1) {
    Write-Warning ("{0} already exists on this system, aborting..." -f $VMname)
    break
} 
$VMCores = Read-Host 'Please enter the amount of cores, for example 2'
[int64]$VMRAM = 1GB * (read-host "Enter Maximum Memory in Gb's, for example 4")
$VMdir = (get-vmhost).VirtualMachinePath + $VMname
$SwitchName = Get-VMSwitch | Out-GridView -OutputMode Single -Title 'Please select the VM Switch and click OK' | Select-Object Name
if (($SwitchName.Name).Count -ne '1') {
    Write-Warning ("No Virtual Switch selected, script aborted...")
    break
}
 
#Create VM directory
try {
    New-Item -ItemType Directory -Path $VMdir -Force:$true -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Warning ("Couldn't create {0} folder, please check VM Name for illegal characters or permissions on folder..." -f $VMdir)
    break
}
finally {
    if (test-path -Path $VMdir -ErrorAction SilentlyContinue) { 
        Write-Host ("Using {0} as Virtual Machine location..." -f $VMdir) -ForegroundColor Green
    }
}
 
#Download VHD file to the VirtualMachinePath\VMname
write-host ("Downloading {0} to {1}..." -f $vhd.Name, $VMdir) -ForegroundColor Green
$VHDFile = "$($VMdir)\$($VMname)" + ".vhd"
$VMPath = (Get-VMHost).VirtualMachinePath + '\'
Invoke-WebRequest -Uri $vhd.Link -OutFile $VHDFile
 
#Create VM with the specified values
try {
    New-VM -Name $VMname -SwitchName $SwitchName.Name -Path $VMPath -Generation 1 -NoVHD:$true -Confirm:$false -ErrorAction Stop | Out-Null  
}
catch {
    Write-Warning ("Error creating {0}, please check logs and make sure {1} doesn't already exist..." -f $VMname, $VMname)
}
finally {
    if (Get-VM -Name $VMname -ErrorAction SilentlyContinue | Out-Null) {
        write-host ("Created {0}..." -f $VMname) -ForegroundColor Green
    }
}
 
#Configure settings on the VM, CPU/Memory/Disk/BootOrder
try {
    Write-Host ("Configuring settings on {0}..." -f $VMname) -ForegroundColor Green
    Set-VM -name $VMname -ProcessorCount $VMCores -DynamicMemory -MemoryMinimumBytes 64MB -MemoryMaximumBytes $VMRAM -MemoryStartupBytes 512MB  -ErrorAction SilentlyContinue | Out-Null 
    Add-VMHardDiskDrive -VMName $VMname -Path $VHDFile -ControllerType IDE -ErrorAction SilentlyContinue | Out-Null
}
catch {
    Write-Warning ("Error setting VM parameters, check {0} settings..." -f $VMname)
    break
}
 
#The end, stop stopwatch and display the time that it took to deploy
$stopwatch.Stop()
Write-Host ("Done, the deployment took {0} hours, {1} minutes and {2} seconds" -f $stopwatch.Elapsed.Hours, $stopwatch.Elapsed.Minutes, $stopwatch.Elapsed.Seconds) -ForegroundColor Green