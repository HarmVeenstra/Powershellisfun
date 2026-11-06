function Search-History {
    param (
        [string]$Filter
    )

    # Exit if running in PowerShell v6, that has no Out-ConsoleGridView or Out-GridView
    if ($PSVersionTable.PSVersion.Major -eq 6) {
        Write-Warning "PowerShell 6 is not supported, exiting..."
        return
    }

    # Search History file, and sort reverse so that newest item is on top
    $History = @(Get-Content (Get-PSReadLineOption).HistorySavePath)
    [array]::Reverse($History)
    $History = $History | Select-Object -Unique

    # Pre-apply the filter so the empty check is accurate
    if ($Filter) {
        $History = $History | Where-Object { $_ -like "*$Filter*" }
    }

    # Out-ConsoleGridView if PowerShell v7
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # Check if Microsoft.PowerShell.ConsoleGuiTools is installed, install if not
        if (-not (Get-Command Out-ConsoleGridView -ErrorAction SilentlyContinue)) {
            Write-Warning ("Microsoft.PowerShell.ConsoleGuiTools Module was not found, installing now...")
            try {
                if ($PSVersionTable.PSVersion -lt [version]'7.4') {
                    Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Force -Confirm:$false -ErrorAction Stop
                }
                else {
                    Install-PSResource -Name Microsoft.PowerShell.ConsoleGuiTools -Quiet -Confirm:$false -TrustRepository -ErrorAction Stop
                }
                Write-Host ("Microsoft.PowerShell.ConsoleGuiTools Module successfully installed") -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error installing Module, exiting...")
                Write-Warning $_.Exception.Message
                return
            }
        }
        if ($History) {
            $History = $History | Out-ConsoleGridView -OutputMode:Multiple -Title 'Select one, or more, lines with Spacebar. Hit Enter to execute them'
        }
        else {
            Write-Warning ("No items found matching query, exiting...")
            return
        }
    }

    # Out-GridView is PowerShell v5
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        if ($History) {
            $History = $History | Out-GridView -OutputMode:Multiple -Title 'Select one, or more, with Ctrl+Left mousebutton. Hit Enter to execute them'
        }
        else {
            Write-Warning ("No items found matching query, exiting...")
            return
        }
    }

    # Display and execute selected item(s) with an empty line in between
    if (-not [string]::IsNullOrWhiteSpace($History)) {
        Write-Host ("Executing History item(s):") -ForegroundColor Green
        foreach ($SelectedItem in $History) {
            Write-Host ("- {0}" -f $SelectedItem)
        }
        foreach ($Item in $History) {
            Write-Host ("`n")
            try {
                Invoke-Expression $Item -ErrorAction Stop
            }
            catch {
                Write-Warning ("Error executing selected History item: {0}" -f $Item)
                Write-Warning $_.Exception.Message
            }
        }
    }
    else {
        Write-Warning ("No History item selected...")
    }
}