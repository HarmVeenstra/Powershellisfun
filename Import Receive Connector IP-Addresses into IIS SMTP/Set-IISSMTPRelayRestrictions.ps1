function Set-IISSMTPRelayRestrictions {
    param (
        [parameter(Mandatory = $true)][string]$CSVFile
    )
    
    #Check if CSV file is present and accessible
    try {
        $IPAddresses = Import-Csv -Path $CSVFile -Delimiter ';'
        write-host ("{0} found, continuing..." -f $CSVFile) -ForegroundColor Green
    }
    catch {
        Write-Warning ("{0} not found or not accessible, exiting..." -f $CSVFile)
        return
    }

    #Setting up variables needed
    $ipblock = @(24, 0, 0, 128,
        32, 0, 0, 128,
        60, 0, 0, 128,
        68, 0, 0, 128,
        1, 0, 0, 0,
        76, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 0, 0, 0,
        0, 0, 0, 0,
        2, 0, 0, 0,
        1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 76, 0, 0, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255)
    $ipList = @()
    $octet = @()

    #Loop through the list of Single IP-Adresses and add them to the Relay Restrictions
    foreach ($network in $IPAddresses | Where-Object RangeFormat -eq SingleAddress) {
        $ipList = $Network.Expression
        $octet += $ipList.Split(".")
        $ipblock[36] += 1
        $ipblock[44] += 1   
    }

    #Add the ip-adresses to the list
    $smtpserversetting = get-wmiobject -namespace root\MicrosoftIISv2 -computername localhost -Query "Select * from IIsSmtpServerSetting"
    $ipblock += $octet
    $smtpserversetting.RelayIpList = $ipblock
    $smtpserversetting.put()
    Write-Host ("Added the IP-Adresses to the Relay Restrictions list") -ForegroundColor Green

}