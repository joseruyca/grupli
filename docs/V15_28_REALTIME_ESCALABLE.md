# Grupli v15.28 — Realtime escalable

Objetivo: que los cambios de un grupo se vean en directo sin refrescar manualmente, pero sin escuchar cambios globales de otros grupos.

## Cambios principales

- `event_attendance`, `expense_participants`, `tournament_teams` y `matches` ahora tienen `group_id` directo.
- Se añaden triggers para rellenar automáticamente `group_id` desde:
  - `events`
  - `expenses`
  - `tournaments`
- Las suscripciones realtime del grupo ahora filtran también esas tablas hijas por `group_id`.
- Se separa el refresco por módulos:
  - eventos/asistencia refrescan agenda;
  - gastos/liquidaciones refrescan finanzas;
  - torneos/equipos/partidos refrescan torneos;
  - grupo/miembros refrescan todo el grupo.
- El debounce sube a 700 ms para agrupar varios cambios y evitar parpadeos.
- La pantalla Mis grupos escucha `group_members` filtrado por el usuario actual.

## SQL

Ejecutar:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v15_28_realtime_escalable.sql" | Set-Clipboard
```

Luego Supabase → SQL Editor → pegar → Run.

No resetea datos.

## Prueba recomendada

Con dos móviles en el mismo grupo:

1. Móvil A crea evento.
2. Móvil B debe ver agenda actualizada.
3. Móvil A confirma asistencia.
4. Móvil B debe ver el cambio.
5. Móvil A crea gasto.
6. Móvil B debe ver finanzas actualizadas.
7. Móvil B liquida pago.
8. Móvil A debe ver balance actualizado.
9. Móvil A pone resultado de torneo.
10. Móvil B debe ver clasificación actualizada.

La actualización puede tardar unos segundos por el debounce, pero no debería requerir botón de actualizar.
