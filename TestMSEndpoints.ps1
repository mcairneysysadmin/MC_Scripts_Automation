# Define endpoints
$endpoints = @(
    "https://login.microsoftonline.com",
    "https://graph.microsoft.com",
    "https://device.login.microsoftonline.com",
    "https://manage.microsoft.com",
    "https://portal.manage.microsoft.com",
    "https://windowsupdate.microsoft.com",
    "https://update.microsoft.com",
    "https://delivery.mp.microsoft.com",
    "https://settings-win.data.microsoft.com",
    "https://v10.events.data.microsoft.com",
    "https://fe3.delivery.mp.microsoft.com",
    "https://sls.update.microsoft.com",
    "https://dl.delivery.mp.microsoft.com"
)

# Define log path
$logFolder = "C:\Scripts\Output"
$logFile = "IntuneConnectivityTest.log"
$logPath = Join-Path -Path $logFolder -ChildPath $logFile

# Create folder if it doesn't exist
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

# Start log
Add-Content -Path $logPath -Value "Intune Connectivity Test Log - $(Get-Date)"
Add-Content -Path $logPath -Value ("=" * 60)

# Test each endpoint
foreach ($url in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        Add-Content -Path $logPath -Value "✅ $url is reachable (Status: $($response.StatusCode))"
    } catch {
        Add-Content -Path $logPath -Value "❌ $url is NOT reachable. Error: $($_.Exception.Message)"
    }
}

# Notify user
Write-Host "Connectivity test completed. Results saved to: $logPath" -ForegroundColor Cyan
