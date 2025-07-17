function Get-MACIPVendor {
    [CmdletBinding(DefaultParameterSetName = 'IP')]
    param(
        [parameter(Mandatory = $true, ParameterSetName = 'MAC')][string]$MAC,
        [parameter(Mandatory = $true, ParameterSetName = 'IP')][ValidatePattern('^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')][string]$IP,
        [parameter(Mandatory = $false)][switch]$NMAP
    )

    #Replace : and . in MAC to - to have to Get-NetNeighbor format
    if ($MAC) {
        $MAC = $MAC.Replace(':.', '-')
    }

    #Retrieve MAC Address if $IP was used if possible, set it to "ZZ-ZZ-ZZ" if not. 
    #Ping IP first, so that it will be added to the ARP table
    if ($IP) {
        try {
            $ProgressPreference = 'SilentlyContinue'
            Test-NetConnection -ComputerName $IP -ErrorAction Stop -WarningAction SilentlyContinue -InformationLevel Quiet | Out-Null
            $MAC = (Get-NetNeighbor -IPAddress $IP -ErrorAction Stop | Where-Object LinkLayerAddress -NE '00-00-00-00-00-00').LinkLayerAddress
        }
        catch {
            Write-Warning ("The MAC address for specified IP {0} was not found / {0} couldn't be pinged" -f $IP)
            $MAC = "ZZ-ZZ-ZZ"
        }
    }

    if ($MAC -and -not $IP) {
        try {
            $IP = (Get-NetNeighbor | Where-Object { $_.LinkLayerAddress -match $MAC -and $_.AddressFamily -eq 'IPV4' -and $_.LinkLayerAddress -ne '00-00-00-00-00-00' }).IPAddress
        }
        catch {
            Write-Warning ("The specified MAC address {0} was not found in ARP table" -f $MAC)
        }
    }

    #Use the macvendors.com API for retrieving information
    #Warning: 1K request max per day without API key and 1 per second limit
    if ($MAC -ne 'ZZ-ZZ-ZZ') {
        try {
            $Vendor = Invoke-RestMethod -Uri "https://api.macvendors.com/$($MAC)" -ErrorAction Stop
        }
        catch {
            Write-Warning ("Could not find information for specified MAC {0} or api.macvendors.com is not accessible." -f $MAC)
        }
    }

    #Store information object in $Info    
    $Info = [PSCustomObject]@{
        MAC    = if ($MAC -ne 'ZZ-ZZ-ZZ') { $MAC } else { "Not found" }
        Vendor = if ($null -ne $Vendor) { $Vendor } else { "Not found" }
        IP     = if (Get-NetNeighbor -IPAddress $IP -ErrorAction SilentlyContinue) { (Get-NetNeighbor -IPAddress $IP | Where-Object LinkLayerAddress -NE '00-00-00-00-00-00').IPAddress } else { "Not found" }
    }
    $Info | Format-Table -AutoSize
    if ($NMAP) {
        if ($Info.IP -ne "Not found") {
            try {
                $NMAPINFO = & "C:\Program Files (x86)\Nmap\nmap.exe" $Info.IP
            }
            catch {
                Write-Warning ("NMAP.exe could not be started, is it installed on your system / in your PATH? https://nmap.org/download")
            }
        }
        else {
            Write-Warning ("No NMAP scan done because specified IP-Address was not found in network")
        }
        $NMAPINFO
    }

    Write-Host ("Done!") -ForegroundColor Green
}