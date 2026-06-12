# Grupli v16.20.1 — Event, finance and agenda polish

## Objetivo

Corregir tres problemas detectados en pruebas reales de APK:

1. Cancelar evento desde el detalle no parecía hacer nada porque los eventos cancelados podían seguir apareciendo en las listas.
2. La tarjeta superior de Finanzas tenía decoración de fondo innecesaria y los importes grandes podían cortarse.
3. La leyenda de Agenda solo mostraba tipos presentes y los marcadores de eventos en el calendario se veían demasiado pequeños.

## Cambios

### Eventos

- `AppData.events()` filtra eventos con `status = cancelled` en todos los caminos de carga.
- `AppData.cancelEvent()` ahora valida que Supabase haya actualizado realmente una fila.
- Si no se actualiza ninguna fila, se muestra un error humano de permisos/evento no disponible.

### Finanzas

- Quitadas las figuras decorativas de fondo en `FinanceHeroCard`.
- Las métricas `Gastado`, `Pendiente` y `A mover` ahora son pulsables.
- Al pulsar una métrica aparece una hoja inferior con explicación clara.
- Los importes usan `FittedBox` para que cantidades grandes no se corten.

### Agenda

- La leyenda de tipos de evento se muestra siempre completa:
  - Quedada
  - Partido
  - Entrenamiento
  - Torneo
  - Cena
  - Reunión
- Los colores de los tipos son más visibles.
- Los puntitos pequeños se cambian por barras compactas de color.
- Los días con eventos tienen fondo suave según el tipo de evento.

## SQL

No requiere SQL nuevo.
