param(
    [parameter(Mandatory = $true)][string]$OutputFileName,
    [parameter(Mandatory = $false)][string]$Filter = ''
)

#Check if necessary modules are installed, install missing modules if not
foreach ($Module in 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Beta.DeviceManagement', 'Microsoft.Graph.Users') {
    if (-not (Get-Module -Name $Module -ListAvailable)) {
        Write-Warning ("{0} Module was not found, installing now..." -f $Module)
        try {
            Install-Module $Module -Confirm:$false -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing required module {0}, exiting..." -f $Module)
            return
        }
    }
}


#Connect MgGraph
try {
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All', 'User.Read.All' | Out-Null
} 
catch {
    Write-Warning ("Error connecting Microsoft Graph, check Permissions/Accounts. Exiting...")
    return
}

#Loop through the devices and the logged on users per device 
$total = foreach ($device in (Get-MgBetaDeviceManagementManagedDevice -All:$true -Filter "contains(DeviceName,'$($filter)')" | Where-Object OperatingSystem -EQ Windows)) {
    Write-Host ("Processing {0}..." -f $device.DeviceName) -ForegroundColor Green
    foreach ($user in $device.UsersLoggedOn.UserId | Select-Object -Unique  ) {
        [PSCustomObject]@{
            Device            = $device.DeviceName
            Model             = $device.Model
            SerialNumber      = $device.SerialNumber
            "Users logged in" = (Get-MgUser -UserId $user).DisplayName
            LastLogon         = ($device.UsersLoggedOn | Where-Object Userid -EQ $user | Sort-Object LastLogonDateTime | Select-Object -Last 1).LastLogOnDateTime
            PrimaryUser       = if ((Get-MgBetaDeviceManagementManagedDeviceUser -ManagedDeviceId $device.Id).DisplayName) {
                $((Get-MgBetaDeviceManagementManagedDeviceUser -ManagedDeviceId $device.Id).DisplayName)
            }
            else {
                "None"
            }
        }
    }
}
Disconnect-MgGraph | Out-Null

try {
    $total | Sort-Object Device, 'Users logged in' | Export-Csv -Path $OutputFileName -NoTypeInformation -Encoding UTF8 -Delimiter ';' -ErrorAction Stop
    Write-Host ("Exported results to {0}" -f $OutputFileName) -ForegroundColor Green
}
catch {
    Write-Warning ("Error saving results to {0}, check path/permissions..." -f $OutputFileName)
}
