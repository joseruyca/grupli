# PowerShell para instalar este ZIP en grupliv2 y subir a GitHub

## 1) Sobrescribir `C:\Users\Jose\Desktop\grupliv2` conservando `.env`

```powershell
$Dest = "$env:USERPROFILE\Desktop\grupliv2"

$Zip = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "grupli-flutter-v1*.zip" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $Zip) {
  throw "No encuentro el ZIP en Descargas."
}

$Temp = "$env:TEMP\grupli_flutter_extract"
$EnvBackup = "$env:TEMP\grupli_env_backup.txt"

if (Test-Path "$Dest\.env") {
  Copy-Item "$Dest\.env" $EnvBackup -Force
}

Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $Temp | Out-Null
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

Expand-Archive -Path $Zip.FullName -DestinationPath $Temp -Force

Get-ChildItem $Dest -Force | Remove-Item -Recurse -Force
Get-ChildItem $Temp -Force | Copy-Item -Destination $Dest -Recurse -Force

if (Test-Path $EnvBackup) {
  Copy-Item $EnvBackup "$Dest\.env" -Force
}

Remove-Item $Temp -Recurse -Force

cd $Dest
dir
```

## 2) Configurar `.env` local

Edita este archivo:

```powershell
notepad "$env:USERPROFILE\Desktop\grupliv2\.env"
```

Debe quedar así, con tus valores reales de Supabase:

```powershell
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_ANON_PUBLICA
```

## 3) Probar local en Chrome

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

## 4) Build web local

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
flutter build web --release
```

## 5) Subir al repo correcto de Grupli

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

git init
git branch -M main

git config user.name "Jose Rubio"
git config user.email "joseruyca@gmail.com"

git remote remove origin 2>$null
git remote add origin https://github.com/joseruyca/grupli.git

git remote -v
```

Tiene que salir:

```powershell
origin  https://github.com/joseruyca/grupli.git (fetch)
origin  https://github.com/joseruyca/grupli.git (push)
```

Después:

```powershell
git rm -r --cached build 2>$null
git rm -r --cached .dart_tool 2>$null
git rm --cached .env 2>$null
git rm --cached android/key.properties 2>$null
git rm -r --cached android/app/keystore 2>$null

git add .
git commit -m "Initial Grupli Flutter"
git push -u origin main
```
