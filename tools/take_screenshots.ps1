# tools\take_screenshots.ps1
# ─────────────────────────────────────────────────────────────────────────────
# Captures app screenshots via adb, using Android demo mode for a clean status
# bar.  Requires a phone with USB debugging enabled and the app already
# installed.  Run from the workspace root or the app directory.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\take_screenshots.ps1
#
# Prerequisites:
#   1. Phone connected with USB debugging
#   2. App installed (flutter install --release)
#   3. Parity images pushed to /sdcard/Pictures/parity/ (see below)
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$outDir = "$PSScriptRoot\..\..\..\07_docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$pkg = "edu.research.lemon_leaf_classifier"

# ── Helper ────────────────────────────────────────────────────────────────────
function Capture([string]$name) {
    Start-Sleep -Seconds 2
    & $adb exec-out screencap -p | Set-Content -Path "$outDir\$name.png" -AsByteStream
    Write-Host "  → Saved $name.png"
}

function AdbShell([string]$cmd) {
    & $adb shell $cmd | Out-Null
}

# ── 1. Enable Android demo mode ───────────────────────────────────────────────
Write-Host "Enabling demo mode..."
AdbShell "settings put global sysui_demo_allowed 1"
AdbShell "am broadcast -a com.android.systemui.demo -e command enter"
AdbShell "am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1200"
AdbShell "am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false"
AdbShell "am broadcast -a com.android.systemui.demo -e command notifications -e visible false"
AdbShell "am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e mobile show -e datatype lte -e level 4"

# ── 2. Launch app ─────────────────────────────────────────────────────────────
Write-Host "Launching app..."
AdbShell "am start -n $pkg/.MainActivity"
Start-Sleep -Seconds 3

# ── 3. Home screen ────────────────────────────────────────────────────────────
Write-Host "Capturing Home..."
Capture "01_home"

# ── 4. Push parity images to gallery (5 per class = 25 total) ─────────────────
# These are the first parity PNG from each class in assets/parity/
$parityDir = "$PSScriptRoot\..\assets\parity"
$classes = @{
    "00_citrus_huanglongbing" = "02_result_hlb"
    "01_citrus_leaf_curl"     = "03_result_leafcurl"
    "02_citrus_leafminer"     = "04_result_leafminer"
    "03_healthy_lemon_leaf"   = "05_result_healthy"
    "04_swallowtail_herbivory"= "06_result_swallowtail"
}

Write-Host "Pushing parity images to phone gallery..."
AdbShell "mkdir -p /sdcard/Pictures/parity"

foreach ($prefix in $classes.Keys) {
    $file = Get-ChildItem $parityDir -Filter "${prefix}_*.png" | Select-Object -First 1
    if ($file) {
        & $adb push $file.FullName "/sdcard/Pictures/parity/$($file.Name)" | Out-Null
        Write-Host "  Pushed $($file.Name)"
    }
}

# Trigger media scan
AdbShell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/parity/"
Start-Sleep -Seconds 2

# ── 5. Result screen for each class ──────────────────────────────────────────
# Navigate to Home, open gallery picker, select the parity image
# NOTE: This requires tapping through the gallery UI — the script opens the
# gallery intent for each image. Manual tap may be needed on first run to
# confirm storage permission.

foreach ($prefix in ($classes.Keys | Sort-Object)) {
    $screenName = $classes[$prefix]
    $file = Get-ChildItem $parityDir -Filter "${prefix}_*.png" | Select-Object -First 1
    if (-not $file) { Write-Host "  SKIP $prefix (no file)"; continue }

    Write-Host "Opening gallery for $prefix..."
    # Launch app home then trigger gallery via am
    AdbShell "am start -n $pkg/.MainActivity"
    Start-Sleep -Seconds 1

    # Open the image directly with the app's file provider by using
    # the ACTION_VIEW intent — the app's ImagePicker will handle it.
    # Alternatively, use am start-activity with the content URI.
    $remotePath = "/sdcard/Pictures/parity/$($file.Name)"
    AdbShell "am start -a android.intent.action.VIEW -t image/png -d file://$remotePath -n $pkg/.MainActivity"
    Start-Sleep -Seconds 4
    Capture $screenName
}

# ── 6. Unable to determine screen ────────────────────────────────────────────
# Use the first parity image (should pass quality gate for accepted result)
# To get an Unable-to-determine screen, push a low-contrast or blurry image.
# Using a dark test image — push a black PNG if available, otherwise skip.
Write-Host "Attempting Unable-to-determine screen..."
AdbShell "am start -n $pkg/.MainActivity"
Start-Sleep -Seconds 2
Capture "07_unable_to_determine_placeholder"

# ── 7. History screen ─────────────────────────────────────────────────────────
Write-Host "Capturing History..."
AdbShell "am start -n $pkg/.MainActivity"
Start-Sleep -Seconds 1
# Tap History icon (approximate coordinates for 1080p — adjust if needed)
AdbShell "input tap 920 100"
Start-Sleep -Seconds 2
Capture "08_history"

# ── 8. About screen ───────────────────────────────────────────────────────────
Write-Host "Capturing About..."
AdbShell "am start -n $pkg/.MainActivity"
Start-Sleep -Seconds 1
# Tap About icon (rightmost in AppBar)
AdbShell "input tap 1050 100"
Start-Sleep -Seconds 2
Capture "09_about"

# ── 9. Exit demo mode ─────────────────────────────────────────────────────────
Write-Host "Exiting demo mode..."
AdbShell "am broadcast -a com.android.systemui.demo -e command exit"
AdbShell "settings put global sysui_demo_allowed 0"

Write-Host ""
Write-Host "Screenshots saved to: $outDir"
Write-Host "DONE."
