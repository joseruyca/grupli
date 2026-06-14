$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Security baseline audit v16.21" -ForegroundColor Cyan

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
  $script:failures.Add($message) | Out-Null
  Write-Host "ERROR: $message" -ForegroundColor Red
}

function Assert-FileContains([string]$path, [string]$pattern, [string]$message) {
  if (-not (Test-Path $path)) {
    Add-Failure "Falta $path"
    return
  }
  $content = Get-Content $path -Raw
  if ($content -notmatch $pattern) {
    Add-Failure $message
  }
}

Assert-FileContains ".gitignore" "(?m)^\.env$" ".gitignore debe ignorar .env"
Assert-FileContains ".gitignore" "android/app/google-services\.json" ".gitignore debe ignorar android/app/google-services.json"
Assert-FileContains ".gitignore" "ios/Runner/GoogleService-Info\.plist" ".gitignore debe ignorar ios/Runner/GoogleService-Info.plist"
Assert-FileContains ".gitignore" "\*\.keystore" ".gitignore debe ignorar keystores"
Assert-FileContains ".gitignore" "key\.properties" ".gitignore debe ignorar key.properties"

if (Get-Command git -ErrorAction SilentlyContinue) {
  $trackedEnv = git ls-files .env 2>$null
  if ($trackedEnv) {
    Add-Failure ".env está trackeado por Git. Ejecuta: git rm --cached .env -f"
  }
}

$frontendFiles = @()
foreach ($dir in @("lib", "web")) {
  if (Test-Path $dir) {
    $frontendFiles += Get-ChildItem $dir -Recurse -File | Where-Object {
      $_.Extension -in @(".dart", ".html", ".js", ".json", ".xml")
    }
  }
}

$forbiddenFrontendPatterns = @(
  @{
    Name = "JWT o token hardcodeado";
    Pattern = "eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}"
  },
  @{
    Name = "Supabase URL hardcodeada en frontend";
    Pattern = "https://[a-zA-Z0-9-]+\.supabase\.co"
  },
  @{
    Name = "service_role en frontend";
    Pattern = "SUPABASE_SERVICE_ROLE_KEY|service_role"
  },
  @{
    Name = "clave privada en frontend";
    Pattern = "-----BEGIN PRIVATE KEY-----|FIREBASE_PRIVATE_KEY|PRIVATE KEY"
  }
)

foreach ($file in $frontendFiles) {
  $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
  foreach ($rule in $forbiddenFrontendPatterns) {
    if ($content -match $rule.Pattern) {
      Add-Failure "$($rule.Name) detectado en $($file.FullName.Replace($ProjectRoot + '\', ''))"
    }
  }
}

# Edge Functions sí pueden leer secrets, pero nunca deben contener valores reales.
if (Test-Path "supabase/functions") {
  $edgeFiles = Get-ChildItem "supabase/functions" -Recurse -File | Where-Object { $_.Extension -in @(".ts", ".js") }
  foreach ($file in $edgeFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match "eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}") {
      Add-Failure "JWT hardcodeado detectado en Edge Function: $($file.FullName.Replace($ProjectRoot + '\', ''))"
    }
    # Las Edge Functions pueden contener las marcas PEM como texto para limpiar una clave leída desde Deno.env.
    # Lo peligroso es contener una clave PEM real completa hardcodeada en el archivo.
    if ($content -match "-----BEGIN PRIVATE KEY-----[\s\r\nA-Za-z0-9+/=]{80,}-----END PRIVATE KEY-----") {
      Add-Failure "Clave privada hardcodeada detectada en Edge Function: $($file.FullName.Replace($ProjectRoot + '\', ''))"
    }
  }
}

if (Test-Path "supabase/all_in_one.sql") {
  $sql = Get-Content "supabase/all_in_one.sql" -Raw
  if ($sql -notmatch "enable row level security") {
    Add-Failure "supabase/all_in_one.sql no contiene enable row level security"
  }
  if ($sql -notmatch "create policy") {
    Add-Failure "supabase/all_in_one.sql no contiene policies RLS"
  }
} else {
  Add-Failure "Falta supabase/all_in_one.sql"
}

foreach ($script in @("scripts/build_android_debug_apk.ps1", "scripts/build_android_release_apk.ps1", "scripts/build_web_release.ps1")) {
  if (-not (Test-Path $script)) {
    Add-Failure "Falta $script"
    continue
  }
  $content = Get-Content $script -Raw
  if ($content -notmatch "SUPABASE_URL" -or $content -notmatch "SUPABASE_ANON_KEY") {
    Add-Failure "$script debe pasar SUPABASE_URL y SUPABASE_ANON_KEY por --dart-define"
  }
  if ($content -notmatch 'Falta \$required') {
    Add-Failure "$script debe fallar si falta SUPABASE_URL o SUPABASE_ANON_KEY"
  }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "Security baseline NO superada." -ForegroundColor Red
  foreach ($failure in $failures) {
    Write-Host "- $failure" -ForegroundColor Red
  }
  exit 1
}

Write-Host "Security baseline superada: sin secretos hardcodeados detectados en frontend y RLS presente." -ForegroundColor Green
