# v15.35 — Torneos rehechos desde mockup aprobado

## Incluye

- Pantalla de torneos del grupo con torneos activos, próximos partidos, últimos resultados y finalizados.
- Crear torneo guiado en 5 pasos: tipo, deporte/puntuación, participantes, emparejamientos y revisión.
- Formatos: liga, eliminatoria, americano y manual.
- Emparejamientos manuales con texto tipo `Jornada 1: Equipo Azul vs Equipo Rojo`.
- Opción para crear eventos de Agenda automáticamente desde los partidos del torneo.
- Detalle de torneo con Resumen, Partidos, Tabla, Stats y Equipos.
- Resultados simples para fútbol/basket/cartas/general y resultados por sets para pádel/tenis.
- Nombres largos en dos líneas en tarjetas, partidos y tablas.
- Tabla calculada automáticamente desde resultados.
- Estadísticas de líder, más victorias, mejor diferencia, más puntos a favor y pendientes.

## SQL

`supabase/all_in_one.sql` acepta ahora `format = 'manual'` en torneos.
