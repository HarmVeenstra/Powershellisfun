function Send-Tweet {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the message in 140 characters or less")][string]$Message
    )
    #Validate length of message
    if ($message.Length -gt 140) {
        Write-Warning ("Length of tweet is {0} characters, maximum amount is 140. Aborting..." -f $Message.Length)
        break
    }
    
    try {
        $status = [System.Uri]::EscapeDataString("$($Message)")  
        $oauth_consumer_key = 'xxxxxxxxxxxx'  #API Key
        $oauth_consumer_secret = 'xxxxxxxxxxxx'  #API Key Secret
        $oauth_token = 'xxxxxx-xxxxxxxxxx'  #Access Token
        $oauth_token_secret = 'xxxxxxxxxxxxxxxx'  #Access Token Secret
        $culture = New-Object  -TypeName System.Globalization.CultureInfo -ArgumentList ('en-US')
        $oauth_nonce = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes([System.DateTime]::Now.Ticks.ToString()))  
        $ts = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact('01/01/1970', 'dd/MM/yyyy', $culture).ToUniversalTime()  
        $oauth_timestamp = [System.Convert]::ToInt64($ts.TotalSeconds).ToString()  
  
        $signature = 'POST&'  
        $signature += [System.Uri]::EscapeDataString('https://api.twitter.com/1.1/statuses/update.json') + '&'  
        $signature += [System.Uri]::EscapeDataString('oauth_consumer_key=' + $oauth_consumer_key + '&')  
        $signature += [System.Uri]::EscapeDataString('oauth_nonce=' + $oauth_nonce + '&')   
        $signature += [System.Uri]::EscapeDataString('oauth_signature_method=HMAC-SHA1&')  
        $signature += [System.Uri]::EscapeDataString('oauth_timestamp=' + $oauth_timestamp + '&')  
        $signature += [System.Uri]::EscapeDataString('oauth_token=' + $oauth_token + '&')  
        $signature += [System.Uri]::EscapeDataString('oauth_version=1.0a&')  
        $signature += [System.Uri]::EscapeDataString('status=' + $status)  
  
        $signature_key = [System.Uri]::EscapeDataString($oauth_consumer_secret) + '&' + [System.Uri]::EscapeDataString($oauth_token_secret)  
  
        $hmacsha1 = New-Object  -TypeName System.Security.Cryptography.HMACSHA1  
        $hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($signature_key)  
        $oauth_signature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($signature)))  
  
        $oauth_authorization = 'OAuth '  
        $oauth_authorization += 'oauth_consumer_key="' + [System.Uri]::EscapeDataString($oauth_consumer_key) + '",'  
        $oauth_authorization += 'oauth_nonce="' + [System.Uri]::EscapeDataString($oauth_nonce) + '",'  
        $oauth_authorization += 'oauth_signature="' + [System.Uri]::EscapeDataString($oauth_signature) + '",'  
        $oauth_authorization += 'oauth_signature_method="HMAC-SHA1",'  
        $oauth_authorization += 'oauth_timestamp="' + [System.Uri]::EscapeDataString($oauth_timestamp) + '",'  
        $oauth_authorization += 'oauth_token="' + [System.Uri]::EscapeDataString($oauth_token) + '",'  
        $oauth_authorization += 'oauth_version="1.0a"'  
  
        $post_body = [System.Text.Encoding]::ASCII.GetBytes('status=' + $status)   
        [System.Net.HttpWebRequest] $request = [System.Net.WebRequest]::Create('https://api.twitter.com/1.1/statuses/update.json')  
        $request.Method = 'POST'  
        $request.Headers.Add('Authorization', $oauth_authorization)  
        $request.ContentType = 'application/x-www-form-urlencoded'  
        $body = $request.GetRequestStream()  
        $body.write($post_body, 0, $post_body.length)  
        $body.flush()  
        $body.close()  
        $response = $request.GetResponse()  
    }

    catch {
        Write-Warning ("Something went wrong, tweet '{0}' is not tweeted..." -f $Message)
    }
}