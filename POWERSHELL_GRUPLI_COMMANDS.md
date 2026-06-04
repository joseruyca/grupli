# Grupli v15.11 — instalación local

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v15.11-finance-tournament-ux-cleanup*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP en Descargas."
}

$Temp = "$env:TEMP\grupli_extract_v1511"
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
New-Item -ItemType Directory -Path $Temp | Out-Null
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

Expand-Archive -Path $Zip.FullName -DestinationPath $Temp -Force

Get-ChildItem $Dest -Force | Where-Object {
  $_.Name -ne ".env" -and $_.Name -ne ".git"
} | Remove-Item -Recurse -Force

Get-ChildItem $Temp -Force | Copy-Item -Destination $Dest -Recurse -Force

if (Test-Path $EnvBackup) {
  Copy-Item $EnvBackup "$Dest\.env" -Force
}

if (Test-Path $GitBackup) {
  Remove-Item "$Dest\.git" -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item $GitBackup "$Dest\.git" -Recurse -Force
}

Remove-Item $Temp -Recurse -Force

cd $Dest
```

## SQL v15.11

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v15_11_finance_tournament_ux.sql" | Set-Clipboard
```

Luego: Supabase → SQL Editor → New query → pegar → Run.

## Probar

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
flutter clean
Remove-Item .\.dart_tool -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\build -Recurse -Force -ErrorAction SilentlyContinue
flutter pub get
flutter analyze
flutter run -d chrome
```

## Subir a GitHub

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
git status
git add .
git commit -m "Improve finance UX and tournament scoring"
git push -u origin main
```
