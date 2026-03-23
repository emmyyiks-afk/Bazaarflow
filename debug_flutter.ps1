# Debug script to trace the error
Write-Host "=== TRACING FLUTTER STARTUP ===" -ForegroundColor Cyan

# Run Flutter with command tracing
$OriginalErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'

try {
    # This will show the actual error location
    & "C:\src\flutter\bin\flutter.bat" --version 2>&1 | 
        Out-File -FilePath "$env:TEMP\flutter_trace.log" -Encoding UTF8
    
    Write-Host "Trace saved to: $env:TEMP\flutter_trace.log" -ForegroundColor Green
    
    # Show relevant lines
    Get-Content "$env:TEMP\flutter_trace.log" | 
        Select-String -Pattern "update_dart_sdk|\.ps1|powershell|at line|error" -CaseSensitive
} finally {
    $ErrorActionPreference = $OriginalErrorActionPreference
}
