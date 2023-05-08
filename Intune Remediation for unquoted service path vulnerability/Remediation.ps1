<#
.SYNOPSIS
    Fix for Microsoft Windows Unquoted Service Path Enumeration

.DESCRIPTION
    Script for fixing vulnerability "Unquoted Service Path Enumeration" in Services and Uninstall strings. Script modifying registry values. 
    Require Administrator rights and should be run on x64 powershell version in case if OS also have x64 architecture

.PARAMETER FixServices
    This bool parameter allow proceed Services with vulnerability. By default this parameter enabled.
    For disabling this parameter use -FixServices:$False

.PARAMETER FixUninstall
    Parameter allow find and fix vulnerability in UninstallPaths.
    Will be covered paths for x86 and x64 applications on x64 systems.

.PARAMETER FixEnv
    Find services with Environment variables in the ImagePath parameter, and replace Env. variable to the it value
    EX. %ProgramFiles%\service.exe will be replace to "C:\Program Files\service.exe"

.PARAMETER WhatIf
    Parameter should be used for checking possible system impact.
    With this parameter script would not change anything on your system,
    and only will show information about possible (needed) changes.

.PARAMETER CreateBackup
    When switch parameter enabled script will export registry tree`s
    specified for services or uninstall strings based on operator selection.
    Tree would be exported before any changes.

    [Note] For restoring backup could be used RestoreBackup parameter
    [Note] For providing full backup path could be used BackupName parameter

.PARAMETER RestoreBackup
    This parameter will allow restore previously created backup.
    If BackupName parameter would not be provided will be used last created backup,
    in other case script will try to find selected backup name

    [Note] For creation backup could be used CreateBackup parameter
    [Note] For providing full backup path could be used BackupName parameter

.PARAMETER BackupFolderPath
    Parameter would be proceeded only with CreateBackup or RestoreBackup
    If CreateBackup or RestoreBackup parameter will be provided, then path from this parameter will be used.

    During backup will be created reg file with original values per each service and application that will be modified
    During restoration all reg files in the specified format will be iterable imported to the registry

    Input example: C:\Backup\

    Backup file format:
      for -FixServices switch => Service_<ServiceName>_YYYY-MM-DD_HHmmss.reg
      for -FixUninstall switch => Software_<ApplicationName>_YYYY-MM-DD_HHmmss.reg

.PARAMETER Passthru
    With this parameter will be returned object array without any messages in a console
    Each element will continue Service\Program Name, Path, Type <Service\Software>, ParamName <ImagePath\UninstallString>, OriginalValue, ExpectedValue

.PARAMETER Silent
    [i] Silent parameter will work only together with Passthru parameter
    If at least 1 Service Path or Uninstall String should be fixed script will return $true
    Otherwise script will return $false

    Example:
        .\windows_path_enumerate.ps1 -FixUninstall -WhatIf -Passthru -Silent
    Output:
        $true
    Description:
        $true mean at least 1 service need to be fixed.
        WhatIf switch mean that nothing was fixed, registry was only diagnosed for the vulnerability

.PARAMETER Help
    Will display this help message

.PARAMETER LogName
    Parameter allow to change output file location, or disable logging setting this parameter to empty string or $null.

.EXAMPLE
    # Run powershell as administrator and type path to this script. In case if it will not run type dot (.) before path.
    . C:\Scripts\Windows_Path_Enumerate.ps1


VERBOSE:
--------
    2017-02-19 15:43:50Z  :  INFO  :  ComputerName: W8-NB
    2017-02-19 15:43:50Z  :  Old Value :  Service: 'BadDriver' - %ProgramFiles%\bad driver\driver.exe -k -l 'oper'
    2017-02-19 15:43:50Z  :  Expected  :  Service: 'BadDriver' - "%ProgramFiles%\bad driver\driver.exe" -k -l 'oper'
    2017-02-19 15:43:50Z  :  SUCCESS  : New Value of ImagePath was changed for service 'BadDriver'
    2017-02-19 15:43:50Z  :  Old Value :  Service: 'NotAVirus' - C:\Program Files\Strange Software\virus.exe -silent
    2017-02-19 15:43:51Z  :  Expected  :  Service: 'NotAVirus' - "C:\Program Files\Strange Software\virus.exe" -silent'
    2017-02-19 15:43:51Z  :  SUCCESS  : New Value of ImagePath was changed for service 'NotAVirus'

Description
-----------
    Fix 2 services 'BadDriver', 'NotAVirus'.
    Env variable %ProgramFiles% did not changed to full path in service 'BadDriver'


.EXAMPLE
    # This command, or similar could be used for running script from SCCM
    Powershell -ExecutionPolicy bypass -command ". C:\Scripts\Windows_Path_Enumerate.ps1 -FixEnv"


VERBOSE:
--------
    2017-02-19 15:43:50Z  :  INFO  :  ComputerName: W8-NB
    2017-02-19 15:43:50Z  :  Old Value :  Service: 'BadDriver' - %ProgramFiles%\bad driver\driver.exe -k -l 'oper'
    2017-02-19 15:43:50Z  :  Expected  :  Service: 'BadDriver' - "C:\Program Files\bad driver\driver.exe" -k -l 'oper'
    2017-02-19 15:43:50Z  :  SUCCESS  : New Value of ImagePath was changed for service 'BadDriver'
    2017-02-19 15:43:50Z  :  Old Value :  Service: 'NotAVirus' - %SystemDrive%\Strange Software\virus.exe -silent
    2017-02-19 15:43:51Z  :  Expected  :  Service: 'NotAVirus' - "C:\Strange Software\virus.exe" -silent'
    2017-02-19 15:43:51Z  :  SUCCESS  : New Value of ImagePath was changed for service 'NotAVirus'

Description
-----------
    Fix 2 services 'BadDriver', 'NotAVirus'.
    Env variable %ProgramFiles% replaced to full path 'C:\Program Files' in service 'BadDriver'

.EXAMPLE
    # This command, or similar could be used for running script from SCCM
    Powershell -ExecutionPolicy bypass -command ". C:\Scripts\Windows_Path_Enumerate.ps1 -FixUninstall -FixServices:$False -WhatIf"


VERBOSE:
--------
    2018-07-02 22:23:02Z  :  INFO  :  ComputerName: test
    2018-07-02 22:23:04Z  :  Old Value : Software : 'FakeSoft32' - c:\Program files (x86)\Fake inc\Pseudo Software\uninstall.exe -silent
    2018-07-02 22:23:04Z  :  Expected  : Software : 'FakeSoft32' - "c:\Program files (x86)\Fake inc\Pseudo Software\uninstall.exe" -silent


Description
-----------
    Script will find and displayed


.EXAMPLE
    # This command will return $true if at least 1 path should be fixed or $false if there nothing to fix
    # Log will not be available
    .\windows_path_enumerate.ps1 -FixUninstall -WhatIf -Passthru -Silent -LogName ''


VERBOSE:
--------
    true



.NOTES
    Name:  Windows_Path_Enumerate.PS1
    Version: 3.5.1
    Author: Vector BCO
    Updated: 8 April 2021

.LINK
    https://github.com/VectorBCO/windows-path-enumerate/
    https://gallery.technet.microsoft.com/scriptcenter/Windows-Unquoted-Service-190f0341
    https://www.tenable.com/sc-report-templates/microsoft-windows-unquoted-service-path-enumeration
    http://www.commonexploits.com/unquoted-service-paths/
#>

[CmdletBinding(DefaultParameterSetName = "Fixing")]

Param (
    [parameter(Mandatory = $false,
        ParameterSetName = "Fixing")]
    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [Alias("s")]
    [Bool]$FixServices = $true,

    [parameter(Mandatory = $false,
        ParameterSetName = "Fixing")]
    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [Alias("u")]
    [Switch]$FixUninstall,

    [parameter(Mandatory = $false,
        ParameterSetName = "Fixing")]
    [Alias("e")]
    [Switch]$FixEnv,

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [Alias("cb", "backup")]
    [switch]$CreateBackup,

    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [Alias("rb", "restore")]
    [switch]$RestoreBackup,

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [string]$BackupFolderPath = "C:\Temp\PathEnumerationBackup",

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [string]$LogName = "C:\Temp\ServicesFix-3.5.1.Log",

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [parameter(Mandatory = $False,
        ParameterSetName = "Restoring")]
    [Alias("ShowOnly")]
    [Switch]$WhatIf,

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [Switch]$Passthru,

    [parameter(Mandatory = $False,
        ParameterSetName = "Fixing")]
    [Switch]$Silent,

    [parameter(Mandatory = $true,
        ParameterSetName = "Help")]
    [Alias("h")]
    [switch]$Help
)

Function Fix-ServicePath {
    <#
    .SYNOPSIS
        Microsoft Windows Unquoted Service Path Enumeration

    .DESCRIPTION
        Use Fix-ServicePath to fix vulnerability "Unquoted Service Path Enumeration".

    .PARAMETER FixServices
        This switch parameter allow proceed Services with vulnerability. By default this parameter enabled.
        For disable this parameter use -FixServices:$False

    .PARAMETER FixUninstall
        Parameter allow find and fix vulnerability in UninstallPath.
        Will be covered paths for x86 and x64 applications on x64 systems.

    .PARAMETER FixEnv
        Find services with Environment variables in the ImagePath parameter, and replace Env. variable to the it value
        EX. %ProgramFiles%\service.exe will be replace to "C:\Program Files\service.exe"

    .PARAMETER WhatIf
        Parameter should be used for checking possible system impact.
        With this parameter script would not be changing anything on your system,
        and only will show information about possible changes

    .EXAMPLE
        Fix-ServicePath


    VERBOSE:
    --------
        2017-02-19 15:43:50Z  :  Old Value :  Service: 'BadDriver' - %ProgramFiles%\bad driver\driver.exe -k -l 'oper'
        2017-02-19 15:43:50Z  :  Expected  :  Service: 'BadDriver' - "%ProgramFiles%\bad driver\driver.exe" -k -l 'oper'
        2017-02-19 15:43:50Z  :  SUCCESS  : New Value of ImagePath was changed for service 'BadDriver'
        2017-02-19 15:43:50Z  :  Old Value :  Service: 'NotAVirus' - C:\Program Files\Strange Software\virus.exe -silent
        2017-02-19 15:43:51Z  :  Expected  :  Service: 'NotAVirus' - "C:\Program Files\Strange Software\virus.exe" -silent'
        2017-02-19 15:43:51Z  :  SUCCESS  : New Value of ImagePath was changed for service 'NotAVirus'

    Description
    -----------
        Fix 2 services 'BadDriver', 'NotAVirus'.
        Env variable %ProgramFiles% did not changed to full path in service 'BadDriver'


    .EXAMPLE
        Fix-ServicePath -FixEnv


    VERBOSE:
    --------
        2017-02-19 15:43:50Z  :  Old Value :  Service: 'BadDriver' - %ProgramFiles%\bad driver\driver.exe -k -l 'oper'
        2017-02-19 15:43:50Z  :  Expected  :  Service: 'BadDriver' - "C:\Program Files\bad driver\driver.exe" -k -l 'oper'
        2017-02-19 15:43:50Z  :  SUCCESS  : New Value of ImagePath was changed for service 'BadDriver'
        2017-02-19 15:43:50Z  :  Old Value :  Service: 'NotAVirus' - %SystemDrive%\Strange Software\virus.exe -silent
        2017-02-19 15:43:51Z  :  Expected  :  Service: 'NotAVirus' - "C:\Strange Software\virus.exe" -silent'
        2017-02-19 15:43:51Z  :  SUCCESS  : New Value of ImagePath was changed for service 'NotAVirus'

    Description
    -----------
        Fix 2 services 'BadDriver', 'NotAVirus'.
        Env variable %ProgramFiles% replaced to full path 'C:\Program Files' in service 'BadDriver'

    .EXAMPLE
        Fix-ServicePath -FixUninstall -FixServices:$False -WhatIf


    VERBOSE:
    --------
        2018-07-02 22:23:04Z  :  Old Value : Software : 'FakeSoft32' - c:\Program files (x86)\Fake inc\Pseudo Software\uninstall.exe -silent
        2018-07-02 22:23:04Z  :  Expected  : Software : 'FakeSoft32' - "c:\Program files (x86)\Fake inc\Pseudo Software\uninstall.exe" -silent


    Description
    -----------
        Script will find problems and only display result but will not change anything


    .NOTES
        Name:  Fix-ServicePath
        Version: 3.5
        Author: Vector BCO
        Last Modified: 3 May 2020

    .LINK
        https://gallery.technet.microsoft.com/scriptcenter/Windows-Unquoted-Service-190f0341
        https://www.tenable.com/sc-report-templates/microsoft-windows-unquoted-service-path-enumeration
        http://www.commonexploits.com/unquoted-service-paths/
    #>

    Param (
        [bool]$FixServices = $true,
        [Switch]$FixUninstall,
        [Switch]$FixEnv,
        [Switch]$Backup,
        [string]$BackupFolder = "C:\Temp\PathEnumeration",
        [Switch]$WhatIf,
        [Switch]$Passthru
    )

    # Get all services
    $FixParameters = @()
    If ($FixServices) {
        $FixParameters += @{"Path" = "HKLM:\SYSTEM\CurrentControlSet\Services\" ; "ParamName" = "ImagePath" }
    }
    If ($FixUninstall) {
        $FixParameters += @{"Path" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" ; "ParamName" = "UninstallString" }
        # If OS x64 - adding paths for x86 programs
        If (Test-Path "$($env:SystemDrive)\Program Files (x86)\") {
            $FixParameters += @{"Path" = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" ; "ParamName" = "UninstallString" }
        }
    }
    If ($Backup) {
        If (! (Test-Path $BackupFolder)) {
            New-Item $BackupFolder -Force -ItemType Directory | Out-Null
        }
    }
    $PTElements = @()
    ForEach ($FixParameter in $FixParameters) {
        Get-ChildItem $FixParameter.Path -ErrorAction SilentlyContinue | ForEach-Object {
            $SpCharREGEX = '([\[\]])'
            $RegistryPath = $_.name -Replace 'HKEY_LOCAL_MACHINE', 'HKLM:' -replace $SpCharREGEX, '`$1'
            $OriginalPath = (Get-ItemProperty "$RegistryPath")
            $ImagePath = $OriginalPath.$($FixParameter.ParamName)
            If ($FixEnv) {
                If ($($OriginalPath.$($FixParameter.ParamName)) -match '%(?''envVar''[^%]+)%') {
                    $EnvVar = $Matches['envVar']
                    $FullVar = (Get-ChildItem env: | Where-Object { $_.Name -eq $EnvVar }).value
                    $ImagePath = $OriginalPath.$($FixParameter.ParamName) -replace "%$EnvVar%", $FullVar
                    Clear-Variable Matches
                } # End If
            } # End If $fixEnv
            # Get all services with vulnerability
            If (($ImagePath -like "* *") -and ($ImagePath -notLike '"*"*') -and ($ImagePath -like '*.exe*')) {
                # Skip MsiExec.exe in uninstall strings
                If ((($FixParameter.ParamName -eq 'UninstallString') -and ($ImagePath -NotMatch 'MsiExec(\.exe)?') -and ($ImagePath -Match '^((\w\:)|(%[-\w_()]+%))\\')) -or ($FixParameter.ParamName -eq 'ImagePath')) {
                    $NewPath = ($ImagePath -split ".exe ")[0]
                    $key = ($ImagePath -split ".exe ")[1]
                    $trigger = ($ImagePath -split ".exe ")[2]
                    $NewValue = ''
                    # Get service with vulnerability with key in ImagePath
                    If (-not ($trigger | Measure-Object).count -ge 1) {
                        If (($NewPath -like "* *") -and ($NewPath -notLike "*.exe")) {
                            $NewValue = "`"$NewPath.exe`" $key"
                        } # End If
                        # Get service with vulnerability with out key in ImagePath
                        ElseIf (($NewPath -like "* *") -and ($NewPath -like "*.exe")) {
                            $NewValue = "`"$NewPath`""
                        } # End ElseIf
                        If ((-not ([string]::IsNullOrEmpty($NewValue))) -and ($NewPath -like "* *")) {
                            try {
                                $soft_service = $(if ($FixParameter.ParamName -Eq 'ImagePath') { 'Service' }Else { 'Software' })
                                $OriginalPSPathOptimized = $OriginalPath.PSPath -replace $SpCharREGEX, '`$1'
                                Write-Output "$(get-date -format u)  :  Old Value : $soft_service : '$($OriginalPath.PSChildName)' - $($OriginalPath.$($FixParameter.ParamName))"
                                Write-Output "$(get-date -format u)  :  Expected  : $soft_service : '$($OriginalPath.PSChildName)' - $NewValue"
                                if ($Passthru) {
                                    $PTElements += '' | Select-Object `
                                    @{n = 'Name'; e = { $OriginalPath.PSChildName } }, `
                                    @{n = 'Type'; e = { $soft_service } }, `
                                    @{n = 'ParamName'; e = { $FixParameter.ParamName } }, `
                                    @{n = 'Path'; e = { $OriginalPSPathOptimized } }, `
                                    @{n = 'OriginalValue'; e = { $OriginalPath.$($FixParameter.ParamName) } }, `
                                    @{n = 'ExpectedValue'; e = { $NewValue } }
                                }
                                If ($Backup) {
                                    $BcpFileName = "$BackupFolder\$soft_service`_$($OriginalPath.PSChildName)`_$(get-date -uFormat "%Y-%m-%d_%H%M%S").reg"
                                    $BcpTmpFileName = "$BackupFolder\$soft_service`_$($OriginalPath.PSChildName)`_$(get-date -uFormat "%Y-%m-%d_%H%M%S").tmp"
                                    $BcpRegistryPath = $RegistryPath -replace '\:'
                                    Write-Output "$(get-date -format u)  :  Creating registry backup : $BcpFileName"
                                    $ExportResult = REG EXPORT $BcpRegistryPath $BcpTmpFileName | Out-String
                                    Get-Content $BcpTmpFileName | Out-File $BcpFileName -Append
                                    Remove-Item $BcpTmpFileName -Force -ErrorAction "SilentlyContinue"
                                    Write-Output "$(get-date -format u)  :  Backup Result : $($ExportResult -split '\r\n' | Where-Object {$_ -NotMatch '^$'})"
                                }
                                If (! $WhatIf) {
                                    Set-ItemProperty -Path $OriginalPSPathOptimized -Name $($FixParameter.ParamName) -Value $NewValue -ErrorAction Stop
                                    $DisplayName = ''
                                    $keyTmp = (Get-ItemProperty -Path $OriginalPSPathOptimized)
                                    If ($soft_service -match 'Software') {
                                        $DisplayName = $keyTmp.DisplayName
                                    }
                                    If ($keyTmp.$($FixParameter.ParamName) -eq $NewValue) {
                                        Write-Output "$(get-date -format u)  :  SUCCESS  : Path value was changed for $soft_service '$($OriginalPath.PSChildName)' $(if($DisplayName){"($DisplayName)"})"
                                    } # End If
                                    Else {
                                        Write-Output "$(get-date -format u)  :  ERROR  : Something is going wrong. Path was not changed for $soft_service '$(if($DisplayName){$DisplayName}else{$OriginalPath.PSChildName})'."
                                    } # End Else
                                } # End If
                            } # End try
                            Catch {
                                Write-Output "$(get-date -format u)  :  ERROR  : Something is going wrong. Value changing failed in service '$($OriginalPath.PSChildName)'."
                                Write-Output "$(get-date -format u)  :  ERROR  : $_"
                            } # End Catch
                            Clear-Variable NewValue
                        } # End If
                    } # End Main If
                } # End if (Skip not needed strings)
            } # End If
            If (($trigger | Measure-Object).count -ge 1) {
                Write-Output "$(get-date -format u)  :  ERROR  : Can't parse  $($OriginalPath.$($FixParameter.ParamName)) in registry  $($OriginalPath.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry\:\:') "
            } # End If
        } # End Foreach
    } # End Foreach
    if ($Passthru) {
        return $PTElements
    }
}

Function Get-OSandPoShArchitecture {
    # Check OS architecture
    if ((Get-CimInstance Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture -match "64.?bits?") {
        if ([intptr]::Size -eq 8) {
            Return $true, $true
        }
        else {
            Return $true, $false
        }
    }
    else { Return $false, $false }
}

Function Tee-Log {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Input,
        [Parameter(Mandatory = $true)]
        $FilePath,
        [switch]$Silent
    )
    if ($Silent) {
        $Input | Out-File -FilePath $LogName -Append
    }
    else {
        $Input | Tee-Object -FilePath $LogName -Append
    }
}

if ((! $FixServices) -and (! $FixUninstall)) {
    Throw "Should be selected at least one of two parameters: FixServices or FixUninstall. `r`n For more details use 'get-help Windows_Path_Enumerate.ps1 -full'"
}

if ($Help) {
    Write-Output "For help use this command in powershell: Get-Help $($MyInvocation.MyCommand.Path) -full"
    powershell -command "& Get-Help $($MyInvocation.MyCommand.Path) -full"
    exit
}

$OS, $PoSh = Get-OSandPoShArchitecture
If (($OS -eq $true) -and ($PoSh -eq $true)) {
    $validation = "$(get-date -format u)  :  INFO  : Executed x64 Powershell on x64 OS"
}
elseIf (($OS -eq $true) -and ($PoSh -eq $false)) {
    $validation = "$(get-date -format u)  :  WARNING  : !ATTENTION! : Executed x32 Powershell on x64 OS. Not all vulnerabilities could be fixed.`r`n"
    $validation += "$(get-date -format u)  :  WARNING  : For fixing all vulnerabilities should be used x64 Powershell."
}
else {
    $validation = "$(get-date -format u)  :  INFO  : Executed x32 Powershell on x32 OS"
}

$DeleteLogFile = $false

if ([string]::IsNullOrEmpty($LogName)) {
    # Log will be written to the temp file if file not specified
    $DeleteLogFile = $true
    $LogName = New-TemporaryFile 
} 
If (! (Test-Path $LogName)) {
    # If path does not exists it should be created
    try {
        $tmpLogPath = $LogName
        if ($tmpLogPath -NotMatch '[\\\/]$') { 
            $tmpLogName = ($tmpLogPath -split '[\\\/]')[-1]
            $tmpLogPath = $tmpLogPath -replace "$tmpLogName`$"
        }
        else {
            $tmpLogName = 'ServicesFix-3.X.Log'
        }
        if (! (Test-Path $tmpLogPath)) {
            New-Item -Path $tmpLogPath -Force -ItemType Directory | Out-Null
        }
        New-Item -Path "$tmpLogPath\$tmpLogName" -Force -ItemType File | Out-Null
        $LogName = "$tmpLogPath\$tmpLogName"
    }
    catch {
        Throw "Log file '$LogName' does not exists and cannot be created. Error: $_"
    }
}


'*********************************************************************' | Tee-Log -FilePath $LogName -Silent:$Passthru
"$(get-date -format u)  :  INFO  : ComputerName: $($Env:ComputerName)" | Tee-Log -FilePath $LogName -Silent:$Passthru
$validation | Tee-Log -FilePath $LogName -Silent:$Passthru

if ($RestoreBackup) {
    if ($FixServices -and (! $FixUninstall)) {
        $RegexPart = "Service"
    }
    elseif ($FixUninstall -and (! $FixServices)) {
        $RegexPart = "Software"
    }
    elseif ($FixUninstall -and $FixServices) {
        $RegexPart = "(Service|Software)"
    }

    if (Test-Path $BackupFolderPath) {
        $FilesToImport = Get-ChildItem "$BackupFolderPath\" | Where-Object { $_.Name -match "$RegexPart`_.+_\d{4}-\d{1,2}-\d{1,2}_\d{3,6}\.reg$" } 
        if ([string]::IsNullOrEmpty($FilesToImport)) {
            Write-Output "$(get-date -format u)  :  No backup files find in $BackupFolderPath" | Tee-Log -FilePath $LogName -Silent:$Passthru
        }
        else {
            Foreach ($FileToImport in $FilesToImport) {
                Write-Output "$(get-date -format u)  :  Importing '$($FileToImport.Name)' file to the registry" | Tee-Log -FilePath $LogName -Silent:$Passthru
                if ($WhatIf) {
                    Write-Output "$(get-date -format u)  :  Whatif switch selected so nothing changed..." | Tee-Log -FilePath $LogName -Silent:$Passthru
                }
                else {
                    REGEDIT /s $($FileToImport.FullName)
                }
                #Write-Output "$(get-date -format u)  :  Result : $($ImportResult -split '\r\n' | Where-Object {$_ -NotMatch '^$'})" | Tee-Log -FilePath $LogName -Silent:$Passthru 
            }
        }
    }
    else {
        Write-Output "$(get-date -format u)  :  Backup folder does not exists. Nothing to restore..." | Tee-Log -FilePath $LogName -Silent:$Passthru
    }
}
else {
    $ScriptExecutionResult = Fix-ServicePath `
        -FixUninstall:$FixUninstall `
        -FixServices:$FixServices `
        -WhatIf:$WhatIf `
        -FixEnv:$FixEnv `
        -Passthru:$Passthru `
        -Backup:$CreateBackup `
        -BackupFolder $BackupFolderPath 

    if ($Passthru -and (! [string]::IsNullOrEmpty($ScriptExecutionResult))) {
        $Objects = $ScriptExecutionResult | Where-Object { $_.GetType().Name -eq 'PSCustomObject' }
        $ScriptExecutionResult = $ScriptExecutionResult | Where-Object { $_.GetType().Name -ne 'PSCustomObject' }
    }

    $ScriptExecutionResult | Tee-Log -FilePath $LogName -Silent:$Passthru
    If ($Passthru) {
        If ($Silent -and $(( $Objects | Measure-Object ).Count -ge 1)) {
            $True
        }
        ElseIf ($Silent) {
            $False
        }
        Else {
            $Objects
        }
    }
}

if ($DeleteLogFile) {
    Remove-Item $LogName -Force -ErrorAction "SilentlyContinue"
}