\
# Grupli v12.6 — instalación local

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v14-premium-product-polish.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP en Descargas."
}

$Temp = "$env:TEMP\grupli_flutter_extract"
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


## v12.9

Calendario en español y perfil real con nombre/foto. Ejecutar `supabase/patch_v12_9_profile_avatar_storage.sql` para habilitar subida de avatares.


## Copiar SQL v12.10 create group RPC fix

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v12_10_create_group_rpc_overload_fix.sql" | Set-Clipboard
```


# v15.5: recuerda ejecutar supabase/patch_v15_5_push_notifications.sql en Supabase SQL Editor.
