function Invoke-CmdMS {
    [CmdletBinding(DefaultParameterSetName = 'Filter')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = ('Alias'))][string[]]$Alias,
        [Parameter(Mandatory = $false)][ValidateSet('Brave', 'Chrome', 'FireFox', 'MSEdge')][string]$Browser,
        [Parameter(Mandatory = $false, ParameterSetName = ('Command'))][string[]]$Command,
        [Parameter(Mandatory = $false, ParameterSetName = ('Filter'))][string]$Filter = '',
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$RunAs
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

    # build params to splat for start-process when we have a Browser and/or are using RunAs
    $paramCmdStartProcess = @{}
    if ($Browser) { $paramCmdStartProcess.FilePath = "$($Browser).exe" }
    if ($PSBoundParameters.RunAs) {
        $paramCmdStartProcess.Credential = (Get-Credential $RunAs)
        
        # // to use Credential with Start-Process we need the full file path for the Browser
        # // we can read this with Get-Process
       
        if (-not $Browser) {
            Write-Verbose 'Fetching Default Browser'
            # get the default browser based on the ones in the validateset
            $thisCommand = Get-Command $MyInvocation.MyCommand.Name
            $thisCommandBrowsers = $thisCommand.Parameters.Browser.Attributes.ValidValues
            [regex] $browserList =  $thisCommandBrowsers -join "|"
            $defaultBrowserPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
            $defaultBrowser = (Get-Item $defaultBrowserPath | Get-ItemProperty).ProgId
            try {
                $Browser = $browserList.Match($defaultBrowser).Value
            }
            catch {
                "Couldn't find the Browser we were looking for, re-try the command using -Browser" | Write-Warning
                return
            }
        }

        Write-Verbose 'Fetching Browser File Path'
        if (Get-Process $Browser -ErrorAction SilentlyContinue) {
            # if we're already have the browser open
            $proc = Get-Process $Browser | Where-Object { -not [string]::IsNullOrEmpty($_.Path) } | Select-Object -First 1
        }
        else {
            try {
                # launch the browser to obtain the file path using Get-Process
                Start-Process $Browser -ErrorAction Stop
                # this ensures we wait for the process to spawn with a MainWindowHandle to pass later on to hide
                while (-not (Get-Process $Browser | Where-Object { -not [string]::IsNullOrEmpty($_.MainWindowTitle.ToString()) }))
                {
                    Start-Sleep -Milliseconds 200
                }   
                $proc = Get-Process $Browser | Where-Object { -not [string]::IsNullOrEmpty($_.MainWindowTitle.ToString()) }

                # hide the launched browser window so it doesnt get in the way
                Add-Type -Name Window -Namespace Console -MemberDefinition '
                [DllImport("Kernel32.dll")]
                public static extern IntPtr GetConsoleWindow();
                [DllImport("user32.dll")]
                public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
                '
                [void] [Console.Window]::ShowWindow($proc.MainWindowHandle, 0)
            }
            catch {
                'Failed to launch {0} : {1} ' -f $Browser, $_.Exception.Message | Write-Warning
                return 
            }
        }

        $paramCmdStartProcess.FilePath = $proc.Path

    } #if

    #If $alias(es) or $Command(s) were specified, check if they are valid
    if ($Alias) {
        $aliases = foreach ($shortname in $Alias) {
            try {
                $aliascmds = Invoke-RestMethod -Uri https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv -ErrorAction Stop | ConvertFrom-Csv -ErrorAction Stop | Where-Object Alias -EQ $shortname
                if ($aliascmds) {
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
    
    if ($Command) {
        $Commands = foreach ($portal in $Command) {
            try {
                $commandcmds = Invoke-RestMethod -Uri https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv -ErrorAction Stop | ConvertFrom-Csv -ErrorAction Stop | Where-Object Command -EQ $portal
                if ($commandcmds) {
                    Write-Host ("Specified {0} Command was found..." -f $portal) -ForegroundColor Green
                    [PSCustomObject]@{
                        Command = $portal
                        URL     = $commandcmds.Url
                    }
                }
                else {
                    Write-Warning ("Specified Command {0} was not found, check https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv for the correct name(s)..." -f $portal)
                }
            }
            catch {
                Write-Warning ("Error displaying/selecting Command {0} from https://cmd.ms, check https://raw.githubusercontent.com/merill/cmd/refs/heads/main/website/config/commands.csv for the correct name(s)..." -f $portal)
            }
        }
    }

    #If $Alias or $Command was not specified, display all items in a GridView
    if (-not ($Alias) -and -not ($Command)) {
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
            if (-not ($cmds)) {
                Write-Warning ("No site(s) selected / Pressed Escape, exiting...")
                return
            }
        }
        #Output $cmds to Out-GridView if the PowerShell version is 5 or lower
        if ($host.Version.Major -le 5) {
            $cmds = $cmds | Sort-Object Category | Out-GridView -PassThru -Title 'Select the site(s) by selecting them with the spacebar while holding CTRL, hit Enter to continue...' -ErrorAction Stop
            if (-not ($cmds)) {
                Write-Warning ("No site(s) selected / Pressed Escape...")
                return
            }
        }
    }  

    #Try to open the selected URLs from either $alias, $Command or $cmds
    if ($Alias) {
        foreach ($url in $aliases) {
            if ($Browser) {
                #Open in specified Browser using -Browser
                try {
                    Start-Process @paramCmdStartProcess -ArgumentList $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} in {1} browser for Alias {2}..." -f $url.url, $Browser, $url.Alias) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} in {1} browser for Alias {2}" -f $url.url, $Browser, $url.Alias)
                }
            }
            else {
                try {
                    Start-Process $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} for Alias {1} in the default browser..." -f $url.url, $url.Alias) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} for Alias {1} in the default browser" -f $url.url, $url.Alias)
                }
            } 
        }
    }

    if ($Command) {
        foreach ($url in $commands) {
            if ($Browser) {               
                #Open in specified Browser using -Browser
                try {
                    Start-Process @paramCmdStartProcess -ArgumentList $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} in {1} browser for Command {2}..." -f $url.url, $Browser, $url.command) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} in {1} browser for Command {2}" -f $url.url, $Browser, $url.command)
                }
            }
            else {
                try {
                    Start-Process $url.URL -ErrorAction Stop
                    Write-Host ("Opening selected URL {0} for Command {1} in the default browser..." -f $url.url, $url.command) -ForegroundColor Green
                }
                catch {
                    Write-Warning ("Error opening selected URL {0} for Command {1} in the default browser" -f $url.url, $url.command)
                }
            } 
        }
    }

    if (-not ($Alias) -and -not ($Command)) {
        foreach ($cmd in $cmds) {
            #Open in Default Browser (Without using -Browser)
            if ($Browser) {
                #Open in specified Browser using -Browser
                try {
                    Start-Process @paramCmdStartProcess -ArgumentList $cmd.URL -ErrorAction Stop
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