# Grupli v15.25.4 — Navegación y refresco realtime

## Objetivo
Corregir el flujo de crear/unirse a grupo y reforzar el refresco automático.

## Cambios
- Al crear un grupo y pulsar **Entrar al grupo**, ahora se abre directamente el grupo creado.
- Ya no vuelve a la pestaña anterior ni obliga a salir al menú y refrescar.
- Al volver desde el grupo, la pantalla de Mis grupos queda detrás y puede actualizarse por realtime.
- Al unirse con código o enlace, la app abre directamente el grupo unido.
- Se reemplazan `pushReplacement` problemáticos por `pushAndRemoveUntil` dejando la ruta raíz limpia.
- Se añade SQL para asegurar que las tablas principales están en la publicación realtime de Supabase.

## SQL
Ejecutar `supabase/patch_v15_25_4_navigation_realtime_refresh.sql`.

No resetea datos.
