$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Get-Command supabase -ErrorAction Stop | Out-Null

if (-not (Test-Path ".\supabase\functions\send-push\index.ts")) {
  throw "No encuentro supabase/functions/send-push/index.ts"
}

Write-Host "Desplegando Edge Function send-push..." -ForegroundColor Cyan
supabase functions deploy send-push --no-verify-jwt

Write-Host "Función desplegada. Ahora configura secretos con:" -ForegroundColor Green
Write-Host "supabase secrets set SUPABASE_URL=..." -ForegroundColor Yellow
Write-Host "supabase secrets set SUPABASE_SERVICE_ROLE_KEY=..." -ForegroundColor Yellow
Write-Host "supabase secrets set FIREBASE_PROJECT_ID=..." -ForegroundColor Yellow
Write-Host "supabase secrets set FIREBASE_CLIENT_EMAIL=..." -ForegroundColor Yellow
Write-Host "supabase secrets set FIREBASE_PRIVATE_KEY=`"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n`"" -ForegroundColor Yellow
Write-Host "Después crea el Database Webhook: table notifications + INSERT + Edge Function send-push." -ForegroundColor Cyan
