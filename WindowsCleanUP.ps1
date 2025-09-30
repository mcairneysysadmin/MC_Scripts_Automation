# Ensure script runs with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    exit
}

Write-Host "Starting full storage cleanup..." -ForegroundColor Cyan

# Clean Temp folders
Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\\Windows\\Temp\\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows Update cache
Write-Host "Stopping Windows Update service..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Write-Host "Cleaning Windows Update cache..." -ForegroundColor Yellow
Remove-Item -Path "C:\\Windows\\SoftwareDistribution\\Download\\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name wuauserv

# Empty Recycle Bin
Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
$shell = New-Object -ComObject Shell.Application
$recycleBin = $shell.Namespace(10)
$recycleBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }

# Clear Delivery Optimization files
Write-Host "Cleaning Delivery Optimization files..." -ForegroundColor Yellow
Remove-Item -Path "C:\\Windows\\ServiceProfiles\\NetworkService\\AppData\\Local\\Microsoft\\Windows\\DeliveryOptimization\\*" -Recurse -Force -ErrorAction SilentlyContinue

# Remove Windows.old and other unused Windows folders
Write-Host "Searching for Windows.old and unused Windows folders..." -ForegroundColor Yellow
$unusedFolders = Get-ChildItem -Path "C:\\" -Directory | Where-Object { $_.Name -match "Windows.old|Windows.~BT|Windows.~WS" }
foreach ($folder in $unusedFolders) {
    try {
        Write-Host "Taking ownership of $($folder.FullName)..." -ForegroundColor Yellow
        takeown /F $folder.FullName /R /D Y | Out-Null

        Write-Host "Granting full control permissions..." -ForegroundColor Yellow
        icacls $folder.FullName /grant administrators:F /T | Out-Null

        Write-Host "Deleting $($folder.FullName)..." -ForegroundColor Yellow
        Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
        Write-Host "Removed $($folder.FullName)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to remove $($folder.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Run Disk Cleanup silently
Write-Host "Running Disk Cleanup..." -ForegroundColor Yellow
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -NoNewWindow
Write-Host "✅ Full storage cleanup completed." -ForegroundColor Green
