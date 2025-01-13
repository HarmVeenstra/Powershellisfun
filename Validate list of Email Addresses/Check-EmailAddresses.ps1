param (
    [Parameter(Mandatory = $false)][ValidateNotNull()][string]$DNSServer,
    [Parameter(Mandatory = $true)][ValidateNotNull()][string]$InputFile,
    [Parameter(Mandatory = $true)][ValidateNotNull()][string]$OutputFile
)

#Test if CSV Input File is valid
if ($InputFile) {
    If (Test-Path -Path $InputFile) {
        Write-Host ("Specified input file {0} is valid, continuing..." -f $InputFile) -ForegroundColor Green
    }
    else {
        Write-Warning ("Specified input file {0} is invalid, exiting..." -f $InputFile)
        return
    }
}

#Test if output file location is accessible
try {
    if (($OutputFile.EndsWith('.csv')) -or ($OutputFile.EndsWith('.xlsx'))) {
        New-Item -Path $OutputFile -Force -ErrorAction Stop | Out-Null
        Write-Host ("Specified output file location {0} is valid, continuing..." -f $OutputFile) -ForegroundColor Green
        Remove-Item -Path $OutputFile -Force -ErrorAction Stop | Out-Null
    }
    else {
        Write-Warning ("Specified output file location {0} has wrong extension, exiting..." -f $OutputFile)
        return
    }
}
catch {
    Write-Warning ("Specified output file location {0} is invalid or inaccessible, exiting..." -f $OutputFile)
    return
}

#Import emailaddresses from CSV or XLSX
if ($InputFile.EndsWith('.csv')) {
    try {
        $EmailAddresses = Import-Csv -Path $InputFile -ErrorAction Stop
        Write-Host ("Imported CSV file {0}" -f $InputFile) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error importing CSV file {0}, check formatting. Exiting...")
        return
    }
}

if ($InputFile.EndsWith('.xlsx')) {
    try {
        try {
            Import-Module 'ImportExcel' -ErrorAction Stop
        }
        catch {
            Write-Warning ("Required ImportExcel module is not installed, installing now...")
            try {
                Install-Module -Name ImportExcel -SkipPublisherCheck:$true -Force:$true -ErrorAction Stop
                Import-Module -Name ImportExcel
            }
            catch {
                Write-Warning ("Error installing required ImportExcel module, check permissions. Exiting...")
                return
            }
        }
    }
    finally {
        $EmailAddresses = Import-Excel -Path $InputFile -ErrorAction Stop
        Write-Host ("Imported Excel file {0}" -f $InputFile) -ForegroundColor Green
    }
}


#Continue if emailadresses were imported, and validate if formatted correctly and domain name is valid
#Skip already tested Domains and use $DNSServer is specified, it not the script will use your default DNS server.
if ($null -ne $EmailAddresses) {
    $Regex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    $ReachableEmailServers = @()
    $UnreachableEmailServers = @()
    $ProgressPreference = 'SilentlyContinue'
    $total = foreach ($EmailAddress in $EmailAddresses | Select-Object emailaddresses -Unique | Sort-Object emailaddresses) {
        if (($EmailAddress.emailaddresses -match $Regex) -eq $true) {
            Write-Host ("{0} is formatted correctly, checking email server...." -f $EmailAddress.emailaddresses) -ForegroundColor Green
            try {
                if ($DNSServer) {
                    $mx = (Resolve-DnsName -Name $EmailAddress.Emailaddresses.Split('@')[1] -Type MX -Server $DNSServer -ErrorAction Stop).NameExchange | Select-Object -First 1
                }
                else {
                    $mx = (Resolve-DnsName -Name $EmailAddress.Emailaddresses.Split('@')[1] -Type MX -ErrorAction Stop).NameExchange | Select-Object -First 1
                }
                if ($null -ne $mx) {
                    if (($mx -split ',')[0] -in $ReachableEmailServers) {
                        CorrectlyFormatted = 'True'
                        EmailAddress = $EmailAddress.Emailaddresses
                        EmailServer = ($mx -split ',')[0]
                        PingReply = 'True'
                        Valid = 'True'
                    }
                    if (($mx -split ',')[0] -in $UnreachableEmailServers) {
                        CorrectlyFormatted = 'True'
                        EmailAddress = $EmailAddress.Emailaddresses
                        EmailServer = ($mx -split ',')[0]
                        PingReply = 'False'
                        Valid = 'True'
                    }
                    if (($mx -split ',')[0] -notin $ReachableEmailServers -and ($mx -split ',')[0] -notin $UnreachableEmailServers ) {
                        [PSCustomObject]@{
                            CorrectlyFormatted = 'True'
                            EmailAddress       = $EmailAddress.Emailaddresses
                            EmailServer        = ($mx -split ',')[0]
                            PingReply          = if (Test-NetConnection $mx -InformationLevel Quiet) { "True" ; $ReachableEmailServers += $mx } else { "False" ; $UnreachableEmailServers += $mx }
                            Valid              = 'True'
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        CorrectlyFormatted = 'True'
                        EmailAddress       = $EmailAddress.Emailaddresses
                        EmailServer        = 'Not found'
                        PingReply          = 'False'
                        Valid              = 'False'
                    }
                }
            }
            catch {
                [PSCustomObject]@{
                    CorrectlyFormatted = 'True'
                    EmailAddress       = $EmailAddress.Emailaddresses
                    EmailServer        = 'Not found'
                    PingReply          = 'False'
                    Valid              = 'False'
                }
            }
        }
        else {
            Write-Warning ("{0} is formatted incorrectly" -f $EmailAddress.emailaddresses)
            [PSCustomObject]@{
                CorrectlyFormatted = 'False'
                EmailAddress       = $EmailAddress.Emailaddresses
                EmailServer        = 'Not found'
                PingReply          = 'False'
                Valid              = 'False'
            }
        }
    }

    #output results to selected $output location
    #CSV
    if ($OutputFile.EndsWith('.csv')) {
        try {
            $total | Export-Csv -Delimiter ';' -Encoding UTF8 -NoTypeInformation -Path $OutputFile -Force
            Write-Host ("Exported results to {0}" -f $OutputFile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Error exporting results to {0}, check permissions/is file open? Exiting..." -f $OutputFile)
            return
        }
    }

    #Excel
    if ($OutputFile.EndsWith('.xlsx')) {
        try {
            $total | Export-Excel -AutoSize -AutoFilter -Path $OutputFile -ErrorAction Stop
            Write-Host ("Exported results to {0}" -f $OutputFile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("Error exporting results to {0}, check permissions/is file open? Exiting..." -f $OutputFile)
            return
        }
    }
}
else {
    Write-Warning ("No email adresses were imported, check input file {0}. Exiting..." -f $InputFile)
    return
}