function Convert-DTSlog {
    [CmdletBinding(DefaultParameterSetName = 'Outfile')]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the path to where the DTS logfile is located, e.g c:\temp\IN2403.log")][string]$DTSLogfile,
        [Parameter(Mandatory = $true, HelpMessage = "Enter the path to where the report should be saved, e.g c:\temp\NPS.XLS", parameterSetName = "Outfile")][string]$Outfile,
        [Parameter(Mandatory = $false, HelpMessage = "Output results in a gridview", parameterSetName = "GridView")][switch]$Gridview
    )
    
    #Test $DTSLogfile
    if (Test-Path -Path $DTSLogfile) {
        Write-Host ("The specified filename {0} is correct, continuing..." -f $DTSLogfile) -ForegroundColor Green
    }
    else {
        Write-Warning ("Specified file {0} cannot be found, exiting..." -f $DTSLogfile)
        return
    }

    #Check file extension, if it's not .csv or .xlsx exit
    if (-not ($Outfile.EndsWith('.csv') -or $Outfile.EndsWith('.xlsx'))) {
        Write-Warning ("The specified {0} output file should use the .csv or .xlsx extension, exiting..." -f $Outfile)
        return
    }

    #Get contents of the specified file
    Write-Host ("Reading log....") -ForegroundColor Green
    $logContents = Get-Content -Path $DTSLogfile

    #Set counters
    $count = 0
    $lines = $logContents.Count

    #Loop through all lines, complete data were possible using table
    #from https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771748(v=ws.10)?redirectedfrom=MSDN#entries-recorded-in-database-compatible-log-files
    $total = foreach ($line in $logContents) {
        $log = ([xml]$line).Event
        Write-Host ("`rProcessing event {0}/{1}" -f $count, $lines) -NoNewline -ForegroundColor Green
        [PSCustomObject]@{
            'NPS Server'                = $log.'Computer-Name'.'#text'
            'Packet-Type'               = switch ($log.'Packet-Type'.'#text') {
                1 { "Access-Request" }
                2 { "Access-Accept" }
                3 { "Access-Reject" }
                4 { "Accounting-Request" }
            }
            'Username'                  = $log.'Fully-Qualifed-User-Name'.'#text'
            'Client-Vendor'             = $log.'Client-Vendor'.'#text'
            'Client-IP-Address'         = $log.'Client-IP-Address'.'#text'
            'Client-Friendly-Name'      = $log.'Client-Friendly-Name'.'#text'
            'Event-Timestamp'           = $log.Timestamp.'#text'
            'Event-Authentication-Type' = switch ($log.'Authentication-Type'.'#text') {
                1 { "PAP" }
                2 { "CHAP" }
                3 { "MS-CHAP" }
                4 { "MS-CHAP v2" }
                5 { "EAP" }
                6 { "None" }
                8 { "Custom" }
            }
            'NP-Policy-Name'            = $log.'NP-Policy-Name'.'#text'
            'Reason-Code'               = switch ($log.'Reason-Code'.'#text') {
                0 { "IAS_SUCCESS" } 
                1 { "IAS_INTERNAL_ERROR" }
                2 { "IAS_ACCESS_DENIED" }
                3 { "IAS_MALFORMED_REQUEST" }
                4 { "IAS_GLOBAL_CATALOG_UNAVAILABLE" }
                5 { "IAS_DOMAIN_UNAVAILABLE" }
                6 { "IAS_SERVER_UNAVAILABLE" }
                7 { "IAS_NO_SUCH_DOMAIN" }
                8 { "IAS_NO_SUCH_USER" }
                16 { "IAS_AUTH_FAILURE" }
                17 { "IAS_CHANGE_PASSWORD_FAILURE" }
                18 { "IAS_UNSUPPORTED_AUTH_TYPE" }
                32 { "IAS_LOCAL_USERS_ONLY" }
                33 { "IAS_PASSWORD_MUST_CHANGE" }
                34 { "IAS_ACCOUNT_DISABLED" }
                35 { "IAS_ACCOUNT_EXPIRED" }
                36 { "IAS_ACCOUNT_LOCKED_OUT" }
                37 { "IAS_INVALID_LOGON_HOURS" }
                38 { "IAS_ACCOUNT_RESTRICTION" }
                48 { "IAS_NO_POLICY_MATCH" }
                64 { "IAS_DIALIN_LOCKED_OUT" }
                65 { "IAS_DIALIN_DISABLED" }
                66 { "IAS_INVALID_AUTH_TYPE" }
                67 { "IAS_INVALID_CALLING_STATION" }
                68 { "IAS_INVALID_DIALIN_HOURS" }
                69 { "IAS_INVALID_CALLED_STATION" }
                70 { "IAS_INVALID_PORT_TYPE" }
                71 { "IAS_INVALID_RESTRICTION" }
                80 { "IAS_NO_RECORD" }
                96 { "IAS_SESSION_TIMEOUT" }
                97 { "IAS_UNEXPECTED_REQUEST" }
            }
            'Session-Timeout'           = $log.'Session-Timeout'.'#text'
            'Acct-Session-ID'           = $log.'Acct-Session-Id'.'#text'
            'Proxy-Policy-Name'         = $log.'Proxy-Policy-Name'.'#text'
            'Provider-Type'             = switch ($log.'Provider-Type'.'#text') {
                0 { "No authentication occured" }
                1 { "Authentication occured on local NPS Server" }
                2 { "Connection request was forwarded to remote RADIUS server" }
            }
        }
        $count++
    }
    
    #Output to Out-GridView if specified
    if ($Gridview) {
        $total | Out-GridView
    } 

    #Export results to either CSV of XLSX, install ImportExcel module if needed
    if ($Outfile.EndsWith('.csv')) {
        try {
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            $total | Sort-Object Name, Property | Export-Csv -Path $Outfile -Encoding UTF8 -Delimiter ',' -NoTypeInformation
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }
    
    if ($Outfile.EndsWith('.xlsx')) {
        try {
            #Test path and remove empty file afterwards because xlsx is corrupted if not
            New-Item -Path $Outfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
            Remove-Item -Path $Outfile -Force:$true -Confirm:$false | Out-Null
            
            #Install ImportExcel module if needed
            write-host ("`nChecking if ImportExcel PowerShell module is installed...") -ForegroundColor Green
            if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                Install-Module ImportExcel -Scope CurrentUser -Force:$true
                Import-Module ImportExcel
            }
            #Export results to path
            $total | Sort-Object name, Property | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $Outfile -NoNumberConversion 'Client-IP-Address'
            Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
        }
        catch {
            Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
            return
        }
    }
}