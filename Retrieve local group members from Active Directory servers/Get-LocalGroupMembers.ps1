function Get-LocalGroupMembers {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [parameter(Mandatory = $true)][string]$Outfile,
        [parameter(Mandatory = $false, parameterSetName = "ComputerNameFilter")][string]$ComputerNameFilter,
        [parameter(Mandatory = $false, parameterSetName = "OUFilter")][string]$OUfilter,
        [parameter(Mandatory = $false, parameterSetName = "FileName")][string]$FileName,
        [parameter(Mandatory = $false)][string[]]$GroupNameFilter
        
    )

    #Check file extension, if it's not .csv or .xlsx exit
    if (-not ($Outfile.ToLower().EndsWith('.csv') -or $Outfile.ToLower().EndsWith('.xlsx'))) {
        Write-Warning ("The specified {0} output file should use the .csv or .xlsx extension, exiting..." -f $Outfile)
        return
    }
    
    #Check is ActiveDirectory module is installed
    if (-not (Get-Module -ListAvailable | Where-Object Name -Match ActiveDirectory)) {
        Write-Warning ("ActiveDirectory PowerShell Module was not found, please install before running script...")
        return
    }

    #Retrieve all enabled computer accounts of Domain Member servers which updated their computer account the last 30 days, skip Domain Controllers
    #Skip checks if -FileName parameter was used
        
    #Using $ComputerNameFilter
    if ($ComputerNameFilter) {
        $servers = Get-ADComputer -Filter { (OperatingSystem -like 'Windows Server*') -and (PrimaryGroupID -ne '516') -and (Enabled -eq $TRUE) } -Properties LastLogonDate `
        | Where-Object Name -Match $ComputerNameFilter `
        | Where-Object LastLogonDate -GT (Get-Date).AddDays(-31) `
        | Sort-Object Name
    }

    #Using OUfilter
    if ($OUfilter) {
        $servers = Get-ADComputer -Filter { (OperatingSystem -like 'Windows Server*') -and (PrimaryGroupID -ne '516') -and (Enabled -eq $TRUE) } -Properties LastLogonDate `
        | Where-Object DistinguishedName -Match $OUfilter `
        | Where-Object LastLogonDate -GT (Get-Date).AddDays(-31) `
        | Sort-Object Name
    }

    #Without a Name or OU filter
    if (-not $OUfilter -and -not $ComputerNameFilter) {
        $servers = Get-ADComputer -Filter { (OperatingSystem -like 'Windows Server*') -and (PrimaryGroupID -ne '516') -and (Enabled -eq $TRUE) } -Properties LastLogonDate -ErrorAction Stop `
        | Where-Object LastLogonDate -GT (Get-Date).AddDays(-31) `
        | Sort-Object Name
    }
    
    #From specified filename
    if ($FileName) {
        try {
            $servers = Get-Content -Path $FileName -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error accessing/reading {0}. Exiting" -f $FileName)
            return
        }
    }

    #Exit if no computer accounts were found
    if ($servers.count -eq 0) {
        Write-Warning ("No Computer Accounts were found. Check access, filters or contents of file. Exiting...")
        return
    }

    $total = @()
    foreach ($server in $servers) {
        #Retrieve all local groups on the server and their members
        if (-not $FileName -and -not $GroupNameFilter) {
            try {
                $groupmembers = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $server.name -ErrorAction Stop | Where-Object GroupComponent -Match $server.Name
                Write-Host ("`nRetrieving local groups and their members on server {0}" -f $server.name) -ForegroundColor Green    
            }
            catch {
                Write-Warning ("Could not connect to {0}, skipping..." -f $server.Name)
                continue
            }
        }
        
        if ($FileName -and -not $GroupNameFilter) {
            try {
                $groupmembers = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $server -ErrorAction Stop | Where-Object GroupComponent -Match $server
                Write-Host ("`nRetrieving local groups and their members on server {0}" -f $server) -ForegroundColor Green    
            }
            catch {
                Write-Warning ("Could not connect to {0}, skipping..." -f $server)
                continue
            }
        }

        if ($FileName -and $GroupNameFilter) {
            Write-Host ("Retrieving members of the groups {0} on server {1}" -f "$($GroupNameFilter)", $server) -ForegroundColor Green
            foreach ($group in $GroupNameFilter) {
                try {
                    $groupmember = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $server -ErrorAction Stop | Where-Object { $_.GroupComponent -match $server -and $_.GroupComponent.Name -eq $group }    
                    $groupmembers += $groupmember
                }
                catch {
                    Write-Warning ("Could not connect to {0} or find group {1}, skipping..." -f $server, $group)
                    continue
                }
            }
        }

        if (-not $FileName -and $GroupNameFilter) {
            Write-Host ("Retrieving members of the groups {0} on server {1}" -f "$($GroupNameFilter)", $server.name) -ForegroundColor Green
            foreach ($group in $GroupNameFilter) {
                try {
                    $groupmember = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $server.name -ErrorAction Stop | Where-Object { $_.GroupComponent -match $server.Name -and $_.GroupComponent.Name -eq $group }    
                    $groupmembers += $groupmember
                }
                catch {
                    Write-Warning ("Could not connect to {0} or find group {1}, skipping..." -f $server.Name, $group)
                    continue
                }
            }
        }

        #Loop through all groupmembers and add them to the $total variable
        foreach ($member in $groupmembers) {
            Write-Host ("[{0}] Adding {1} from domain or server {2} which is member of the local group '{3}'" -f $member.PSComputerName, $member.PartComponent.Name, $member.PartComponent.Domain, $member.GroupComponent.Name) -ForegroundColor Green
            $members = [PSCustomObject]@{
                Server = $member.PSComputerName
                Group  = $member.GroupComponent.Name
                Domain = $member.PartComponent.Domain
                Member = $member.PartComponent.Name
            }
            $total += $members
        }
    }

    #Output to report is resuls where found
    if ($total.count -gt 0) {
        #Export results to either CSV of XLSX, install ImportExcel module if needed
        if ($Outfile.ToLower().EndsWith('.csv')) {
            try {
                $total | Sort-Object Server, Group, User | Export-Csv -Path $Outfile -Encoding UTF8 -Delimiter ';' -NoTypeInformation -ErrorAction Stop
                Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
                return
            }
        }

        if ($Outfile.ToLower().EndsWith('.xlsx')) {
            try {
                #Install ImportExcel module if needed
                if (-not (Get-Module -ListAvailable | Where-Object Name -Match ImportExcel)) {
                    Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                    Install-Module ImportExcel -Scope CurrentUser -Force:$true -ErrorAction Stop
                    Import-Module ImportExcel -ErrorAction Stop
                }

                $total | Sort-Object Server, Group, User | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $Outfile -Append:$false -ErrorAction Stop
                Write-Host ("`nExported results to {0}" -f $Outfile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $Outfile)
                return
            }
        }
    }
    else {
        Write-Warning ("Could not find any members, please check acces or filter...")
        return
    }
}