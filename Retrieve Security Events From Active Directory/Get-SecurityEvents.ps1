function Get-SecurityEvents {
      param (
            [Parameter(Mandatory = $true, HelpMessage = "Number of hours to search back", Position = 1)][string]$hours,
            [Parameter(Mandatory = $true, HelpMessage = "Folder for storing found events", Position = 2)][string]$outputfolder,
            [Parameter(Mandatory = $False, HelpMessage = "Enter email-address to send the logs to", Position = 3)][string]$to_emailaddress,
            [Parameter(Mandatory = $False, HelpMessage = "Enter the From Address", Position = 4)][string]$from_emailaddress,
            [Parameter(Mandatory = $False, HelpMessage = "Enter the SMTP server to use", Position = 5)][string]$smtpserver
      )
      
      # Test admin privileges without using -Requires RunAsAdministrator,
      # which causes a nasty error message, if trying to load the function within a PS profile but without admin privileges
      if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
            Write-Warning ("Function {0} needs admin privileges, aborting..." -f $MyInvocation.MyCommand)
            break
      }

      #Get Domain Controller with PDC FSMO Role to get events from
      try {
            $domaincontroller = (Get-ADDomain).PDCEmulator
      }
      catch {
            Write-Warning ("Unable to get Domain information, check ActiveDirectory module installation. Aborting...")
      }

      #Event id's from https://www.ultimatewindowssecurity.com/securitylog/book/page.aspx?spid=chapter8
      $useraccountmanagementeventids = 
      4720, #A user account was created
      4722, #A user account was enabled
      4723, #An attempt was made to change an account's password
      4724, #An attempt was made to reset an accounts password
      4725, #A user account was disabled
      4726, #A user account was deleted
      4738, #A user account was changed
      4740, #A user account was locked out
      4767, #A user account was unlocked
      4780, #The ACL was set on accounts which are members of administrators groups
      4781, #The name of an account was changed
      4794, #n attempt was made to set the Directory Services Restore Mode administrator password
      5376, #Credential Manager credentials were backed up
      5377  #redential Manager credentials were restored from a backup

      $computeraccountmanagementeventids = 
      4741, #A computer account was created
      4742, #A computer account was changed
      4743  #A computer account was deleted
      
      $securitygroupmanagementeventids =
      4727, #A security-enabled global group was created
      4728, #A member was added to a security-enabled global group
      4729, #A member was removed from a security-enabled global group
      4730, #A security-enabled global group was deleted
      4731, #A security-enabled local group was created
      4732, #A member was added to a security-enabled local group
      4733, #A member was removed from a security-enabled local group
      4734, #A security-enabled local group was deleted
      4735, #A security-enabled local group was changed
      4737, #A security-enabled global group was changed
      4754, #A security-enabled universal group was created
      4755, #A security-enabled universal group was changed
      4756, #A member was added to a security-enabled universal group
      4757, #A member was removed from a security-enabled universal group
      4758, #A security-enabled universal group was deleted
      4764 #A groups type was changed
      
      $distributiongroupmanagementeventids =
      4744, #A security-disabled local group was created
      4745, #A security-disabled local group was changed
      4746, #A member was added to a security-disabled local group
      4747, #A member was removed from a security-disabled local group
      4748, #A security-disabled local group was deleted
      4749, #A security-disabled global group was created
      4750, #A security-disabled global group was changed
      4751, #A member was added to a security-disabled global group
      4752, #A member was removed from a security-disabled global group
      4753, #A security-disabled global group was deleted
      4759, #A security-disabled universal group was created
      4760, #A security-disabled universal group was changed
      4761, #A member was added to a security-disabled universal group
      4762, #A member was removed from a security-disabled universal group
      4763  #A security-disabled universal group was deleted

      $applicationgroupmanagementeventids =
      4783, #A basic application group was created
      4784, #A basic application group was changed
      4785, #A member was added to a basic application group
      4786, #A member was removed from a basic application group
      4787, #A non-member was added to a basic application group
      4788, #A non-member was removed from a basic application group
      4789, #A basic application group was deleted
      4790, #An LDAP query group was created
      4791, #A basic application group was changed
      4792  #An LDAP query group was deleted

      $otheraccountmanagementeventids =
      4739, #Domain Policy was changed
      4793  #The Password Policy Checking API was called


      #Set empty collection variable, date and eventids
      $collection = @()
      $date = (Get-Date).AddHours( - $($hours))
            
      $filteruseraccountmanagement = @{
            Logname   = 'Security'
            ID        = $useraccountmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      $filtercomputeraccountmanagement = @{
            Logname   = 'Security'
            ID        = $computeraccountmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      $filtersecuritygroupmanagement = @{
            Logname   = 'Security'
            ID        = $securitygroupmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      $filterdistributiongroupmanagement = @{
            Logname   = 'Security'
            ID        = $distributiongroupmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      $filterapplicationgroupmanagement = @{
            Logname   = 'Security'
            ID        = $applicationgroupmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      $filterotheraccountmanagement = @{
            Logname   = 'Security'
            ID        = $otheraccountmanagementeventids
            StartTime = $date
            EndTime   = [datetime]::Now
      }

      #Retrieve events
      Write-Host ("Retrieving Security events from {0}..." -f $domaincontroller) -ForegroundColor Green
      foreach ($eventids in `
                  $filteruseraccountmanagement, `
                  $filtercomputeraccountmanagement, `
                  $filtersecuritygroupmanagement, `
                  $filterdistributiongroupmanagement, `
                  $filterapplicationgroupmanagement, `
                  $filterotheraccountmanagement ) {
            $events = Get-WinEvent -FilterHashtable $eventids -ComputerName $domaincontroller -ErrorAction SilentlyContinue 
            foreach ($event in $events) {
                  Write-Host ("- Found EventID {0} on {1} and adding to list..." -f $event.id, $event.TimeCreated) -ForegroundColor Green
                  $eventfound = [PSCustomObject]@{
                        DomainController = $domaincontroller
                        Timestamp        = $event.TimeCreated
                        LevelDisplayName = $event.LevelDisplayName
                        EventId          = $event.Id
                        Message          = $event.message -replace '\s+', " "
                  }
                  $collection += $eventfound
            }
      }

      if ($null -ne $collection) {
            $filenametimestamp = Get-Date -Format 'dd-MM-yyyy-HHmm'
            Write-Host ("- Saving the {0} events found to {1}..." -f $collection.count, "$($outputfolder)\events_$($filenametimestamp).csv") -ForegroundColor Green
            $collection | Sort-Object TimeStamp, DomainController, EventId | Export-Csv -Delimiter ';' -NoTypeInformation -Path "$($outputfolder)\events_$($filenametimestamp).csv"
      
            if ($to_emailaddress) {
                  $emailoptions = @{
                        Attachments = "$($outputfolder)\events_$($filenametimestamp).csv"
                        Body        = "See Attached CSV file"
                        ErrorAction = "Stop"
                        From        = $from_emailaddress
                        Priority    = "High" 
                        SmtpServer  = $smtpserver
                        Subject     = "Security event found"
                        To          = $to_emailaddress
                  }
                  Write-Host ("- Emailing the {0} events found to {1}..." -f $collection.count, $to_emailaddress) -ForegroundColor Green
                  try {
                        Send-MailMessage @emailoptions 
                  }
                  catch {
                        Write-Warning ("Unable to email results, please check the email settings...")
                  }
            }
      }
}