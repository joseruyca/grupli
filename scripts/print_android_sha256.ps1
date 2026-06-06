$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

if (-not (Test-Path ".\android")) {
  Write-Host "Creando carpeta Android para poder calcular huellas SHA256..." -ForegroundColor Cyan
  flutter create --platforms=android --org com.joseruyca --project-name grupli .
  Remove-Item ".\test" -Recurse -Force -ErrorAction SilentlyContinue
}

Set-Location ".\android"
Write-Host "Buscando SHA256 de las firmas Android..." -ForegroundColor Cyan
.\gradlew signingReport

Write-Host ""
Write-Host "Copia el SHA256 que corresponda a la variante debug/release y ponlo en:" -ForegroundColor Yellow
Write-Host "web/.well-known/assetlinks.json" -ForegroundColor Yellow
Write-Host "Después sube a GitHub para que Vercel publique https://grupli.vercel.app/.well-known/assetlinks.json" -ForegroundColor Yellow
