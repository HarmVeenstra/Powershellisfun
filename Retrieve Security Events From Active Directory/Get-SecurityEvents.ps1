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
            Write-Warning ('Function "{0}" needs admin privileges, aborting...' -f $MyInvocation.MyCommand)
            break
      }

      #Get Domain Controller with PDC FSMO Role to get events from
      try {
            $domaincontroller = (Get-ADDomain).PDCEmulator
      }
      catch {
            Write-Warning 'Unable to get Domain information, check ActiveDirectory module installation. Aborting...'
      }

      #Event id's from https://www.ultimatewindowssecurity.com/securitylog/book/page.aspx?spid=chapter8
      $useraccountmanagementeventids = 
      4720,
      4722,
      4723,
      4724,
      4725,
      4726,
      4738,
      4740,
      4767,
      4780,
      4781,
      4794,
      5376,
      5377

      $computeraccountmanagementeventids = 
      4741,
      4742,
      4743
      
      $securitygroupmanagementeventids =
      4727,
      4728,
      4729,
      4730,
      4731,
      4732,
      4733,
      4734,
      4735,
      4737,
      4754,
      4755,
      4756,
      4757,
      4758,
      4764
      
      $distributiongroupmanagementeventids =
      4744,
      4745,
      4746,
      4747,
      4748,
      4749,
      4750,
      4751,
      4752,
      4753,
      4759,
      4760,
      4761,
      4762,
      4763

      $applicationgroupmanagementeventids =
      4783,
      4784,
      4785,
      4786,
      4787,
      4788,
      4789,
      4790,
      4791,
      4792

      $otheraccountmanagementeventids =
      4739,
      4793


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
      Write-Host ('Retrieving Security events from {0}...' -f $domaincontroller) -ForegroundColor Green
      foreach ($eventids in `
                  $filteruseraccountmanagement, `
                  $filtercomputeraccountmanagement, `
                  $filtersecuritygroupmanagement, `
                  $filterdistributiongroupmanagement, `
                  $filterapplicationgroupmanagement, `
                  $filterotheraccountmanagement ) {
            $events = Get-WinEvent -FilterHashtable $eventids -ComputerName $domaincontroller -ErrorAction SilentlyContinue 
            foreach ($event in $events) {
                  Write-Host ('- Found EventID {0} on {1} and adding to list...' -f $event.id, $event.TimeCreated) -ForegroundColor Green
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
            Write-Host ('- Saving the {0} events found to {1}...' -f $collection.count, "$($outputfolder)\events_$($filenametimestamp).csv") -ForegroundColor Green
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
                  Write-Host ('- Emailing the {0} events found to {1}...' -f $collection.count, $to_emailaddress) -ForegroundColor Green
                  try {
                        Send-MailMessage @emailoptions 
                  }
                  catch {
                        Write-Warning 'Unable to email results, please check the email settings...'
                  }
            }
      }
}