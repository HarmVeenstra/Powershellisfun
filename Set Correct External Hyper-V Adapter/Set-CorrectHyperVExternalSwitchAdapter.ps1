function Set-CorrectHyperVExternalSwitchAdapter {
    param (
        [parameter(Mandatory = $true)][string]$SwitchName
    )
    
    #Validate SwitchName
    if (-not (Get-VMSwitch -Name $SwitchName | Where-Object { $_.SwitchType -eq 'External' -and $_.AllowManagementOS -eq $True })) {
        Write-Warning ("External Hyper-V Switch {0} can't be found or has no 'Allow management operating system to share this network adapter' enabled, exiting..." -f $SwitchName)
        return
    }

    #retrieve external switch(es) with Allow Management OS on and get Network adapter with Up state
    $externalswitch = Get-VMSwitch | Where-Object { $_.Name -eq $SwitchName -and $_.SwitchType -eq 'External' -and $_.AllowManagementOS -eq $True }
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