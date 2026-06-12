$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\pubspec.yaml")) {
  throw "No estoy en la carpeta del proyecto Flutter. Falta pubspec.yaml."
}

Get-Command flutter -ErrorAction Stop | Out-Null

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

if (-not ($Defines -match '^--dart-define=APP_BASE_URL=')) {
  $Defines += "--dart-define=APP_BASE_URL=https://grupli.vercel.app"
}

Write-Host "Preparando dependencias web..." -ForegroundColor Cyan
flutter pub get

Write-Host "Analizando errores reales antes de web build..." -ForegroundColor Cyan
$AnalyzeOutput = flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1
$AnalyzeText = ($AnalyzeOutput | Out-String)
Write-Host $AnalyzeText
if ($LASTEXITCODE -ne 0 -or $AnalyzeText -match '(?m)^\s*error\s+-') {
  throw "flutter analyze tiene errores reales. Corrige los errores antes de compilar web."
}

Write-Host "Creando build web RELEASE..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons @Defines

$IndexPath = Join-Path $ProjectRoot "build\web\index.html"
if (Test-Path $IndexPath) {
  Write-Host "Build web creado correctamente:" -ForegroundColor Green
  Write-Host (Join-Path $ProjectRoot "build\web") -ForegroundColor Green
} else {
  throw "No encuentro build/web/index.html"
}
