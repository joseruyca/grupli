$ErrorActionPreference = "Stop"

cd "$PSScriptRoot\.."

Write-Host "Grupli v16.34 quality gate" -ForegroundColor Cyan

Select-String -Path ".\pubspec.yaml" -Pattern "version:|supabase_flutter|app_links"
Select-String -Path ".\vercel_build.sh" -Pattern "FLUTTER_VERSION|pub_get_reproducible|flutter build web"

flutter pub get
flutter analyze

if (Test-Path ".\.env") {
  Get-Content ".\.env" | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
      [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
    }
  }
}

$DartDefines = @()
if ($env:SUPABASE_URL) { $DartDefines += "--dart-define=SUPABASE_URL=$env:SUPABASE_URL" }
if ($env:SUPABASE_ANON_KEY) { $DartDefines += "--dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY" }
elseif ($env:SUPABASE_PUBLISHABLE_KEY) { $DartDefines += "--dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_PUBLISHABLE_KEY" }
$DartDefines += "--dart-define=APP_BASE_URL=https://grupli.vercel.app"

flutter build web --release --no-tree-shake-icons --no-wasm-dry-run @DartDefines

if (-not (Test-Path ".\build\web\index.html")) { throw "No se ha generado build/web/index.html" }
if (-not (Test-Path ".\build\web\main.dart.js")) { throw "No se ha generado build/web/main.dart.js" }

Write-Host "Grupli v16.34 OK" -ForegroundColor Green
