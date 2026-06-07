# Grupli v15.31.3 — Realtime loop / flicker fix

Esta fase corrige el parpadeo/refresco constante detectado en navegador después de crear un grupo.

## Causa probable

Había dos problemas combinados:

1. `ensure_current_profile()` actualizaba `profiles.updated_at = now()` cada vez que la app comprobaba el perfil.
2. El grupo escuchaba cambios de `profiles` sin filtro, así que cualquier update de perfil podía provocar refresco de grupo.

Resultado: algunas pantallas podían entrar en un bucle de Realtime:
lectura → ensure profile → update profile → realtime → refresco → lectura.

## Cambios

- `ensure_current_profile()` ya no actualiza `profiles` si no hay cambios reales.
- Home deja de escuchar todos los cambios globales de `groups`.
- GroupShell deja de escuchar `profiles` global sin filtro.
- GroupShell conserva el grupo cacheado mientras refresca para no enseñar `Cargando grupo...` en cada evento realtime.
- Versión interna: `v15.31.3`.

## SQL

Ejecutar:

```powershell
Get-Content ".\supabase\patch_v15_31_3_realtime_loop_flicker_fix.sql" | Set-Clipboard
```

No resetea nada.
