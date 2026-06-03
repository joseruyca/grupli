# Grupli v12.9 — Calendario en español + perfil real

## Cambios de interfaz

- El calendario usa `es_ES`:
  - meses en español
  - días largos en español
  - etiquetas abreviadas en español
- El perfil deja de ser una pantalla estática.
- El usuario puede:
  - ver su nombre real
  - cambiar el nombre visible
  - subir foto desde galería
  - quitar foto
  - ver estadísticas básicas de grupos, grupos donde administra y eventos
- Los miembros del grupo ya pueden mostrar avatar si existe `avatar_url`.

## Cambios técnicos

- Se inicializa `Intl.defaultLocale = 'es_ES'`.
- Se ejecuta `initializeDateFormatting('es_ES')`.
- Se añade `image_picker` en el perfil.
- Se usa Supabase Storage bucket `avatars`.

## SQL

Para que la foto de perfil pueda subirse hay que ejecutar:

`supabase/patch_v12_9_profile_avatar_storage.sql`

No resetea datos. Solo crea/actualiza el bucket `avatars` y sus políticas de Storage.

## Regla

El perfil debe seguir siendo escueto:
- nombre
- foto
- email
- estadísticas sencillas
- opciones básicas
