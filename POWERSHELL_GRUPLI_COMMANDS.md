# Grupli v16.32.3 — comandos PowerShell

Versión basada en v16.32.2 con el fix web probado:

- `supabase_flutter: 2.8.3`
- `app_links: 6.4.1`

## Instalar conservando `.env` y `.git`

```powershell
$ErrorActionPreference = "Stop"

$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v16.32.3-web-working-deps*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP grupli-flutter-v16.32.3-web-working-deps en Descargas."
}

$Temp = Join-Path $env:TEMP ("grupli_extract_v16323_" + [guid]::NewGuid().ToString("N"))
$EnvBackup = Join-Path $env:TEMP "grupli_env_backup.txt"
$GitBackup = Join-Path $env:TEMP "grupli_git_backup"

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Temp -Force | Out-Null

if (Test-Path "$Dest\.env") {
  Copy-Item "$Dest\.env" $EnvBackup -Force
}

if (Test-Path "$Dest\.git") {
  Remove-Item $GitBackup -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item "$Dest\.git" $GitBackup -Recurse -Force
}

Expand-Archive -Path $Zip.FullName -DestinationPath $Temp -Force

$Pubspec = Get-ChildItem $Temp -Recurse -Filter "pubspec.yaml" -File | Sort-Object { $_.FullName.Length } | Select-Object -First 1
if (-not $Pubspec) {
  throw "El ZIP no contiene pubspec.yaml."
}

$SourceRoot = $Pubspec.Directory.FullName

Get-ChildItem $Dest -Force | Where-Object {
  $_.Name -ne ".env" -and $_.Name -ne ".git"
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Get-ChildItem $SourceRoot -Force | Where-Object {
  $_.Name -ne ".env" -and $_.Name -ne ".git" -and $_.Name -ne ".dart_tool" -and $_.Name -ne "build"
} | Copy-Item -Destination $Dest -Recurse -Force

if (Test-Path $EnvBackup) {
  Copy-Item $EnvBackup "$Dest\.env" -Force
}

if (Test-Path $GitBackup) {
  Remove-Item "$Dest\.git" -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item $GitBackup "$Dest\.git" -Recurse -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
cd $Dest

git status --short
```

## Subir a GitHub

```powershell
$ErrorActionPreference = "Stop"
cd "$env:USERPROFILE\Desktop\grupliv2"

git status

git add -A
git commit -m "Restore v16.32.3 with working web dependencies"
git push -u origin main
```

## Comprobar dependencias clave antes de subir

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Select-String -Path ".\pubspec.yaml" -Pattern "supabase_flutter|app_links"
```

Debe salir:

```text
supabase_flutter: 2.8.3
app_links: 6.4.1
```
