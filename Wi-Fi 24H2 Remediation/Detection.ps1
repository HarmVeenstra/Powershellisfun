#Check Registry
if ((Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc | Select-Object -ExpandProperty DependOnService) -contains "WinHTTPAutoProxySvc") {
    Write-Output "WinHTTPAutoProxySvc key found in HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc, needs Remediation"
    $remediation = $true
}
else {
    Write-Output "WinHTTPAutoProxySvc key not found in HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc, no need for Remediation"
    $remediation = $false
}

#check service
if ((Get-Service -Name WinHttpAutoProxySvc).StartType -ne 'Manual') {
    Write-Output "WinHTTP Web Proxy Auto-Discovery Service not configured as Manual, needs Remediation"
    $remediation = $true
}
else {
    Write-Output "WinHTTP Web Proxy Auto-Discovery Service configured as Manual, no need for Remediation"
    $remediation = $false
}

#exit with correct exit code
if ($remediation) {
    exit 1
}
else {
    exit 0
}