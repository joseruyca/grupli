$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Dest = "$env:USERPROFILE\Desktop\grupliv2"
if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }

Write-Host "Antes de ejecutar este script, descomprime el ZIP manualmente o usa el bloque de instalación del chat." -ForegroundColor Yellow
Write-Host "Este archivo queda como recordatorio: conservar siempre .env y .git, no copiar dentro de una subcarpeta." -ForegroundColor Yellow
