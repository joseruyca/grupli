# Grupli v9 — Revisión completa de bugs + checklist multiusuario + seguridad RLS

## Objetivo

Antes de seguir cambiando cada página visualmente, esta fase congela la arquitectura y añade una revisión clara de seguridad y pruebas.

## Qué se revisa

### 1. Layout base

- `AppScreen` debe seguir siendo simple.
- La home debe pintar siempre contenido, carga o error.
- Nada de pantallas en blanco silenciosas.

### 2. Módulos separados

Cada funcionalidad debe seguir aislada:

```text
lib/features/groups
lib/features/calendar
lib/features/finances
lib/features/tournaments
lib/features/profile
lib/features/settings
```

Regla: una pantalla no debe tocar directamente tablas que pertenecen a otro módulo. Debe pasar por su repository.

### 3. Repositories

Cada módulo habla con Supabase desde su repository:

- `groups_repository.dart`
- `calendar_repository.dart`
- `finances_repository.dart`
- `tournaments_repository.dart`
- `profile_repository.dart`
- `settings_repository.dart`

### 4. RLS

Esta fase añade `supabase/patch_v9_rls_hardening.sql`.

Corrige/revisa:

- `get_group_balances` ahora comprueba que el usuario pertenece al grupo.
- Las funciones críticas dejan de estar abiertas a `PUBLIC`.
- `expense_participants` queda más protegido: solo admin o creador del gasto puede editar participantes.
- Añade `v_grupli_security_diagnostics` para comprobar estado de seguridad.

### 5. Checklist multiusuario

La pantalla `Ajustes → Checklist de prueba` ahora es interactiva y está dividida por bloques:

- Usuarios A/B.
- Roles y permisos.
- Flujos principales.
- RLS y seguridad.
- Publicación.

## Orden de prueba obligatorio

1. Ejecutar `patch_v9_rls_hardening.sql` en Supabase.
2. Ejecutar `security_checks.sql`.
3. Probar con usuario A.
4. Probar con usuario B.
5. Confirmar que B no ve datos ajenos.
6. Confirmar que roles funcionan.
7. Confirmar que Vercel despliega el commit correcto.

## No seguir si falla

No continuar con rediseño página por página si falla cualquiera de estos puntos:

- Login.
- Home.
- Crear grupo.
- Entrar por código.
- Roles owner/admin/member.
- RLS de grupos ajenos.
- Crear quedada.
- Crear gasto.
- Crear torneo.
- Perfil/avatar.
