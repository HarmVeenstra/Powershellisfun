#Check Registry
if ((Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc | Select-Object -ExpandProperty DependOnService) -contains "WinHTTPAutoProxySvc") {
    Write-Output "WinHTTPAutoProxySvc key found in HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc, needs Remediation"
    $remediationdepeondson = $true
}
else {
    Write-Output "WinHTTPAutoProxySvc key not found in HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc, no need for Remediation"
    $remediationdepeondson = $false
}

#check service
if ((Get-Service -Name WinHttpAutoProxySvc).StartType -ne 'Manual') {
    Write-Output "WinHTTP Web Proxy Auto-Discovery Service not configured as Manual, needs Remediation"
    $remediationstarttype = $true
}
else {
    Write-Output "WinHTTP Web Proxy Auto-Discovery Service configured as Manual, no need for Remediation"
    $remediationstarttype = $false
}

#exit with correct exit code
if ($remediationdepeondson -or $remediationstarttype) {
    exit 1
}
else {
    exit 0
}