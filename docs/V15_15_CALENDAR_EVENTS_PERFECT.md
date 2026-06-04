# v15.15 — Calendario y eventos perfectos

Cambios aplicados:

- Rutinas conectadas mediante `event_series_id`.
- Al crear rutina se guardan frecuencia, posición y total de ocurrencias.
- Edición de rutinas con alcance:
  - Solo esta fecha.
  - Esta y futuras.
  - Toda la rutina.
- Cancelación de rutinas con el mismo selector de alcance.
- Agenda por día con textos más claros.
- Eventos de rutina identificados por datos reales y no solo por notas.
- Asistencia mantiene avatares de miembros en el detalle del evento.

SQL necesario:

```sql
supabase/patch_v15_15_calendar_events_perfect.sql
```
