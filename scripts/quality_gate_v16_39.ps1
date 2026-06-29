$ErrorActionPreference = "Stop"

cd "$PSScriptRoot\.."

Write-Host "Grupli v16.39 quality gate" -ForegroundColor Cyan

Select-String -Path ".\pubspec.yaml" -Pattern "version:|supabase_flutter|app_links"
Select-String -Path ".\vercel_build.sh" -Pattern "FLUTTER_VERSION|pub_get_reproducible|flutter build web"

$Pub = Get-Content ".\pubspec.yaml" -Raw
if ($Pub -notmatch "version:\s*0\.16\.39\+16390") { throw "pubspec.yaml no está en 0.16.39+16390" }
if ($Pub -notmatch "supabase_flutter:\s*2\.8\.3") { throw "supabase_flutter debe ser 2.8.3" }
if ($Pub -notmatch "app_links:\s*6\.4\.1") { throw "app_links debe ser 6.4.1" }

$Conflicts = Select-String -Path ".\pubspec.yaml", ".\vercel_build.sh", ".\lib\*.dart", ".\lib\**\*.dart" -Pattern "<<<<<<<|=======|>>>>>>>" -ErrorAction SilentlyContinue
if ($Conflicts) { $Conflicts; throw "Hay marcadores de conflicto Git." }

$Mojibake = Select-String -Path ".\pubspec.yaml", ".\vercel_build.sh", ".\README.md", ".\lib\*.dart", ".\lib\**\*.dart" -Pattern "Ã|Â|ï»¿|�" -ErrorAction SilentlyContinue
if ($Mojibake) { $Mojibake; throw "Hay posible mojibake." }

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

Write-Host "Grupli v16.39 OK" -ForegroundColor Green
