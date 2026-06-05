$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $ApkPath)) {
  throw "No existe app-debug.apk. Ejecuta primero .\scripts\build_android_debug_apk.ps1"
}

Get-Command adb -ErrorAction Stop | Out-Null
adb devices
adb install -r $ApkPath
