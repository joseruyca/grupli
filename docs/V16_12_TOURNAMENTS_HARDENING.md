# Grupli v16.12 — Torneos hardening

Esta fase no añade funciones grandes. Endurece el editor para evitar datos rotos.

## Cambios

- Añadir miembros del grupo evita duplicados por usuario y por nombre.
- Crear pareja visual evita parejas duplicadas por nombre y exige dos miembros distintos.
- Eliminar participante ahora es seguro:
  - si no tiene partidos, se elimina;
  - si tiene partidos, se marca como retirado para no romper histórico, resultados ni calendario.
- Cambiar fecha de un partido añade entrada al historial.
- Reprogramar jornada/lote añade entrada al historial de cada partido.
- Cambiar estado de partido añade entrada al historial.
- La confirmación de reprogramación masiva se mantiene antes de guardar.
- El historial global del torneo ahora recoge también cambios de fecha y estado.

## Motivo

Evitar parches peligrosos de futuro: nunca borrar participantes con partidos vinculados, nunca perder trazabilidad de cambios importantes y evitar duplicados al importar miembros.
