# Grupli

Grupli es una app Flutter + Supabase para organizar grupos reales: quedadas, asistencia, gastos compartidos tipo Tricount y torneos.

## Stack

- Flutter
- Supabase Auth + Database + Storage + Realtime + RLS
- Vercel para Flutter Web mediante `vercel_build.sh`

## Flujo correcto

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
flutter clean
flutter pub get
flutter run -d chrome
```

Cuando local funcione:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
git init
git branch -M main
git config user.name "Jose Rubio"
git config user.email "joseruyca@gmail.com"
git remote remove origin 2>$null
git remote add origin https://github.com/joseruyca/grupli.git
git remote -v
git rm -r --cached build 2>$null
git rm -r --cached .dart_tool 2>$null
git rm --cached .env 2>$null
git rm --cached android/key.properties 2>$null
git rm -r --cached android/app/keystore 2>$null
git add .
git commit -m "Initial Grupli Flutter"
git push -u origin main
```

## Variables

Local: crear `.env` copiando `.env.example`.

Vercel: añadir `SUPABASE_URL` y `SUPABASE_ANON_KEY` en Production, Preview y Development.

## SQL

Ejecutar `supabase/all_in_one.sql` en Supabase SQL Editor.
Después ejecutar `supabase/security_checks.sql` para comprobar políticas principales.
