#Change Dependency
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Wcmsvc -Name DependOnService -Value @('RpcSs', 'NSI') -Type MultiString

#Set Service WinHttpAutoProxySvc to Manual
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc -Name 'Start' -Value '3' -PropertyType DWORD -Force:$true

#Restart services
Restart-Service WcmSvc, WlanSvc -Force:$true -Confirm:$false