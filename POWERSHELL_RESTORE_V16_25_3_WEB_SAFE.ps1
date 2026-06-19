$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v16.25.3-web-safe-restore*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) { throw "No encuentro el ZIP v16.25.3 en Descargas." }

$Temp = "$env:TEMP\grupli_restore_v16253_web_safe"
$EnvBackup = "$env:TEMP\grupli_env_backup.txt"
$GitBackup = "$env:TEMP\grupli_git_backup"

if (Test-Path "$Dest\.env") { Copy-Item "$Dest\.env" $EnvBackup -Force }
if (Test-Path "$Dest\.git") {
  Remove-Item $GitBackup -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item "$Dest\.git" $GitBackup -Recurse -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Temp -Force | Out-Null
Expand-Archive -Path $Zip.FullName -DestinationPath $Temp -Force

$SourceRoot = $Temp
if (-not (Test-Path "$SourceRoot\pubspec.yaml")) {
  $Pubspec = Get-ChildItem $Temp -Recurse -Filter "pubspec.yaml" | Select-Object -First 1
  if (-not $Pubspec) { throw "El ZIP no contiene pubspec.yaml." }
  $SourceRoot = Split-Path $Pubspec.FullName -Parent
}

Get-ChildItem $Dest -Force | Where-Object { $_.Name -ne ".env" -and $_.Name -ne ".git" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem $SourceRoot -Force | Copy-Item -Destination $Dest -Recurse -Force

if (Test-Path $EnvBackup) { Copy-Item $EnvBackup "$Dest\.env" -Force }
if (Test-Path $GitBackup) {
  Remove-Item "$Dest\.git" -Recurse -Force -ErrorAction SilentlyContinue
  Copy-Item $GitBackup "$Dest\.git" -Recurse -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
cd $Dest
