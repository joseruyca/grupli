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

## Estado v6

Esta versión aplica el concepto visual más claro y distintivo a:

- Auth
- Mis grupos
- Crear/editar grupo
- Detalle grupo
- Miembros
- Calendario mensual completo
- Crear y editar quedadas
- Detalle de quedada con asistencia real
- Respuestas Voy / Duda / No voy
- Mínimos de personas y aviso si falta gente
- Cancelar/reactivar quedadas
- Finanzas + nuevo gasto
- Torneos + vista previa de clasificación
- Perfil
- Ajustes

También añade documentación de diseño y plan de desarrollo.

## Estado v6

Esta versión mejora finanzas:

- reparto igual/manual
- balances netos calculados en cliente
- liquidaciones/pagos entre miembros
- marcar gastos pagados, reabrir, cancelar o eliminar
- filtros de movimientos
- pagos registrados
- explicación clara del reparto



## v6.2 UI visible shell fix

Corrige la pantalla en blanco después del login: AppScreen ya no usa layouts ambiguos dentro de scroll, el contenido de grupos renderiza siempre encabezado/carga/error/estado vacío, y web/index.html evita bloquear el layout en móvil.


## v6.3 Body render fix

Rehace `AppScreen` con un `ListView` directo y añade `ErrorWidget.builder` para que cualquier error de render se vea en pantalla en vez de dejar una home en blanco.
