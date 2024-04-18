function Resolve-CmdletsToModules {
    param(
        [parameter(Mandatory = $true, parameterSetname = "Clipboard")][switch]$clipboard,    
        [parameter(Mandatory = $true, parameterSetname = "Cmdlets")][string[]]$cmdlets,
        [parameter(Mandatory = $true, parameterSetname = "File")][string]$scriptfile,
        [parameter(Mandatory = $false)][string]$outputfile
    )

    #Exit if incorrect extension was used
    if ($outputfile) {
        if (($outputfile.EndsWith('.csv') -ne $true) -and ($outputfile.EndsWith('.xlsx') -ne $true)) {
            Write-Warning ("Specified file {0} does not have the .csv or .xlsx extension. Exiting..." -f $outputfile)
            return
        }
    }

    #Check if Clipboard parameter was used and read contents of file in $scriptcontents
    if ($clipboard) {
        try {
            $scriptcontents = Get-Clipboard -ErrorAction Stop
            if ($scriptcontents.Length -gt 0) {
                write-host ("The Clipboard content is valid, continuing...") -ForegroundColor Green
            }
            else {
                Write-Warning ("Could not read Clipboard contents correctly, picture in Clipboard perhaps? Exiting...")
                return
            }
        }
        catch {
            Write-Warning ("Could not read Clipboard contents correctly, picture in Clipboard perhaps? Exiting...")
            return
        }
    }

    #Add values from $cmdlets to $scriptcontents
    if ($cmdlets) {
        $scriptcontents = $cmdlets
    }

    #Check if specified file is correct and read contents of file in $scriptcontents
    if ($scriptfile) {
        if (Test-Path -Path $scriptfile) {
            write-host ("The specified file {0} is valid, continuing..." -f $scriptfile) -ForegroundColor Green
            $scriptcontents = Get-Content -Path $scriptfile
        }
        else {
            Write-Warning ("The specified file {0} is invalid, exiting..." -f $scriptfile)
            return
        }
    }

    #$Verbs variable with valid PowerShell verbs to search for
    #https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.4
    #Add your own if needed.
    $verbs = @(
        "Add-" 
        "Approve-"
        "Assert-"
        "Backup-"
        "Block-"
        "Build-"
        "Checkpoint-"
        "Clear-"
        "Close-"
        "Compare-"
        "Complete-"
        "Compress-"
        "Confirm-"
        "Connect-"
        "Convert-"
        "ConvertFrom-"
        "ConvertTo-"
        "Copy-"
        "Debug-"
        "Deny-"
        "Deploy-"
        "Disable-"
        "Disconnect-"
        "Dismount-"
        "Edit-"
        "Enable-"
        "Enter-"
        "Exit-"
        "Expand-"
        "Export-"
        "Find-"
        "Format-"
        "Get-"
        "Grant-"
        "Group-"
        "Hide-"
        "Import-"
        "Initialize-"
        "Install-"
        "Invoke-"
        "Join-"
        "Limit-"
        "Lock-"
        "Measure-"
        "Merge-"
        "Mount-"
        "Move-"
        "New-"
        "Open-"
        "Optimize-"
        "Out-"
        "Ping-"
        "Pop-"
        "Protect-"
        "Publish-"
        "Push-"
        "Read-"
        "Receive-"
        "Redo-"
        "Register-"
        "Remove-"
        "Rename-"
        "Repair-"
        "Request-"
        "Reset-"
        "Resize-"
        "Resolve-"
        "Restart-"
        "Restore-"
        "Resume-"
        "Revoke-"
        "Save-"
        "Search-"
        "Select-"
        "Send-"
        "Set-"
        "Show-"
        "Skip-"
        "Split-"
        "Start-"
        "Step-"
        "Stop-"
        "Submit-"
        "Suspend-"
        "Switch-"
        "Sync-"
        "Test-"
        "Trace-"
        "Unblock-"
        "Undo-"
        "Uninstall-"
        "Unlock-"
        "Unprotect-"
        "Unpublish-"
        "Unregister-"
        "Update-"
        "Use-"
        "Wait-"
        "Watch-"
        "Write-"
    )

    #loop through each line in the script and get all the cmdlets being used
    #that are based on the approved verbs above
    $cmdletstocheck = foreach ($line in $scriptcontents) {
        if (-not $line.StartsWith('#')) {
            foreach ($word in $line.Split(' ')) {
                foreach ($verb in $verbs) {
                    if ($word.ToLower().StartsWith($verb.ToLower())) {
                        [PSCustomObject]@{
                            Cmdlet = $word -Replace '[\{\}\(\)\\]', ''
                        }
                    }
                }
            }
        }
    }
    
    #Search for the module(s) that the cmdlet is from
    $results = foreach ($cmdlet in ($cmdletstocheck | Sort-Object -Property * -Unique).Cmdlet | Sort-Object) {
        try {
            $cmdletinfo = Get-Command -Name $cmdlet -Erroraction Stop
            Write-Host ("Checking {0} locally" -f $cmdlet) -ForegroundColor Green
            foreach ($info in $cmdletinfo) {
                [PSCustomObject]@{
                    CmdletName                                = $info.Name
                    CommandType                               = $info.CommandType
                    ModuleName                                = $info.ModuleName
                    Version                                   = $info.Version
                    Location                                  = "Local"
                    'Is required module installed by script?' = if (($scriptcontents | Select-String $info.ModuleName | Select-String Install-Module) -or ($scriptcontents | Select-String $info.ModuleName | Select-String Install-PSResource)) { "Yes" } else { "No (Or -Cmdlets parameter was used)" }
                    'Is required module imported by script?'  = if ($scriptcontents | Select-String $info.ModuleName | Select-String Import-Module) { "Yes" } else { "No (Or -Cmdlets parameter was used)" }                    
                }    
            }
        }
        catch {
            Write-Warning ("Could not find information for {0} in your local modules, trying online..." -f $cmdlet)
            $cmdletinfo = Find-Module -Command $cmdlet
            Write-Host ("Checking {0} online" -f $cmdlet) -ForegroundColor Green
            if ($cmdletinfo) {
                foreach ($info in $cmdletinfo) {
                    [PSCustomObject]@{
                        CmdletName                                = $cmdlet
                        CommandType                               = $info.Type
                        ModuleName                                = $info.Name
                        Version                                   = $info.Version
                        Location                                  = "PSGallery"
                        'Is required module installed by script?' = if (($scriptcontents | Select-String $info.Name | Select-String Install-Module) -or ($scriptcontents | Select-String $info.Name | Select-String Install-PSResource)) { "Yes" } else { "No (Or -Cmdlets parameter was used)" }
                        'Is required module imported by script?'  = if ($scriptcontents | Select-String $info.Name | Select-String Import-Module) { "Yes" } else { "No (Or -Cmdlets parameter was used)" }
                    }
                }
            }
            else {            
                Write-Warning ("Could not find information for {0} in PSGallery, skipping..." -f $cmdlet)
            }
        }
    }

    #Output to .csv file
    if ($outputfile.EndsWith('.csv')) {
        if ($results) {
            try {
                New-Item -Path $outputfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
                $results | Sort-Object Name | Export-Csv -Path $outputfile -Encoding UTF8 -Delimiter ';' -NoTypeInformation
                Write-Host ("`nExported results to {0}" -f $outputfile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $outputfile)
                return
            }
        }
        else {
            Write-Warning ("No results found, exiting...")
            return
        }
    }

    #Output to .xlsx file
    if ($outputfile.EndsWith('.xlsx')) {
        if ($results) {
            try {
                #Test path and remove empty file afterwards because xlsx is corrupted if not
                New-Item -Path $outputfile -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
                Remove-Item -Path $outputfile -Force:$true -Confirm:$false | Out-Null
    
                #Install ImportExcel module if needed
                if (-not (Get-Module -Name importexcel -ListAvailable)) {
                    Write-Warning ("`nImportExcel PowerShell Module was not found, installing...")
                    Install-Module ImportExcel -Scope CurrentUser -Force:$true
                    Import-Module ImportExcel
                }
                Import-Module ImportExcel
                $results | Sort-Object Name | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter -Path $outputfile
                Write-Host ("`nExported results to {0}" -f $outputfile) -ForegroundColor Green
            }
            catch {
                Write-Warning ("`nCould not export results to {0}, check path and permissions" -f $outputfile)
                return
            }
        }
        else {
            Write-Warning ("No results found, exiting...")
            return
        }
    }

    #Output to screen if -Outputfile was not specified
    if (-not $outputfile) {
        if ($results) {
            return $results | Format-Table -AutoSize
        }
        else {
            Write-Warning ("No results found, exiting...")
        }
    }
}