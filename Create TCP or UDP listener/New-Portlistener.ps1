function New-Portlistener {
    param (
        [parameter(Mandatory = $false, HelpMessage = "Enter the tcp port you want to use to listen on, for example 3389")]
        [ValidatePattern('^[0-9]+$')]
        [ValidateRange(0, 65535)]
        [int]$TCPPort,

        [parameter(Mandatory = $false, HelpMessage = "Enter the udp port you want to use to listen on, for example 3389")]
        [ValidatePattern('^[0-9]+$')]
        [ValidateRange(0, 65535)]
        [int]$UDPPort
    )
    
    #Exit if both options were used
    if ($TCPPort -and $UDPPort) {
        Write-Warning "You can only specify one other, use either TCPPort or UDPPort. Aborting..."
        break
    }

    #Test if TCP port is already listening port before starting listener
    if ($TCPPort) {
        $Global:ProgressPreference = 'SilentlyContinue' #Hide GUI output
        $testtcpport = Test-NetConnection -ComputerName localhost -Port $TCPPort -WarningAction SilentlyContinue -ErrorAction Stop
        if ($testtcpport.TcpTestSucceeded -ne $True) {
            Write-Host ("TCP port {0} is available, continuing..." -f $TCPPort) -ForegroundColor Green
        }
        else {
            Write-Warning ("TCP Port {0} is already listening, aborting..." -f $TCPPort)
            break
        }

        #Start TCP Server
        #Used procedure from https://riptutorial.com/powershell/example/18117/tcp-listener
        $ipendpoint = new-object System.Net.IPEndPoint([ipaddress]::any, $TCPPort) 
        $listener = new-object System.Net.Sockets.TcpListener $ipendpoint
        $listener.start()
        Write-Host ("Now listening on TCP port {0}, press Escape to stop listening" -f $TCPPort) -ForegroundColor Green
        while ( $true ) {
            if ($host.ui.RawUi.KeyAvailable) {
                $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
                if ($key.VirtualKeyCode -eq 27 ) {	
                    $listener.stop()
                    Write-Host ("Stopped listening on TCP port {0}" -f $TCPPort) -ForegroundColor Green
                    break
                }
            }
        }
    }
        
    
    #Test if UDP port is already listening port before starting listener
    if ($UDPPort) {
        #Used procedure from https://cloudbrothers.info/en/test-udp-connection-powershell/
        try {
            # Create a UDP client object
            $UdpObject = New-Object system.Net.Sockets.Udpclient($UDPPort)
            # Define connect parameters
            $computername = "localhost"
            $UdpObject.Connect($computername, $UDPPort)    
        
            # Convert current time string to byte array
            $ASCIIEncoding = New-Object System.Text.ASCIIEncoding
            $Bytes = $ASCIIEncoding.GetBytes("$(Get-Date -UFormat "%Y-%m-%d %T")")
            # Send data to server
            [void]$UdpObject.Send($Bytes, $Bytes.length)    
        
            # Cleanup
            $UdpObject.Close()
            Write-Host ("UDP port {0} is available, continuing..." -f $UDPPort) -ForegroundColor Green
        }
        catch {
            Write-Warning ("UDP Port {0} is already listening, aborting..." -f $UDPPort)
            break
        }

        #Start UDP Server
        #Used procedure from https://github.com/sperner/PowerShell/blob/master/UdpServer.ps1
        $endpoint = new-object System.Net.IPEndPoint( [IPAddress]::Any, $UDPPort)
        $udpclient = new-object System.Net.Sockets.UdpClient $UDPPort
        Write-Host ("Now listening on UDP port {0}, press Escape to stop listening" -f $UDPPort) -ForegroundColor Green
        while ( $true ) {
            if ($host.ui.RawUi.KeyAvailable) {
                $key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
                if ($key.VirtualKeyCode -eq 27 ) {	
                    $udpclient.Close()
                    Write-Host ("Stopped listening on UDP port {0}" -f $UDPPort) -ForegroundColor Green
                    break
                }
            }

            if ( $udpclient.Available ) {
                $content = $udpclient.Receive( [ref]$endpoint )
                Write-Host "$($endpoint.Address.IPAddressToString):$($endpoint.Port) $([Text.Encoding]::ASCII.GetString($content))"
            }
        }
    }
}
