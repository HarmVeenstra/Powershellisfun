param(
    [parameter(Mandatory = $true)][string]$OutputFileName
)

#Check if filename is correct
if (-not ($OutputFileName.EndsWith('.xlsx'))) {
    Write-Warning ("Specified filename {0} is not correct, should end with .xlsx. Exiting...")
    return
}

#Check access to the path, and if the file already exists, append if it does or test the creation of a new one
if (-not (Test-Path -Path $OutputFileName)) {
    try {
        New-Item -Path $OutputFileName -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
        Remove-Item -Path $OutputFileName -Force:$true -Confirm:$false | Out-Null
        Write-Host ("Specified {0} filename is correct, and the path is accessible, continuing..." -f $OutputFileName) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Path to specified {0} filename is not accessible, correct or file is in use, exiting..." -f $OutputFileName)
        return
    }
}
else {
    Write-Warning ("Specified file {0} already exists, appending data to it..." -f $OutputFileName)
}

#Check if necessary modules are installed, install missing modules if not
if (-not ((Get-Module Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement, ImportExcel, WindowsAutoPilotIntune -ListAvailable | Select-Object Name -Unique).count -eq 4)) {
    Write-Warning ("One or more required modules were not found, installing now...")
    try {
        Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Beta.DeviceManagement, ImportExcel, WindowsAutoPilotIntune -Confirm:$false -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
    }
    catch {
        Write-Warning ("Error installing required modules, exiting...")
        return
    }
}

#Connect MgGraph
try {
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
    Write-Host ("Connected to Microsoft Graph, continuing...") -ForegroundColor Green
} 
catch {
    Write-Warning ("Error connecting Microsoft Graph, check Permissions/Account. Exiting...")
    return
}

#Gather details for the report
try {
    $AutopilotDevices = Get-AutopilotDevice -ErrorAction Stop
    $AutopilotProfiles = Get-AutopilotProfile -ErrorAction Stop
    $AutoPilotSyncInfo = Get-AutopilotSyncInfo -ErrorAction Stop
    Write-Host ("Retrieved Autopilot information") -ForegroundColor Green
}
catch {
    Write-Warning ("Error retrieving data, check permissions. Exiting...")
    return
}

#Set dateformat for the Excel tabs
$date = Get-Date -Format ddMMyyhhmm

#AutopilotDevices
$total = foreach ($AutopilotDevice in $AutopilotDevices | Sort-Object serialNumber) {
    [PSCustomObject]@{
        DeviceId                               = $AutopilotDevice.azureActiveDirectoryDeviceId
        IntuneId                               = $AutopilotDevice.id
        GroupTag                               = if ($AutopilotDevice.groupTag) { 
            "$($AutopilotDevice.groupTag)" 
        }
        else { "None" }
        'Assigned user'                        = if ($AutopilotDevice.addressableUserName) { 
            "$($AutopilotDevice.addressableUserName)" 
        }
        else { "None" }
        'Last contacted'                       = if ($AutopilotDevice.lastContactedDateTime) {
            "$($AutopilotDevice.lastContactedDateTime)"
        }
        else {
            "Never"
        }
        'Profile status'                       = $AutopilotDevice.deploymentProfileAssignmentStatus
        'Profile assignment Date'              = $AutopilotDevice.deploymentProfileAssignedDateTime
        'Purchase order'                       = if ($AutopilotDevice.purchaseOrderIdentifier) {
            "$($AutopilotDevice.purchaseOrderIdentifier)"
        }
        else {
            "None"
        }
        'Remediation state'                    = $AutopilotDevice.remediationState
        'Remediation state last modified date' = $AutopilotDevice.remediationStateLastModifiedDateTime
        Manufacturer                           = $AutopilotDevice.manufacturer
        Model                                  = $AutopilotDevice.model
        Serialnumber                           = $AutopilotDevice.serialNumber
        'System family'                        = $AutopilotDevice.systemFamily
    }
}
try {
    $total | Export-Excel -Path $OutputFileName -WorksheetName "AutopilotDevices_$($date)" -AutoFilter -AutoSize -Append -ErrorAction Stop
    Write-Host ("Exported Autopilot Devices to {0}" -f $OutputFileName) -ForegroundColor Green
}
catch {
    Write-Warning ("Error exporting Autopilot Devices to {0}" -f $OutputFileName)
}

#Autopilotprofile
$total = foreach ($AutopilotProfile in $AutopilotProfiles) {
    [PSCustomObject]@{
        Name                                        = $AutopilotProfile.displayName
        Description                                 = if ($AutopilotProfile.description) {
            "$($AutopilotProfile.description)"
        }
        else {
            "None"
        }
        'Created on'                                = $AutopilotProfile.createdDateTime
        'Last modified on'                          = $AutopilotProfile.lastModifiedDateTime
        'Convert all targeted devices to Autopilot' = $AutopilotProfile.extractHardwareHash
        'Allow pre-provisioned deployment'          = $AutopilotProfile.enableWhiteGlove
        'Apply device name template'                = if ($AutopilotProfile.deviceNameTemplate) {
            "$($AutopilotProfile.deviceNameTemplate)"
        }
        else {
            "No"
        }
        'Automatically configure keyboard'          = $AutopilotProfile.outOfBoxExperienceSettings.skipKeyboardSelectionPage
        'Device Type'                               = $AutopilotProfile.deviceType
        'Hide Microsoft Software License Terms'     = $AutopilotProfile.outOfBoxExperienceSettings.hideEULA
        'Hide Privacy settings'                     = $AutopilotProfile.outOfBoxExperienceSettings.hidePrivacySettings
        'Language (Region)'                         = $AutopilotProfile.language
        'User account type'                         = $AutopilotProfile.outOfBoxExperienceSettings.userType
    }
}
try {
    $total | Export-Excel -Path $OutputFileName -WorksheetName "AutopilotProfiles_$($date)" -AutoFilter -AutoSize -Append
    Write-Host ("Exported Autopilot Profiles to {0}" -f $OutputFileName) -ForegroundColor Green
}
catch {
    Write-Warning ("Error exporting Autopilot Profiles to {0}" -f $OutputFileName)
}

#Autopilot Sync information
$total = [PSCustomObject]@{
    syncStatus              = $AutoPilotSyncInfo.syncStatus
    'Last sync time'        = $AutoPilotSyncInfo.lastSyncDateTime
    'Last manual sync time' = $AutoPilotSyncInfo.lastManualSyncTriggerDateTime
}
try {
    $total | Export-Excel -Path $OutputFileName -WorksheetName "AutopilotSyncInfo_$($date)" -AutoFilter -AutoSize -Append
    Write-Host ("Exported Autopilot Sync Information to {0}" -f $OutputFileName) -ForegroundColor Green
}
catch {
    Write-Warning ("Error exporting Autopilot Sync Information to {0}" -f $OutputFileName)
}

Write-Host ("`nDone!") -ForegroundColor Green