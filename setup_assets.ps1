# KochiGo v1.1 — Asset Setup Script
# Run this ONCE to download Poppins fonts and copy app icon
# Usage: .\setup_assets.ps1

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

Write-Host "📁 Creating asset directories..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$projectRoot\assets\fonts"  | Out-Null
New-Item -ItemType Directory -Force -Path "$projectRoot\assets\images" | Out-Null

# ─── Poppins Font Download ─────────────────────────────────────────────────
Write-Host "📦 Downloading Poppins fonts from Google..." -ForegroundColor Cyan

$fonts = @{
  "Poppins-Regular.ttf"  = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
  "Poppins-Medium.ttf"   = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
  "Poppins-SemiBold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
  "Poppins-Bold.ttf"     = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
}

foreach ($font in $fonts.GetEnumerator()) {
  $dest = "$projectRoot\assets\fonts\$($font.Key)"
  if (Test-Path $dest) {
    Write-Host "  ✅ $($font.Key) already exists — skipping" -ForegroundColor Green
  } else {
    Write-Host "  ⬇️  Downloading $($font.Key)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $font.Value -OutFile $dest -UseBasicParsing
    Write-Host "  ✅ $($font.Key)" -ForegroundColor Green
  }
}

# ─── App Icon Copy ──────────────────────────────────────────────────────────
Write-Host "`n🎨 Copying app icon..." -ForegroundColor Cyan

# Generated icon location — update this path if regenerated
$generatedIcon = "C:\Users\Ts\.gemini\antigravity\brain\18858b32-a893-4ec2-8649-46ef1332e145\kochigo_icon_1776510953110.png"
$iconDest      = "$projectRoot\assets\images\app_icon.png"

if (Test-Path $generatedIcon) {
  Copy-Item -Path $generatedIcon -Destination $iconDest -Force
  Write-Host "  ✅ app_icon.png copied" -ForegroundColor Green
} else {
  Write-Host "  ⚠️  Generated icon not found at:" -ForegroundColor Yellow
  Write-Host "     $generatedIcon" -ForegroundColor Yellow
  Write-Host "     Place your 1024x1024 PNG manually at: assets\images\app_icon.png" -ForegroundColor Yellow
}

# ─── Done ───────────────────────────────────────────────────────────────────
Write-Host "`n✨ Asset setup complete!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  1. flutter pub get"
Write-Host "  2. dart run flutter_launcher_icons"
Write-Host "  3. dart run flutter_native_splash:create"
Write-Host "  4. flutter run"
