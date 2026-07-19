$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\pubspec.yaml")) {
  throw "No estoy en la carpeta del proyecto Flutter. Falta pubspec.yaml."
}

Get-Command flutter -ErrorAction Stop | Out-Null

$AndroidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path (Join-Path $AndroidStudioJbr "bin\java.exe")) {
  $env:JAVA_HOME = $AndroidStudioJbr
  $env:Path = "$(Join-Path $AndroidStudioJbr 'bin');$env:Path"
  Write-Host "Usando el JDK de Android Studio para Gradle." -ForegroundColor Cyan
}

. $PSScriptRoot\gradle_truststore.ps1
Initialize-GradleJavaTrustStore -ProjectRoot $ProjectRoot -AndroidStudioJbr $AndroidStudioJbr

if (-not (Test-Path ".\android")) {
  Write-Host "Creando carpeta Android con package com.joseruyca.grupli..." -ForegroundColor Cyan
  flutter create --platforms=android --org com.joseruyca --project-name grupli .
  Remove-Item ".\test" -Recurse -Force -ErrorAction SilentlyContinue
}

$EnvAliases = @{
  "SUPABASE_URL" = @(
    "SUPABASE_URL",
    "EXPO_PUBLIC_SUPABASE_URL",
    "VITE_SUPABASE_URL",
    "NEXT_PUBLIC_SUPABASE_URL",
    "FLUTTER_SUPABASE_URL"
  )
  "SUPABASE_ANON_KEY" = @(
    "SUPABASE_ANON_KEY",
    "SUPABASE_PUBLISHABLE_KEY",
    "EXPO_PUBLIC_SUPABASE_ANON_KEY",
    "EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
    "VITE_SUPABASE_ANON_KEY",
    "VITE_SUPABASE_PUBLISHABLE_KEY",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY",
    "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
    "SUPABASE_KEY",
    "FLUTTER_SUPABASE_ANON_KEY",
    "FLUTTER_SUPABASE_PUBLISHABLE_KEY"
  )
  "APP_BASE_URL" = @(
    "APP_BASE_URL",
    "EXPO_PUBLIC_APP_BASE_URL",
    "VITE_APP_BASE_URL",
    "NEXT_PUBLIC_APP_BASE_URL"
  )
  "OSM_GEOCODER_ENDPOINT" = @("OSM_GEOCODER_ENDPOINT", "EXPO_PUBLIC_OSM_GEOCODER_ENDPOINT", "VITE_OSM_GEOCODER_ENDPOINT", "NEXT_PUBLIC_OSM_GEOCODER_ENDPOINT")
  "FIREBASE_API_KEY" = @("FIREBASE_API_KEY", "EXPO_PUBLIC_FIREBASE_API_KEY", "VITE_FIREBASE_API_KEY", "NEXT_PUBLIC_FIREBASE_API_KEY")
  "FIREBASE_APP_ID" = @("FIREBASE_APP_ID", "EXPO_PUBLIC_FIREBASE_APP_ID", "VITE_FIREBASE_APP_ID", "NEXT_PUBLIC_FIREBASE_APP_ID")
  "FIREBASE_MESSAGING_SENDER_ID" = @("FIREBASE_MESSAGING_SENDER_ID", "EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID", "VITE_FIREBASE_MESSAGING_SENDER_ID", "NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID")
  "FIREBASE_PROJECT_ID" = @("FIREBASE_PROJECT_ID", "EXPO_PUBLIC_FIREBASE_PROJECT_ID", "VITE_FIREBASE_PROJECT_ID", "NEXT_PUBLIC_FIREBASE_PROJECT_ID")
  "FIREBASE_VAPID_KEY" = @("FIREBASE_VAPID_KEY", "EXPO_PUBLIC_FIREBASE_VAPID_KEY", "VITE_FIREBASE_VAPID_KEY", "NEXT_PUBLIC_FIREBASE_VAPID_KEY")
}

$EnvMap = @{}
if (Test-Path ".\.env") {
  foreach ($line in Get-Content ".\.env") {
    if ($line -match '^\s*#') { continue }
    if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
      $key = $matches[1].Trim()
      $value = $matches[2].Trim()
      if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if ($value.Length -gt 0) {
        $EnvMap[$key] = $value
      }
    }
  }
}

$Defines = @()
foreach ($target in $EnvAliases.Keys) {
  foreach ($alias in $EnvAliases[$target]) {
    if ($EnvMap.ContainsKey($alias)) {
      $Defines += "--dart-define=$target=$($EnvMap[$alias])"
      break
    }
  }
}

$RequiredDefines = @("SUPABASE_URL", "SUPABASE_ANON_KEY")
foreach ($required in $RequiredDefines) {
  $hasValue = $false
  foreach ($define in $Defines) {
    if ($define -like "--dart-define=$required=*") {
      $hasValue = $true
      break
    }
  }
  if (-not $hasValue) {
    throw "Falta $required en .env. Por seguridad Grupli ya no usa claves hardcodeadas en el frontend."
  }
}

Write-Host "Preparando Firebase Android/notificaciones..." -ForegroundColor Cyan
& "$PSScriptRoot\configure_firebase_android.ps1"

Write-Host "Preparando dependencias..." -ForegroundColor Cyan
flutter clean
flutter pub get

Write-Host "Analizando errores reales antes de crear APK..." -ForegroundColor Cyan
$AnalyzeOutput = flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1
$AnalyzeText = ($AnalyzeOutput | Out-String)
Write-Host $AnalyzeText
if ($LASTEXITCODE -ne 0 -or $AnalyzeText -match '(?m)^\s*error\s+-') {
  throw "flutter analyze tiene errores reales. Corrige los errores antes de crear la APK."
}

Write-Host "Creando APK DEBUG instalable..." -ForegroundColor Cyan
$FlutterStdOut = Join-Path $env:TEMP "grupli-flutter-build.out.log"
$FlutterStdErr = Join-Path $env:TEMP "grupli-flutter-build.err.log"
Remove-Item $FlutterStdOut, $FlutterStdErr -Force -ErrorAction SilentlyContinue
$FlutterArgs = @("build", "apk", "--debug") + $Defines
$FlutterProcess = Start-Process -FilePath "flutter" -ArgumentList $FlutterArgs -WorkingDirectory $ProjectRoot -NoNewWindow -Wait -PassThru -RedirectStandardOutput $FlutterStdOut -RedirectStandardError $FlutterStdErr
$BuildText = ""
if (Test-Path $FlutterStdOut) { $BuildText += Get-Content $FlutterStdOut -Raw }
if (Test-Path $FlutterStdErr) { $BuildText += Get-Content $FlutterStdErr -Raw }
Write-Host $BuildText
if ($FlutterProcess.ExitCode -ne 0) {
  throw "flutter build apk --debug falló."
}

$ApkPath = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $ApkPath) {
  Write-Host "APK creada correctamente:" -ForegroundColor Green
  Write-Host $ApkPath -ForegroundColor Green
} else {
  throw "No encuentro la APK generada en $ApkPath"
}
