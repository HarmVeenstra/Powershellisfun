function Invoke-CmdMS {
    [CmdletBinding(DefaultParameterSetName = 'Browser')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Alias')]
        [Parameter(Mandatory = $false, ParameterSetName = 'AliasBrowser')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Browser')]
        [string[]]$Alias,
        [Parameter(Mandatory = $false, ParameterSetName = 'AliasBrowser')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Browser')]
        [Parameter(Mandatory = $false, ParameterSetName = 'FilterBrowser')]
        [ValidateSet('Brave', 'Chrome', 'FireFox', 'MSEdge')][string]$Browser,
        [Parameter(Mandatory = $false, ParameterSetName = 'Browser')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [Parameter(Mandatory = $false, ParameterSetName = 'FilterBrowser')]
        [string]$Filter = ''
    )

    #Retrieve commands.csv from Merill's GitHub page, use $filter if specified or '' when not specified to retrieve all URLs
    try {
        $cmds = (Invoke-RestMethod -Uri https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv -ErrorAction Stop | ConvertFrom-Csv -ErrorAction Stop) -match $filter
        Write-Host ("Retrieved URLs from https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv...") -ForegroundColor Green
    }
    catch {
        Write-Warning ("Error retrieving commands from https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv, check internet access! Exiting..." -f $shortname)
        return
    }

    #If $alias(es) were specified, check if they are valid
    if ($Alias) {
        $aliases = foreach ($shortname in $Alias) {
            try {
                $aliascmds = Invoke-RestMethod -Uri https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv -ErrorAction Stop | ConvertFrom-Csv -ErrorAction Stop | Where-Object Alias -EQ $shortname
                if ($null -ne $aliascmds) {
                    Write-Host ("Specified {0} alias was found..." -f $shortname) -ForegroundColor Green
                    [PSCustomObject]@{
                        Alias = $shortname
                        URL   = $aliascmds.Url
                    }
                }
                else {
                    Write-Warning ("Specified Alias {0} was not found, check https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv for the correct name(s)..." -f $shortname)
                }
            }
            catch {
                Write-Warning ("Error displaying/selecting Alias {0} from https://cmd.ms, check https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv for the correct name(s)..." -f $shortname)
            }
        }
    } 
    else {
        #Output $cmds to Out-ConsoleGridView. If the PowerShell version is 7 or higher, install Microsoft.PowerShell.ConsoleGuiTools if needed
        if ($host.Version.Major -ge 7) {
            if (-not (Get-Module Microsoft.PowerShell.ConsoleGuiTools -ListAvailable )) {
                try {
                    Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -ErrorAction Stop
                    Write-Host ("Installed required Module Microsoft.PowerShell.ConsoleGuiTools") -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error installing required Module Microsoft.PowerShell.ConsoleGuiTools, exiting...")
                    return
                }
            }
            $cmds = $cmds | Sort-Object Category | Out-ConsoleGridView -Title 'Select the site(s) by selecting them with the spacebar and hit Enter to continue...' -ErrorAction Stop
            if ($null -eq $cmds) {
                Write-Warning ("No site(s) selected / Pressed Escape, exiting...")
                return
            }
        }
    }

    #Output $cmds to Out-GridView if the PowerShell version is 5 or lower
    if ($host.Version.Major -le 5) {
        $cmds = $cmds | Sort-Object Category | Out-GridView -PassThru -Title 'Select the site(s) by selecting them with the spacebar while holding CTRL, hit Enter to continue...' -ErrorAction Stop
        if ($null -eq $cmds) {
            Write-Warning ("No site(s) selected / Pressed Escape...")
            return
        }
    }

    #Try to open the selected URLs from either $alias or $cmds
    if ($Alias) {
        foreach ($url in $aliases) {
            if ($Browser) {
                #Open in specified Browser using -Browser
                try {
                    Start-Process "$($Browser).exe" -ArgumentList $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} in {1} browser for alias {2}..." -f $url.url, $Browser, $url.Alias) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} in {1} browser for alias {2}" -f $url.url, $Browser, $url.Alias)
                }
            }
            else {
                try {
                    Start-Process $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} for alias {1} in the default browser..." -f $url.url, $url.Alias) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} for alias {1} in the default browser" -f $url.url, $url.Alias)
                }
            } 
        }
    }
    else {
        foreach ($cmd in $cmds) {
            #Open in Default Browser (Without using -Browser)
            if ($Browser) {
                #Open in specified Browser using -Browser
                try {
                    Start-Process "$($Browser).exe" -ArgumentList $cmd.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} in {1} browser..." -f $cmd.url, $Browser) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} in {1} browser" -f $cmd.url, $Browser)
                }
            }
            else {
                try {
                    Start-Process $cmd.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} in the default browser..." -f $cmd.url) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} in the default browser" -f $cmd.url)
                }
            }            
        }
    }
}