#Requires -RunAsAdministrator
#Retrieve all adapters which have a Up status
$adapters = Get-NetAdapter | Where-Object Status -eq 'Up'

#Set primary and secondary DNS Servers variables
$primary = '10.0.0.4'
$secondary = '10.0.0.5' 

#Loop through all adapters and configure $primary and $secondary for all adapters which have a DNS Server setting
foreach ($adapter in $adapters) {
    if (Get-DnsClientServerAddress | Where-Object InterfaceIndex -eq $adapter.InterfaceIndex) {
        try {
            $dnsservers = (Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction Stop).DNSServer.ServerAddresses
            Write-Host ("Retrieved DNS settings for adapter {0} on {1}" -f $adapter.Name, $env:COMPUTERNAME)
        }
        catch {
            Write-Warning ("Could not retrieve DNS settings for adapter {0} on {1}" -f $adapter.Name, $env:COMPUTERNAME)
        }
    
        if ($dnsservers -notcontains $primary -or $dnsservers -notcontains $secondary) {
            try {
                Set-DNSClientServerAddress -ServerAddresses ($primary, $secondary) -InterfaceIndex $adapter.ifIndex -ErrorAction Stop
                Write-Host ("Changing DNS settings for {0} to {1} and {2} (Previous setting was {3}) on {4}" -f $adapter.Name, $primary, $secondary, $($dnsservers -join ', '), $env:COMPUTERNAME) -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error changing {0} on {1}" -f $adapter.Name, $env:COMPUTERNAME)
            }
        }
        else {
            Write-Host ("Adapter {0} already has {1} and {2} configured on {3}, skipping..." -f $adapter.Name, $primary, $secondary, $env:COMPUTERNAME)
        }
    }
}