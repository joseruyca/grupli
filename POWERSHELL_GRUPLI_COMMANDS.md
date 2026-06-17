# Grupli v16.32 — comandos PowerShell

Instalar conservando `.env` y `.git`:

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v16.32-premium-prepared*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP v16.32 en Descargas."
}

$Temp = "$env:TEMP\grupli_extract_v1632"
$EnvBackup = "$env:TEMP\grupli_env_backup.txt"
$GitBackup = "$env:TEMP\grupli_git_backup"

if (Test-Path "$Dest\.env") {
  Copy-Item "$Dest\.env" $EnvBackup -Force
}

if (Test-Path "$Dest\.git") {
  Remove-Item $GitBackup -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item "$Dest\.git" $GitBackup -Recurse -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Temp -Force | Out-Null

Expand-Archive -Path $Zip.FullName -DestinationPath $Temp -Force

Get-ChildItem $Dest -Force | Where-Object {
  $_.Name -ne ".env" -and $_.Name -ne ".git"
} | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Get-ChildItem $Temp -Force | Copy-Item -Destination $Dest -Recurse -Force

if (Test-Path $EnvBackup) {
  Copy-Item $EnvBackup "$Dest\.env" -Force
}

if (Test-Path $GitBackup) {
  Remove-Item "$Dest\.git" -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item $GitBackup "$Dest\.git" -Recurse -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
cd $Dest
```

Comprobar:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

flutter clean
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue

flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings

Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\build_android_debug_apk.ps1
.\scripts\build_web_release.ps1
```

Subir:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

git status
git add -A
git commit -m "Prepare group premium layer"
git push -u origin main
```
