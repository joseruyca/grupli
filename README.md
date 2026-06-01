# Grupli

App Flutter + Supabase para organizar grupos reales: quedadas, asistencia, gastos compartidos y torneos.

## Stack

- Flutter
- Supabase
- Vercel para Flutter Web
- GitHub automático hacia Vercel

## Proyecto local fijo

```powershell
C:\Users\Jose\Desktop\grupliv2
```

## Repositorio correcto

```text
https://github.com/joseruyca/grupli.git
```

## Variables

Local:

```env
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_ANON_PUBLICA
```

Vercel:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Nunca usar `service_role` en Flutter.

## Comandos

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"

flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

Subida:

```powershell
git status
git add .
git commit -m "Update Grupli"
git push -u origin main
```

## Estado v4

Esta versión aplica el concepto visual más claro y distintivo a:

- Auth
- Mis grupos
- Crear/editar grupo
- Detalle grupo
- Miembros
- Calendario + detalle de quedada
- Finanzas + nuevo gasto
- Torneos + vista previa de clasificación
- Perfil
- Ajustes

También añade documentación de diseño y plan de desarrollo.
