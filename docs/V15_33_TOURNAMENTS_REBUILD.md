# Grupli v15.33 — Torneos y ligas reconstruidos

Esta fase rehace el flujo de Torneos/Ligas para que sea útil de verdad en grupos reales.

## Inspiración funcional

Se ha tomado como referencia el patrón habitual de apps de torneos: formatos claros, participantes/equipos, generación automática de partidos, resultados y clasificación.

## Cambios principales

- Crear competición con nombres de equipos/parejas/jugadores desde el asistente.
- Campo multilinea: un participante por línea.
- Botón para cargar miembros del grupo como participantes.
- Si se añaden 2 o más participantes al crear, se genera el calendario automáticamente.
- Liga/Americano ahora usa calendario round-robin real por jornadas, no un partido por ronda.
- Eliminatoria permite números no potencia de dos usando pases directos/BYE.
- En eliminatoria ya no se avanza si queda algún resultado pendiente de la ronda actual.
- Se pueden añadir varios participantes de golpe en el detalle.
- Se pueden renombrar equipos/parejas/jugadores tocando en el participante.
- Resultado por deporte:
  - General: marcador directo 3/1/0.
  - Fútbol: goles, empate permitido, diferencia de goles.
  - Tenis/Pádel: sets, mejor de 3, juegos por parcial.
  - Baloncesto: puntos, sin empate.
  - Mus/Cartas: juegos/rondas.
  - Personalizado: directo o por sets/rondas.

## Sin SQL adicional

No se añade parche SQL nuevo. Se mantiene la política de estabilidad:

- `supabase/all_in_one.sql`
- `supabase/security_checks.sql`

