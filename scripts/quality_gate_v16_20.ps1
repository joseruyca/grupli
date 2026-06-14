param(
  [switch]$SkipApk,
  [switch]$SkipWeb
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\pubspec.yaml")) {
  throw "No estoy en la carpeta del proyecto Flutter. Falta pubspec.yaml."
}

Get-Command flutter -ErrorAction Stop | Out-Null

Write-Host "Grupli quality gate v16.21" -ForegroundColor Cyan
Write-Host "0/6 Auditoría base de seguridad" -ForegroundColor Cyan
& "$PSScriptRoot\security_audit_v16_21.ps1"

Write-Host "1/6 Limpieza local" -ForegroundColor Cyan
Remove-Item ".\test" -Recurse -Force -ErrorAction SilentlyContinue
flutter clean
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "2/6 Dependencias" -ForegroundColor Cyan
flutter pub get

Write-Host "3/6 flutter analyze sin errores reales" -ForegroundColor Cyan
$AnalyzeOutput = flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1
$AnalyzeText = ($AnalyzeOutput | Out-String)
Write-Host $AnalyzeText
if ($LASTEXITCODE -ne 0 -or $AnalyzeText -match '(?m)^\s*error\s+-') {
  throw "flutter analyze tiene errores reales. No se puede cerrar Fase 0."
}

if (-not $SkipApk) {
  Write-Host "4/6 APK debug" -ForegroundColor Cyan
  & "$PSScriptRoot\build_android_debug_apk.ps1"
} else {
  Write-Host "4/6 APK debug saltada por parámetro -SkipApk" -ForegroundColor Yellow
}

if (-not $SkipWeb) {
  Write-Host "5/6 Build web" -ForegroundColor Cyan
  & "$PSScriptRoot\build_web_release.ps1"
} else {
  Write-Host "5/6 Build web saltado por parámetro -SkipWeb" -ForegroundColor Yellow
}

Write-Host "Quality gate completado sin errores reales." -ForegroundColor Green
