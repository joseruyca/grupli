# Grupli v15.29.2 — Agenda repair + revisión rápida

## Problema detectado

La agenda podía sentirse vacía aunque existieran eventos en otros días, porque la pantalla se centraba demasiado en el día seleccionado. Si hoy no tenía eventos, el usuario veía poca información útil.

Además, la consulta de eventos dependía del embed de `event_attendance`. Si Supabase/relaciones/RLS fallaban temporalmente, la agenda podía quedarse sin datos aunque los eventos existieran.

## Cambios

- Consulta de eventos más robusta.
- Fallback defensivo: si falla el embed de asistencia, carga al menos los eventos.
- Cabecera de agenda con resumen real:
  - total de eventos;
  - próximos planes;
  - asistencia acumulada;
  - próximo evento destacado.
- Si el día seleccionado no tiene planes, debajo aparecen los próximos eventos.
- La agenda se refresca mejor cuando cambia `refreshSeed`.
- Estado vacío más claro.
- Revisión rápida de navegación/refresh en agenda.

## No requiere SQL

No hace falta resetear ni ejecutar parche.
