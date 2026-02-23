# =====================================================
# Linguabot Flutter Build Automation Script
# Author: Sathya Prakash
# Path: D:\Linguabot\lingua_bot\build.ps1
# Purpose: Cleans, rebuilds, and generates APK safely
# =====================================================

# --- Change directory to project root ---
Set-Location "D:\Linguabot\lingua_bot"

Write-Host "🧹 Cleaning previous Flutter build..." -ForegroundColor Yellow
flutter clean | Out-Null

# --- Remove build artifacts ---
Write-Host "🧩 Removing temporary folders (.gradle, .dart_tool, build)..." -ForegroundColor Yellow
Remove-Item -Recurse -Force build, .dart_tool, .gradle, "android\.gradle" -ErrorAction SilentlyContinue

# --- Reinstall dependencies ---
Write-Host "📦 Fetching Flutter dependencies..." -ForegroundColor Cyan
flutter pub get | Out-Null

# --- Clean Gradle ---
Write-Host "🧰 Cleaning Gradle cache..." -ForegroundColor Yellow
Set-Location "android"
.\gradlew clean | Out-Null
Set-Location ".."

# --- Build APK ---
Write-Host "⚙️ Building APK (Release Mode, No Tree Shake Icons)..." -ForegroundColor Green
flutter build apk --no-tree-shake-icons

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "📦 APK location: D:\Linguabot\lingua_bot\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ BUILD FAILED. Please check above errors." -ForegroundColor Red
}

Write-Host "`n🚀 Build process completed!" -ForegroundColor Green
# =====================================================
