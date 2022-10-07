#Set Logs folder
$logs = 'c:\scripts\logs'

#Create Logs folder it it doesn't exist
if (-not (Test-Path -Path $logs -PathType Any)) {
    New-Item -Path $logs -ItemType Directory | Out-Null
}

#Start Transcript logging to $logs\run.log
Start-Transcript -Path "$($logs)\run.log" -Append

#Configure groups to monitor
$admingroups = @(
    "Account Operators",
    "Administrators",
    "Backup Operators",
    "Domain Admins",
    "DNSAdmins",
    "Enterprise Admins",
    "Group Policy Creator Owners",
    "Schema Admins",
    "Server Operators"
)

#rename previous currentmembers.csv to previousmembers.csv and rename the old
#previousmembers.csv to one with a time-stamp for archiving
if (Test-Path -Path "$($logs)\previousmembers.csv" -ErrorAction SilentlyContinue) {
    #Set date format variable
    $date = Get-Date -Format 'dd-MM-yyyy-HHMM'
    Write-Host ("- Renaming previousmembers.csv to {0}_previousmembers.csv" -f $date) -ForegroundColor Green
    Move-Item -Path "$($logs)\previousmembers.csv" -Destination "$($logs)\$($date)_previousmembers.csv" -Confirm:$false -Force:$true
}

if (Test-Path -Path "$($logs)\currentmembers.csv" -ErrorAction SilentlyContinue) {
    Write-Host ("- Renaming currentmembers.csv to previousmembers.csv") -ForegroundColor Green
    Move-Item -Path "$($logs)\currentmembers.csv" -Destination "$($logs)\previousmembers.csv" -Confirm:$false -Force:$true
}

#Retrieve all direct members of the admingroups,
#store them in the members variable and output
#them to currentmembers.csv
$members = foreach ($admingroup in $admingroups) {
    Write-Host ("- Checking {0}" -f $admingroup) -ForegroundColor Green
    try {
        $admingroupmembers = Get-ADGroupMember -Identity $admingroup -Recursive -ErrorAction Stop | Sort-Object SamAccountName
    }
    catch {
        Write-Warning ("Members of {0} can't be retrieved, skipping..." -f $admingroup)
        $admingroupmembers = $null
    }
    if ($null -ne $admingroupmembers) {
        foreach ($admingroupmember in $admingroupmembers) {
            Write-Host ("  - Adding {0} to list" -f $admingroupmember.SamAccountName) -ForegroundColor Green
            [PSCustomObject]@{
                Group  = $admingroup
                Member = $admingroupmember.SamAccountName
            }
        }
    }
}

#Save found members to currentmembers.csv and create previousmembers.csv if not present (First Run)
Write-Host ("- Exporting results to currentmembers.csv") -ForegroundColor Green
$members | export-csv -Path "$($logs)\currentmembers.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ';'
if (-not (Test-Path "$($logs)\previousmembers.csv")) {
    $members | export-csv -Path "$($logs)\previousmembers.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ';'
}

#Compare currentmembers.csv to the #previousmembers.csv
$CurrentMembers = Import-Csv -Path "$($logs)\currentmembers.csv" -Delimiter ';'
$PreviousMembers = Import-Csv -Path "$($logs)\previousmembers.csv" -Delimiter ';'
Write-Host ("- Comparing current members to the previous members") -ForegroundColor Green
$compare = Compare-Object -ReferenceObject $PreviousMembers -DifferenceObject $CurrentMembers -Property Group, Member
if ($null -ne $compare) {
    $differencetotal = foreach ($change in $compare) {
        if ($change.SideIndicator -match ">") {
            $action = 'Added'
        }
        if ($change.SideIndicator -match "<") {
            $action = 'Removed'
        }

        [PSCustomObject]@{
            Date   = $date
            Group  = $change.Group
            Action = $action
            Member = $change.Member
        }
    }

    #Save output to file
    $differencetotal | Sort-Object group | Out-File "$($logs)\$($date)_changes.txt"

    #Send email with changes to admin email address
    Write-Host ("- Emailing detected changes") -ForegroundColor Green
    $body = Get-Content "$($logs)\$($date)_changes.txt" | Out-String
    $options = @{
        Body        = $body
        Erroraction = 'Stop'
        From        = 'admin@powershellisfun.com'
        Priority    = 'High'
        Subject     = "Admin group change detected"
        SmtpServer  = 'emailserver.domain.local'
        To          = 'harm@powershellisfun.com'     
    }
    
    try {
        Send-MailMessage @options
    }
    catch {
        Write-Warning ("- Error sending email, please check the email options")
    }
}
else {
    Write-Host ("No changes detected") -ForegroundColor Green
}

Stop-Transcript