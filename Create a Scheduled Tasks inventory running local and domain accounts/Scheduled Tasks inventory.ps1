$CSVlocation = 'C:\Temp\ScheduledTasks.csv'
$total = foreach ($server in Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object OperatingSystem -Match 'Windows Server' | Sort-Object Name) {

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
            Write-Host ("Processing Task {0} on {1}" -f $task.Name, $server.name)
        }
        catch {
            Write-Warning ("Could not read {0}" -f $task.FullName)
            $taskinfo = $null
        }
        
        if ($taskinfo.Task.Settings.Enabled -eq 'true' `
                -and $taskinfo.Task.Principals.Principal.GroupId -ne 'NT AUTHORITY\SYSTEM' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'AnyUser' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'Authenticated Users' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'AllUsers' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'LocalAdmin' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'LocalService' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'LocalSystem' `
                -and $taskinfo.Task.Principals.Principal.Id -ne 'Users' `
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
                -and $taskinfo.Task.Triggers.LogonTrigger.Enabled -ne 'True' 
        ) {
            [PSCustomObject]@{
                Server    = $Server.name
                TaskName  = $task.Name
                RunAsUser = $taskinfo.Task.Principals.Principal.UserId
            }    
        }
    }
}

$Total | Sort-Object Server, TaskName | Export-CSV -NoTypeInformation -Delimiter ';' -Encoding UTF8 -path $CSVlocation