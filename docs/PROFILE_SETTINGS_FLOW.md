# Grupli v8 — Perfil, avatar y ajustes reales

## Objetivo

Cerrar una base útil para el usuario fuera de los grupos:

- Ver perfil real.
- Editar nombre visible.
- Subir foto de perfil a Supabase Storage.
- Quitar foto de perfil.
- Ver estadísticas básicas.
- Guardar preferencias de notificaciones.
- Acceder a términos, privacidad y ayuda.

## Tablas / Storage

### `profiles`

Ya existe. Se usa para:

- `full_name`
- `email`
- `avatar_url`

### `user_settings`

Nueva tabla para ajustes persistentes:

- `notify_events`
- `notify_expenses`
- `notify_tournaments`
- `theme`

### Storage `avatars`

Bucket público para avatares. Cada usuario solo puede escribir en su carpeta:

```text
avatars/<user_id>/avatar.jpg
```

## Archivo SQL

Ejecutar si la base ya existe:

```text
supabase/patch_v8_profile_settings.sql
```

También está incluido dentro de `supabase/all_in_one.sql` para instalaciones limpias.

## Reglas de arquitectura

- `profile_repository.dart` solo toca perfil/avatar/estadísticas.
- `settings_repository.dart` solo toca ajustes.
- `profile_screen.dart` no hace SQL directo.
- `settings_screen.dart` no hace SQL directo.
- Legal/ayuda viven en `settings_info_screen.dart`.

## Pruebas mínimas

1. Abrir perfil.
2. Cambiar nombre.
3. Subir avatar.
4. Quitar avatar.
5. Abrir estadísticas.
6. Ir a ajustes.
7. Activar/desactivar notificaciones.
8. Entrar en términos, privacidad y ayuda.
9. Cerrar sesión.
