$adapters = Get-NetAdapterAdvancedProperty -DisplayName 'Idle Power Saving' | Where-Object DisplayValue -eq 'Disabled'
foreach ($adapter in $adapters) {
    Set-NetAdapterAdvancedProperty -InterfaceDescription $adapter.InterfaceDescription -DisplayName 'Idle Power Saving' -DisplayValue 'Enabled'
}