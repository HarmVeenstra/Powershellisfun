function Set-CorrectHyperVExternalSwitchAdapter {
    param (
        [parameter(Mandatory = $true)][string]$SwitchName
    )
    
    #retrieve external switch(es) and get Network adapter with Up state
    $externalswitch = Get-VMSwitch | Where-Object Name -eq $SwitchName
    $connectedadapter = Get-NetAdapter | Where-Object Status -eq Up | Sort-Object ifIndex | Select-Object -First 1

    #Set VMSwitch(es) properties so that the connected adapter is configured
    try {
        Set-VMSwitch $externalswitch.Name -NetAdapterName $connectedadapter.Name -ErrorAction Stop
        Write-Host ("Reconfiguring External Hyper-V Switch {0} to use Network Adapter {1}" -f $SwitchName, $connectedadapter.Name) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Failed reconfiguring External Hyper-V Switch {0} to use Network Adapter {1}" -f $SwitchName, $connectedadapter.Name)
    }
}