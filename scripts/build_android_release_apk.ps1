$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\pubspec.yaml")) {
  throw "No estoy en la carpeta del proyecto Flutter. Falta pubspec.yaml."
}

Get-Command flutter -ErrorAction Stop | Out-Null

if (-not (Test-Path ".\android")) {
  Write-Host "Creando carpeta Android con package com.joseruyca.grupli..." -ForegroundColor Cyan
  flutter create --platforms=android --org com.joseruyca --project-name grupli .
  Remove-Item ".\test" -Recurse -Force -ErrorAction SilentlyContinue
}

$Keys = @(
  "SUPABASE_URL",
  "SUPABASE_ANON_KEY",
  "APP_BASE_URL",
  "OSM_GEOCODER_ENDPOINT",
  "FIREBASE_API_KEY",
  "FIREBASE_APP_ID",
  "FIREBASE_MESSAGING_SENDER_ID",
  "FIREBASE_PROJECT_ID",
  "FIREBASE_VAPID_KEY"
)

$Defines = @()
if (Test-Path ".\.env") {
  foreach ($line in Get-Content ".\.env") {
    if ($line -match '^\s*#') { continue }
    if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
      $key = $matches[1].Trim()
      $value = $matches[2].Trim()
      if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if ($Keys -contains $key -and $value.Length -gt 0) {
        $Defines += "--dart-define=$key=$value"
      }
    }
  }
}

Write-Host "Preparando Firebase Android/notificaciones..." -ForegroundColor Cyan
& "$PSScriptRoot\configure_firebase_android.ps1"

Write-Host "Preparando dependencias..." -ForegroundColor Cyan
flutter clean
flutter pub get

Write-Host "Creando APK RELEASE de prueba..." -ForegroundColor Cyan
flutter build apk --release @Defines

$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $ApkPath) {
  Write-Host "APK creada correctamente:" -ForegroundColor Green
  Write-Host $ApkPath -ForegroundColor Green
} else {
  throw "No encuentro la APK generada en $ApkPath"
}
