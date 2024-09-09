$CSVlocation = 'C:\Temp\ScheduledTasks.csv'
$total = foreach ($server in Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*" -and Enabled -ne $False' | Sort-Object Name) {
    try {
        $scheduledtasks = Get-ChildItem "\\$($Server.name)\c$\Windows\System32\Tasks" -Recurse -File -ErrorAction Stop
        Write-Host ("Retrieving Scheduled Tasks list for {0}" -f $server.Name) -ForegroundColor Green
    }
    catch {
        Write-Warning ("Unable to retrieve Scheduled Tasks list for {0}" -f $server.Name)
        $scheduledtasks = $null
    }
    foreach ($task in $scheduledtasks | Sort-Object Name) {
        try {
            $taskinfo = [xml](Get-Content -Path $task.FullName -ErrorAction stop)
        }
        catch {
            Write-Warning ("Could not read {0}" -f $task.FullName)
            $taskinfo = $null
        }
        
        if ($taskinfo.Task.Settings.Enabled -eq 'true' `
                -and $taskinfo.Task.Principals.Principal.GroupId -ne 'NT AUTHORITY\SYSTEM' `
                -and $taskinfo.Task.Principals.Principal.GroupId -ne 'S-1-5-32-544' `
                -and $taskinfo.Task.Principals.Principal.LogonType -ne 'InteractiveToken' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'Administrators' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'EVERYONE' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'INTERACTIVE' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'LOCAL SERVICE' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'NETWORK SERVICE' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'NT AUTHORITY\SYSTEM' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'SYSTEM' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'S-1-5-18' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'S-1-5-19' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'S-1-5-20' `
                -and $taskinfo.Task.Principals.Principal.UserId -ne 'USERS' `
                -and $taskinfo.Task.Triggers.LogonTrigger.Enabled -ne 'True' `
                -and $null -ne $taskinfo.Task.Principals.Principal.UserId
        ) {
            [PSCustomObject]@{
                Server    = $Server.name
                TaskName  = $task.Name
                RunAsUser = $taskinfo.Task.Principals.Principal.UserId
            }    
        }
    }
}
if ($total.count -gt 0) {
    $Total | Sort-Object Server, TaskName | Export-Csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path $CSVlocation
    Write-Host ("Saved results to {0}" -f $CSVlocation) -ForegroundColor Green
}
else {
    Write-Warning ("No Scheduled Tasks were found running on local or Domain accounts")
}