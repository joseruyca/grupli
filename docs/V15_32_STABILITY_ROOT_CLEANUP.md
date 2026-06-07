# Grupli v15.32 — Estabilización raíz

Esta versión cambia la estrategia: no añade funcionalidades nuevas.

## Decisiones importantes

- No se entrega un parche SQL incremental.
- `supabase/all_in_one.sql` queda como único reset global.
- Se eliminan los `patch_*.sql` y `reset_global_*.sql` del ZIP.
- Realtime automático queda desactivado en la app para cortar bucles de refresco/parpadeo.
- La app refresca tras acciones explícitas: crear, editar, borrar, volver de pantallas, actualizar manualmente.

## Por qué

El parpadeo venía de la combinación de:

- listeners realtime amplios;
- `setState` global;
- `FutureBuilder` reconstruyendo pantallas completas;
- `refreshKey` recreando widgets;
- consultas que podían tocar perfiles o datos relacionados.

No conviene arreglar esto con más parches. Primero se estabiliza la base.

## SQL

Para reset global usar solo:

```powershell
Get-Content ".\supabase\all_in_one.sql" | Set-Clipboard
```

Después puedes ejecutar:

```powershell
Get-Content ".\supabase\security_checks.sql" | Set-Clipboard
```

## Realtime

Está preparado en SQL, pero desactivado en código con:

```dart
AppConfig.enableRealtimeSubscriptions = false
```

Para reactivarlo en el futuro hay que hacerlo por pantalla y con streams/caché, no con refrescos globales.
