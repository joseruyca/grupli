# v16.31 — Agenda integrada

Objetivo: cerrar la conexión entre Torneos y Agenda sin añadir pagos ni SQL nuevo.

## Incluido

- Resumen visible de Agenda dentro de la pestaña Partidos.
- Estado por partido: En Agenda, Falta Agenda, Sin fecha, Agenda cancelada o Descanso.
- Acción para añadir a Agenda los partidos programados que todavía no tienen evento vinculado.
- Cambio de fecha/pista con sincronización de Agenda.
- Cancelar partido cancela el evento vinculado.
- Desde el detalle de un evento de Agenda de torneo se puede abrir el torneo vinculado.

## Criterio de producto

Torneos y Agenda deben sentirse como una sola experiencia: si un partido tiene fecha, el usuario debe entender claramente si aparece en Agenda y poder corregirlo sin buscar opciones ocultas.

## Seguridad

No se añaden claves, pagos ni operaciones sensibles nuevas. La app sigue usando RLS de Supabase para lectura y escritura.
