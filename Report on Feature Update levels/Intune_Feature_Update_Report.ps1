# Check if PSResourceGet is available; install it if not, and check that the required modules are available, and install them if not
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet)) {
    try {
        Install-Module -Name Microsoft.PowerShell.PSResourceGet -Scope CurrentUser -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "Error installing PSResourceGet, exiting..."
        Write-Warning ("Error message:`n{0}" -f $_)
        return
    }
}

# Import Module PSResourceGet
try {
    Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop
}
catch {
    Write-Warning "Error importing PSResourceGet, exiting..."
    Write-Warning ("Error message:`n{0}" -f $_)
    return
}

# Check if the required Graph Modules are available, and install them if not
foreach ($Module in "Microsoft.Graph.Authentication", "Microsoft.Graph.DeviceManagement") {
    if (-not (Get-InstalledPSResource -Name $Module -ErrorAction SilentlyContinue)) {
        try {
            Install-PSResource -Name $Module -Scope CurrentUser -ErrorAction Stop
            Import-Module -Name $Module -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing and importing required Module {0}, exiting..." -f $Module)
            Write-Warning ("Error message: `n{0}" -f $_)
            return
        }
    }
    else {
        try {
            Import-Module -Name $Module -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error importing required Module {0}, exiting..." -f $Module)
            Write-Warning ("Error message: `n{0}" -f $_)
            return
        }
    }
}

# Connect to Graph with permissions to read devices and the tenant display name
# Check if already connected with the correct scopes, (re)connect if not
$Context = Get-MgContext
$DeviceScopes = @( 
    'DeviceManagementManagedDevices.Read.All' 
    'DeviceManagementManagedDevices.ReadWrite.All'
)
$OrganizationScope = 'Organization.Read.All'
$HasDeviceScope = @($Context.Scopes | Where-Object { $_ -in $DeviceScopes }).Count -gt 0
$HasOrganizationScope = $OrganizationScope -in $Context.Scopes
if (-not $Context -or -not $HasDeviceScope -or -not $HasOrganizationScope) {
    try {
        Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All', $OrganizationScope -NoWelcome -ErrorAction Stop
        $Context = Get-MgContext
    }
    catch {
        Write-Warning "Error connecting to Microsoft Graph, exiting..."
        Write-Warning ("Error message:`n{0}" -f $_)
        return
    }
}

# Retrieve Tenant information to show connecting user information
try {
    $Organization = Invoke-MgGraphRequest -Method GET -Uri ('/v1.0/organization/{0}?$select=displayName' -f $Context.TenantId) -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($Organization.displayName)) {
        throw "Microsoft Graph returned an empty Tenant display name."
    }
    Write-Output ("`n`nConnected to Microsoft Graph with account {0} from Tenant {1}, continuing..." -f $Context.Account, $Organization.displayName)
}
catch {
    Write-Warning "Error retrieving Tenant name, exiting..."
    Write-Warning ("Error message:`n{0}" -f $_)
    return
}

# Retrieve all Managed Windows Devices
try {
    $Devices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows' and managedDeviceOwnerType eq 'company'" -All -ErrorAction Stop
}
catch {
    Write-Warning ("Error retrieving devices, exiting...")
    Write-Warning ("Error message: `n{0}" -f $_)
    return
}

# Check Feature version based on Buildnumber and add to $Total
$Total = foreach ($Device in $Devices) {
    switch -Wildcard ($Device.OSVersion) {
        '10.0.10240.*' { $Version = 'Windows 10 1507' }
        '10.0.10586.*' { $Version = 'Windows 10 1511' }
        '10.0.14393.*' { $Version = 'Windows 10 1607' }
        '10.0.15063.*' { $Version = 'Windows 10 1703' }
        '10.0.16299.*' { $Version = 'Windows 10 1709' }
        '10.0.17134.*' { $Version = 'Windows 10 1803' }
        '10.0.17763.*' { $Version = 'Windows 10 1809' }
        '10.0.18362.*' { $Version = 'Windows 10 1903' }
        '10.0.18363.*' { $Version = 'Windows 10 1909' }
        '10.0.19041.*' { $Version = 'Windows 10 2004' }
        '10.0.19042.*' { $Version = 'Windows 10 20H2' }
        '10.0.19043.*' { $Version = 'Windows 10 21H1' }
        '10.0.19044.*' { $Version = 'Windows 10 21H2' }
        '10.0.19045.*' { $Version = 'Windows 10 22H2' }
        '10.0.22000.*' { $Version = 'Windows 11 21H2' }
        '10.0.22621.*' { $Version = 'Windows 11 22H2' }
        '10.0.22631.*' { $Version = 'Windows 11 23H2' }
        '10.0.26100.*' { $Version = 'Windows 11 24H2' }
        '10.0.26200.*' { $Version = 'Windows 11 25H2' }
        '10.0.28000.*' { $Version = 'Windows 11 26H1' }
        '10.0.26300.*' { $Version = 'Windows 11 26H2' }
        default { $Version = 'Unknown' }    
    }

    [PSCustomObject]@{
        Name                   = $Device.DeviceName
        Manufacturer           = $Device.Manufacturer
        Model                  = $Device.Model
        User                   = $Device.UserPrincipalName
        OperatingSystemVersion = $Device.OSVersion
        Version                = $Version
        LastSyncDateTime       = $Device.LastSyncDateTime
    }
}

# Output statistics if there are results saved to $Total
if ($null -ne $Total) {
    Write-Output ("Statistics for the Windows Managed Intune devices are:")
    $total | Group-Object Version | Select-Object Count, Name | Sort-Object Count

    # Copy data to clipboard in CSV format
    try {
        $Total | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Set-Clipboard -ErrorAction Stop
        Write-Output ("`nOutput saved to clipboard; paste in Excel for further analysis")
    }
    catch {
        Write-Warning ("Error copying results to clipboard, exiting...")
        Write-Warning ("Error message: `n{0}" -f $_)
        return
    }
}
else {
    Write-Warning ("No Company-Owned Windows Devices were found")
}