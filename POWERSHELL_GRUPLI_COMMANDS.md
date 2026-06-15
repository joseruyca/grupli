# Grupli v16.24 — comandos PowerShell

## Instalar ZIP conservando `.env` y `.git`

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v16.24-group-home-clarity*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP v16.24 en Descargas."
}

$Temp = "$env:TEMP\grupli_extract_v1624"
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

## Comprobar, APK y web

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

Remove-Item ".\test" -Recurse -Force -ErrorAction SilentlyContinue

flutter clean
Remove-Item ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\build" -Recurse -Force -ErrorAction SilentlyContinue

flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings

Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\build_android_debug_apk.ps1

.\scripts\build_web_release.ps1
```

## Copiar APK

```powershell
Copy-Item `
  "$env:USERPROFILE\Desktop\grupliv2\build\app\outputs\flutter-apk\app-debug.apk" `
  "$env:USERPROFILE\Desktop\Grupli-v16.24.apk" `
  -Force
```

## GitHub

Si Git vuelve a intentar usar `C:/`, no añadas `C:/` como safe directory. Usa:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

Remove-Item Env:GIT_DIR -ErrorAction SilentlyContinue
Remove-Item Env:GIT_WORK_TREE -ErrorAction SilentlyContinue

$SafePath = (Resolve-Path "$env:USERPROFILE\Desktop\grupliv2").Path.Replace('\','/')
git config --global --add safe.directory $SafePath

git status
```

Después:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

git status
git add -A
git commit -m "Improve group home clarity"
git push -u origin main
```
