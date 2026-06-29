$ErrorActionPreference = "Stop"

cd "$env:USERPROFILE\Desktop\grupliv2"

Write-Host "Grupli quality gate v16.33" -ForegroundColor Cyan

if (Test-Path ".git\rebase-merge") { throw "Hay un rebase abierto." }
if (Test-Path ".git\rebase-apply") { throw "Hay un rebase abierto." }
if (Test-Path ".git\MERGE_HEAD") { throw "Hay un merge abierto." }

$Required = @("pubspec.yaml", "lib\main.dart", "web\index.html", "vercel_build.sh", "vercel.json")
foreach ($File in $Required) {
  if (-not (Test-Path $File)) { throw "Falta archivo clave: $File" }
}

$Conflict = Select-String -Path ".\pubspec.yaml", ".\vercel_build.sh", ".\lib\*.dart", ".\lib\**\*.dart" -Pattern "<<<<<<<|=======|>>>>>>>" -ErrorAction SilentlyContinue
if ($Conflict) {
  $Conflict
  throw "Hay conflictos Git sin resolver."
}

$Mojibake = Select-String -Path ".\pubspec.yaml", ".\vercel_build.sh", ".\README.md", ".\lib\*.dart", ".\lib\**\*.dart" -Pattern "Ã|Â|ï»¿|�" -ErrorAction SilentlyContinue
if ($Mojibake) {
  $Mojibake
  throw "Hay posible mojibake."
}

$Pubspec = Get-Content ".\pubspec.yaml" -Raw
if ($Pubspec -notmatch "supabase_flutter:\s*2\.8\.3") { throw "supabase_flutter debe ser 2.8.3" }
if ($Pubspec -notmatch "app_links:\s*6\.4\.1") { throw "app_links debe ser 6.4.1" }

flutter --version
flutter pub get
flutter analyze
flutter build web --release --no-tree-shake-icons --no-wasm-dry-run

if (-not (Test-Path ".\build\web\index.html")) { throw "No se generó build/web/index.html" }
if (-not (Test-Path ".\build\web\main.dart.js")) { throw "No se generó build/web/main.dart.js" }

Write-Host "Quality gate OK." -ForegroundColor Green
