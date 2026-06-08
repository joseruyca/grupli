# Grupli v16 — Torneos Engine

Replanteamiento completo de la sección Torneos para que deje de ser solo una lista de partidos y pase a funcionar como motor real de competición dentro del grupo.

## Cambios principales

- Nuevo flujo de creación en 6 pasos:
  1. Nombre y tipo.
  2. Participantes.
  3. Formato detallado.
  4. Puntuación.
  5. Calendario.
  6. Revisión.

- Liga mejorada:
  - vueltas configurables;
  - límite de jornadas para ligas parciales;
  - generación automática todos contra todos;
  - soporte de ida/vuelta.

- Manual mejorado:
  - emparejamientos por texto;
  - jornadas manuales;
  - fechas y pista/mesa/campo desde el propio partido.

- Eliminatoria preparada:
  - cruces iniciales;
  - pases directos si no cuadran participantes;
  - siguiente ronda desde ganadores.

- Americano base:
  - rondas configurables;
  - pistas/mesas simultáneas;
  - ranking calculado con resultados.

- Puntuación separada en dos capas:
  - resultado del partido;
  - puntos de clasificación.

- Nuevos estados:
  - torneo: draft, scheduled, active, paused, finished, cancelled;
  - partido: pending, scheduled, played, postponed, cancelled, no_show, walkover, bye.

- Cada partido ahora puede tener:
  - fecha/hora;
  - duración;
  - ubicación;
  - pista/mesa/campo;
  - notas;
  - vínculo a evento de Agenda;
  - menú de acciones.

- Pantalla de detalle con nueva pestaña Ajustes.

## SQL

El archivo `supabase/all_in_one.sql` se ha actualizado como reset único. Incluye los nuevos campos de torneos, equipos y partidos, además de `tournament_team_members` para dejar preparada la estructura de parejas/equipos reales.

Ejecutar reset completo si se quiere probar la v16 limpia.
