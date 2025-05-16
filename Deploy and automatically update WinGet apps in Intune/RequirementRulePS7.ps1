if (Test-Path -LiteralPath 'C:\Program Files\PowerShell\7\pwsh.exe') {
    Write-Output 'Required_PowerShell_v7_Found'
    exit 0
}
else {
    Write-Output 'Required_PowerShell_v7_Not_Found'
    exit 1
}