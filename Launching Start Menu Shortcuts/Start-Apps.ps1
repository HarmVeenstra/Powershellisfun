#Set Filter, use '' as Default
param (
    [parameter(Mandatory = $false)][string[]]$Filter = ''
)

#Retrieve list of applications based on $Filter
foreach ($Item in $Filter) {
    if (Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Start Menu\*.lnk" -Recurse | Where-Object Name -Match $Item) {
        $Apps += Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Start Menu\*.lnk" -Recurse | Where-Object Name -Match $Item
    }
    if (Get-ChildItem -Path "$($ENV:APPDATA)\Microsoft\Windows\Start Menu\Programs\*.lnk" -Recurse | Where-Object Name -Match $Item) {
        $Apps += Get-ChildItem -Path "$($ENV:APPDATA)\Microsoft\Windows\Start Menu\Programs\*.lnk" -Recurse | Where-Object Name -Match $Item
    }
}

#Add applications to $Total
$Total = foreach ($App in $Apps) {
    [PSCustomObject]@{
        Name     = $App.Name.Replace('.lnk', '')
        Shortcut = $app.Fullname
    }
}

#Check if Out-ConsoleGridView is installed if running from PowerShell v7
if ($host.Version.Major -ge 7) {
    try {
        Import-Module Microsoft.PowerShell.ConsoleGuiTools -ErrorAction Stop
    }
    catch {
        Write-Warning ("Microsoft.PowerShell.ConsoleGuiTools module was not installed, installing now...")
        try {
            Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -ErrorAction Stop
        }
        catch {
            Write-Warning ("Error installing Microsoft.PowerShell.ConsoleGuiTools module, exiting...")
            return
        }
    }
}

#Output to Gridview for selection, start selected applications or exit when nothing was selected
if ($null -ne $Total) {
    if ($host.Version.Major -ge 7) {
        $SelectedPrograms = $Total | Sort-Object Name, Shortcut | Out-ConsoleGridView -Title 'Select the program(s) to start, press Escape to stop' -OutputMode Multiple
    }
    else {
        $SelectedPrograms = $Total | Sort-Object Name, Shortcut | Out-GridView -Title 'Select the program(s) to start, press Escape to stop' -OutputMode Multiple
    }
    if ($null -ne $SelectedPrograms) {
        foreach ($Program in $SelectedPrograms) {
            try {
                Invoke-Item -Path $Program.Shortcut -ErrorAction Stop
                Write-Host ("Starting {0}" -f $Program.Name) -ForegroundColor Green
            }
            catch {
                Write-Warning ("Error starting {0}" -f $Program.Name)
            }
        }
    }
    else {
        Write-Host ("No program(s) selected, exiting...") -ForegroundColor Green
        return
    }
}
else {
    Write-Warning ("No programs found based on filter {0}, exiting" -f $Filter)
    return
}