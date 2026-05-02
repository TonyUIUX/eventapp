#!/usr/bin/env pwsh
# build_release.ps1
# Usage: .\build_release.ps1 -TestKey rzp_test_xxx -ProdKey rzp_live_xxx -UseLive false
param(
    [string]$TestKey = "rzp_test_YOUR_KEY_HERE",
    [string]$ProdKey = "rzp_live_YOUR_KEY_HERE",
    [string]$UseLive = "false"
)

Write-Host "Building KochiGo Release AAB..." -ForegroundColor Cyan
Write-Host "  Razorpay Mode: $( if ($UseLive -eq 'true') { 'LIVE' } else { 'TEST' } )" -ForegroundColor Yellow

flutter build appbundle --release `
    "--dart-define=RAZORPAY_TEST_KEY=$TestKey" `
    "--dart-define=RAZORPAY_PROD_KEY=$ProdKey" `
    "--dart-define=USE_LIVE_RAZORPAY=$UseLive"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ AAB built successfully!" -ForegroundColor Green
    Write-Host "   Output: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
    Write-Host "`n❌ Build failed. Check errors above." -ForegroundColor Red
}
