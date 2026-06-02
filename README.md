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


## v6.4 visible home proof

La pantalla `/app` ya no depende de `AppScreen`: usa un `Scaffold` directo con `ListView` y un marcador visible `V6.4 HOME CARGADA`. Si ese marcador no aparece, el navegador/Vercel/local no está cargando este código.


## v6.5 RLS group creation fix

La creación de grupos ahora usa `create_group_atomic`, una función SQL `SECURITY DEFINER` que crea el grupo y añade al usuario como owner en una sola transacción. Esto evita el error RLS:

```text
new row violates row-level security policy for table "groups"
```

Ejecutar primero en Supabase:

```text
supabase/patch_v6_5_create_group_atomic.sql
```


## v6.6

Pulido visual de Home + Crear grupo, manteniendo el fix RLS de creación atómica de grupos. El objetivo es acercarse al mockup y dejar la base usable antes de seguir con más funcionalidades.


## v6.7 Detail + Members polish

Pulido visual de Detalle de grupo y Miembros para acercarlo más al mockup: hero cards, código de invitación, resumen rápido, grid de accesos, métricas de miembros, búsqueda, filtros y acciones de admin más claras.


## v7 Torneos funcionales

Añade equipos, generación de partidos todos contra todos, registro de resultados, clasificación real, finalizar/reabrir torneo y documentación de arquitectura.


## v8 — Perfil, avatar y ajustes reales

Añade perfil real con estadísticas básicas, avatar en Supabase Storage, ajustes persistentes por usuario, pantallas legales/base de ayuda y SQL `patch_v8_profile_settings.sql`.

## Estado v9

Fase de revisión antes de rediseñar cada página:

- Checklist multiusuario interactivo.
- Revisión de RLS.
- `patch_v9_rls_hardening.sql`.
- `security_checks.sql` ampliado.
- Documentación de reglas para rediseños posteriores.

Ejecutar en Supabase:

```powershell
Get-Content ".\supabase\patch_v9_rls_hardening.sql" | Set-Clipboard
```

Luego pegar en `Supabase → SQL Editor → New query → Run`.


## v9.1 — grupos privados y fix de creación

La creación de grupo ahora asegura `profiles` antes de insertar en `groups`, evitando el error `groups_owner_id_fkey`. La pantalla de crear grupo queda simplificada: solo nombre + grupo privado. Días, hora, ubicación y mínimos se gestionan en quedadas/eventos, no en el grupo.

## v10 — product reset premium foundation

Esta versión resetea la dirección de Grupli:

- Fondo base blanco.
- Grupos siempre privados/cerrados.
- Crear grupo pide solo el nombre.
- Días, hora, ubicación y mínimo pertenecen a eventos, no al grupo.
- Detalle de grupo gira alrededor de las 4 funciones clave: eventos/calendario, finanzas y ligas.
- Perfil queda escueto.
- Se añade `supabase/patch_v10_product_reset.sql` para corregir perfiles ausentes y reforzar creación privada de grupos.
- Se añade `docs/PRODUCT_APP_CONTRACT_V10.md` como contrato de producto.

## v11 — mockup app premium aplicado

Esta versión aplica el mockup aprobado como base real de la app: fondo blanco, navegación inferior dentro de cada grupo, detalle del grupo con cuatro funciones principales y documentación de todas las pantallas en `docs/MOCKUP_PAGE_SPEC_V11.md`.

Cambios clave:
- Barra inferior fija dentro del grupo: Eventos, Calendario, Finanzas, Torneos y Más.
- Nueva ruta `/app/groups/:groupId/events` para acceder directamente a eventos.
- Detalle del grupo rehecho como overview premium con hero, acciones rápidas, código y módulos.
- Eventos y Calendario usan la misma base funcional, pero entran desde pestañas distintas.
- Finanzas, Torneos, Miembros y Editar grupo mantienen la navegación interna del grupo.
- Welcome rediseñado con hero teal y fondo blanco.
