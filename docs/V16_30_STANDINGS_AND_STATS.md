# v16.30 — Clasificación y estadísticas

Objetivo: cerrar una base clara para tablas, desempates y estadísticas por deporte sin añadir pagos, SQL ni lógica de premium real.

## Cambios principales

- Versión interna actualizada a `v16.30`.
- Tabla de torneo con resumen superior: líder, partidos jugados, mejor diferencia y mejor marca secundaria.
- Estadísticas adaptadas por deporte:
  - Fútbol: puntos, victorias, empates, goles a favor, goles en contra y diferencia de goles.
  - Basket: victorias, puntos a favor, puntos en contra y diferencia de puntos.
  - Tenis / Pádel: sets ganados/perdidos, juegos ganados/perdidos y diferencias.
  - Voleibol / Ping pong: sets y puntos de parcial.
  - Americano: ranking individual por puntos/juegos acumulados.
  - Libre / cartas / billar / dardos / gaming: marcador simple y diferencia.
- Desempates explicados con textos más humanos y adaptados al deporte.
- Estadísticas gratuitas útiles: líder, progreso, porcentaje de victorias, más victorias, mejor diferencia y más puntos/goles/juegos a favor.
- Base preparada para estadísticas premium futuras, sin bloquear participantes ni grupos grandes.

## Qué no se ha tocado

- No hay SQL nuevo.
- No hay pagos reales.
- No hay nuevas librerías.
- No se toca `.env`.
- No se cambian permisos ni RLS.

## Siguiente fase

v16.31 — Agenda integrada: partidos de torneo en la agenda, edición de fechas, mover partidos y abrir desde Agenda/Torneos.
