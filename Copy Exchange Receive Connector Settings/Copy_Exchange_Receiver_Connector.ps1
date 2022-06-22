#Add Microsoft Exchange snapins
Add-PSSnapin Microsoft.Exchange*
 
#Set variables
$receiveconnector = Get-receiveconnector | Out-GridView -OutputMode Single -Title 'Please select the Receive Connector to copy the settings from and click OK'
$newserver = Get-ExchangeServer | Out-GridView -OutputMode Single -Title 'Please select destination server to create the Receive Connector on and click OK'
 
#Set the options for creating the Receive Connector
$options = @{
    Bindings             = $receiveconnector.Bindings
    Enabled              = $receiveconnector.Enabled
    MaxHopCount          = $receiveconnector.MaxHopCount
    MaxLocalHopCount     = $receiveconnector.MaxLocalHopCount
    MaxMessageSize       = $receiveconnector.MaxMessageSize
    MessageRateLimit     = $receiveconnector.MessageRateLimit
    Name                 = $receiveconnector.Identity.Name
    PermissionGroups     = $receiveconnector.PermissionGroups.ToString().Split(',')[0]
    ProtocolLoggingLevel = $receiveconnector.ProtocolLoggingLevel
    RemoteIPRanges       = $receiveconnector.RemoteIPRanges
    Server               = $newserver
    SizeEnabled          = $receiveconnector.SizeEnabled
    TransportRole        = $receiveconnector.TransportRole
    Usage                = 'Custom'
    WhatIf               = $True
     
}
 
#Create new Receive Connector and copy the settings from the existing one
New-ReceiveConnector @options