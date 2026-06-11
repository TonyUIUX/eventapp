#!/usr/bin/env pwsh
# build_release.ps1
# Usage: .\build_release.ps1 -TestKey rzp_test_xxx -ProdKey rzp_live_xxx -UseLive false `
#          -InstaKey your_key -InstaToken your_token -InstaSandbox false
param(
    [string]$TestKey      = "rzp_test_YOUR_KEY_HERE",
    [string]$ProdKey      = "rzp_live_YOUR_KEY_HERE",
    [string]$UseLive      = "false",
    # ── Instamojo params (additive — Razorpay params unchanged) ─────────────
    [string]$InstaKey     = "your_instamojo_api_key",
    [string]$InstaToken   = "your_instamojo_auth_token",
    [string]$InstaSandbox = "false"
)

Write-Host "Building Evorra Release AAB..." -ForegroundColor Cyan
Write-Host "  Razorpay Mode:  $( if ($UseLive -eq 'true') { 'LIVE' } else { 'TEST' } )" -ForegroundColor Yellow
Write-Host "  Instamojo Mode: $( if ($InstaSandbox -eq 'true') { 'SANDBOX' } else { 'LIVE' } )" -ForegroundColor Yellow

flutter build appbundle --release `
    "--dart-define=RAZORPAY_TEST_KEY=$TestKey" `
    "--dart-define=RAZORPAY_PROD_KEY=$ProdKey" `
    "--dart-define=USE_LIVE_RAZORPAY=$UseLive" `
    "--dart-define=INSTAMOJO_API_KEY=$InstaKey" `
    "--dart-define=INSTAMOJO_AUTH_TOKEN=$InstaToken" `
    "--dart-define=INSTAMOJO_SANDBOX=$InstaSandbox"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ AAB built successfully!" -ForegroundColor Green
    Write-Host "   Output: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
} else {
    Write-Host "`n❌ Build failed. Check errors above." -ForegroundColor Red
}
