# Grupli v16.22.1 — instalación local

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v16.22.1-event-contributions-security-fix*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP v16.22.1 en Descargas."
}

$Temp = "$env:TEMP\grupli_extract_v16221"
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
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

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

## SQL v16.22

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v16_22_event_contributions.sql" | Set-Clipboard
```

Supabase → SQL Editor → New query → pegar → Run.

## Quality gate

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\quality_gate_v16_22_1.ps1
```
