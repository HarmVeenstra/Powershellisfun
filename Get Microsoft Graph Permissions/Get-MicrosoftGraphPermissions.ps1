function Get-MicrosoftGraphPermissions {
    param (
        [parameter(Mandatory = $false, ParameterSetName = 'All')][switch]$All,    
        [Parameter(Mandatory = $false, ParameterSetName = 'Cmdlet')][String[]]$Cmdlet,
        [Parameter(Mandatory = $false)][string]$Filename,
        [Parameter(Mandatory = $false, ParameterSetName = 'Module')][String[]]$Module,
        [Parameter(Mandatory = $false)][validateset('Console', 'ConsoleGridView', 'GridView')][string]$Output = 'Console'
    )

    #Check if required modules are installed for when using ConsoleGridView or XLSX
    if ($Output -eq 'ConsoleGridView') {
        if ($host.Version.Major -eq 7) {
            if (-not (Get-Module Microsoft.PowerShell.ConsoleGuiTools -ListAvailable)) {
                try {
                    Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -ErrorAction Stop
                    Import-Module Microsoft.PowerShell.ConsoleGuiTools -ErrorAction Stop
                    Write-Host ('Installed missing PowerShell Module Microsoft.PowerShell.ConsoleGuiTools which is needed for ConsoleGridView output') -ForegroundColor Green
                }
                catch {
                    Write-Warning ('Could not install missing PowerShell Module Microsoft.PowerShell.ConsoleGuiTools which is needed for ConsoleGridView output, exiting...')
                    return
                }
            }
        }
        else {
            Write-Warning ('The ConsoleGridView parameter only works on PowerShell v7, version {0} was found. Exiting...' -f $host.Version.Major)
            return
        }
    }

    #Build list of cmdlet(s) or all Microsoft Graph cmdlets to query
    if ($all) {
        $cmdlets = foreach ($item in (Get-Module Microsoft.Graph* -ListAvailable | Where-Object ModuleType -NE Manifest).ExportedCommands.Values) {
            [PSCustomObject]@{
                'Name'                   = $item.Name
                'PowerShell Module Name' = $item.Source
                'Version'                = $item.Version
            }
        }
        if ($null -eq $cmdlets) {
            Write-Warning ('No Microsoft Graph Modules were not found, exiting...')
            return
        }
    }

    if ($Cmdlet -and -not $all) {
        try {
            $cmdlets = foreach ($item in Get-Command $cmdlet -ErrorAction Stop) {
                [PSCustomObject]@{
                    'Name'                   = $item.Name
                    'PowerShell Module Name' = $item.Source
                    'Version'                = $item.Version
                }
            }
        }
        catch {
            Write-Warning ('One or more specified Cmdlets are not found, exiting...')
            return
        }
    }

    if ($Module) {
        if (Get-Module $Module -ListAvailable) {
            $cmdlets = foreach ($item in (Get-Module $Module -ListAvailable | Where-Object ModuleType -NE Manifest).ExportedCommands.Values) {
                [PSCustomObject]@{
                    'Name'                   = $item.Name
                    'PowerShell Module Name' = $item.Source
                    'Version'                = $item.Version
                }
            }    
        }
        else {
            Write-Warning ('One or more Module names were specified but not found, exiting...')
            return
        }
    }

    #Build the $report variable containing all cmdlets and the required permissions
    #Show a Progress bar it there more than 1 cmdlets to be processed
    if ($cmdlets.Name.Count -gt 0) {
        [int]$processed = '1'
        $total = foreach ($item in $cmdlets | Select-Object Name, 'PowerShell Module Name', Version -Unique) {
            if ($cmdlets.count -gt 1) {
                Write-Progress ('Processing cmdlets...') -PercentComplete (($processed * 100) / $cmdlets.count) -Status "$(([math]::Round((($processed)/$cmdlets.count * 100),0))) %"
            }
            foreach ($command in Find-MgGraphCommand -Command $item.Name -ErrorAction SilentlyContinue | Select-Object -First 1) {
                if ($command.permissions.Length -gt 0) {
                    foreach ($permission in $command.permissions) {   
                        [PSCustomObject]@{
                            'Name'                                 = $item.Name
                            'PowerShell Module Name'               = $item.'PowerShell Module Name'
                            'Version'                              = $item.Version
                            'Required Permission Name'             = $permission.Name
                            'Required Permission Description'      = $permission.Description
                            'Required Permission Full Description' = $permission.FullDescription
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        'Name'                                 = $item.Name
                        'PowerShell Module Name'               = $item.'PowerShell Module Name'
                        'Version'                              = $item.Version
                        'Required Permission Name'             = 'No permissions found' 
                        'Required Permission Description'      = 'No permissions found'
                        'Required Permission Full Description' = 'No permissions found'
                    }
                }
            }
            $processed++
        }

        #If $total has items, output it to display or file
        if ($null -ne $total) {

            #Display $total to the chosen $ouput value if $FileName was not used
            if ($Output -and -not $Filename) {
                switch ($Output) {
                    Console { $total | Sort-Object Name, 'PowerShell Module Name', Version, 'Required Permission Name' | Format-Table -AutoSize -Wrap }
                    ConsoleGridView { $total | Sort-Object Name, 'PowerShell Module Name', Version, 'Required Permission Name' | Out-ConsoleGridView -Title 'Microsoft Graph Permissions' }
                    GridView { $total | Sort-Object Name, 'PowerShell Module Name', Version, 'Required Permission Name' | Out-GridView -Title 'Microsoft Graph Permissions' }
                }
            }
    
            #Export to file if $FileName was specified
            if ($Filename) {
                if ($Filename.EndsWith('csv')) {
                    try {
                        $total | Sort-Object Name, 'PowerShell Module Name', Version, 'Required Permission Name' | Export-Csv -Path $Filename -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Append:$true -Force:$true -ErrorAction Stop
                        Write-Host ('Exported Microsoft Graph Permissions to {0}' -f $Filename) -ForegroundColor Green
                    }
                    catch {
                        Write-Warning ('Could not write {0}, check path and permissions. Exiting...' -f $Filename)
                        return
                    }
                }
                if ($Filename.EndsWith('xlsx')) {
                    if (-not (Get-Module ImportExcel -ListAvailable)) {
                        try {
                            Install-Module ImportExcel -Scope CurrentUser -ErrorAction Stop
                            Import-Module ImportExcel -ErrorAction Stop
                            Write-Host ('Installed missing PowerShell Module ImportExcel which is needed for XLSX output') -ForegroundColor Green
                        }
                        catch {
                            Write-Warning ('Could not install missing PowerShell Module ImportExcel which is needed for XLSX output, exiting...')
                            return
                        }
                    }
                    try {
                        $total | Sort-Object Name, 'PowerShell Module Name', Version, 'Required Permission Name' | Export-Excel -Path $Filename -AutoSize -AutoFilter -Append:$true -ErrorAction Stop
                        Write-Host ('Exported Microsoft Graph Permissions to {0}' -f $Filename) -ForegroundColor Green
                    }
                    catch {
                        Write-Warning ('Could not write {0}, check path and permissions. Exiting...' -f $Filename)
                        return
                    }
                }
            } 
        }
    }
    else {
        Write-Warning ('Specified cmdlets were not found / or no cmdlets found in the specified module(s), exiting...')
        return
    }
}