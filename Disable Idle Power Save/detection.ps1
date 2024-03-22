try {
    $adapters = Get-NetAdapterAdvancedProperty -DisplayName 'Idle Power Saving' -ErrorAction SilentlyContinue | Where-Object RegistryValue -eq '1'
    if ($null -eq $adapters) {
        Write-Output 'No adapter(s) found with Idle Power Saving enabled, nothing to do...'
        exit 0
    }
    else {
        Write-Output 'Adapter(s) found with Idle Power Saving enabled, disabling now... '
        exit 1
    }
} 
catch {
    Write-Output 'No adapter(s) found with Idle Power Saving enabled, nothing to do...'
    exit 0
}