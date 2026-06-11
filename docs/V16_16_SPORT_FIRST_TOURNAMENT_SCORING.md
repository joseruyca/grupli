# Grupli v16.16 — Torneos por deporte y puntuación real

## Objetivo

Replantear Torneos para que no funcione como un sistema genérico de “ganar = X puntos” para todo.

Ahora el flujo correcto es:

1. Elegir deporte.
2. Elegir formato.
3. Añadir participantes.
4. Registrar resultados con el modelo correcto.
5. Calcular la tabla con métricas reales del deporte.

## Cambios principales

### Creación de torneos

La primera pantalla ahora prioriza el deporte:

- Fútbol
- Tenis / Pádel
- Basket
- Voleibol
- Ping pong
- Mus / Cartas
- Dardos
- Billar
- Gaming
- Personalizado

Después se elige el formato:

- Liga
- Americano
- Eliminatoria
- Manual

Esto evita que una liga de tenis se comporte como una liga de fútbol.

### Resultado por deporte

#### Fútbol

- Resultado por goles.
- Tabla con:
  - puntos,
  - GF,
  - GC,
  - DG.

#### Tenis / Pádel

- Resultado por sets y juegos.
- No se introduce solo “2-1”.
- Se introducen todos los parciales:
  - 6-7
  - 6-4
  - 6-0
- La app guarda:
  - Sets 2-1,
  - juegos 18-11,
  - detalle de cada set.

#### Voleibol / Ping pong

- Resultado por sets y puntos.
- Ejemplo:
  - 25-21
  - 22-25
  - 15-12
- La app guarda:
  - sets ganados,
  - puntos totales,
  - detalle de parciales.

#### Basket

- Resultado por puntos totales.
- Tabla con:
  - victorias,
  - puntos a favor,
  - puntos en contra,
  - diferencia.

#### Americano

- Ranking individual.
- Parejas rotativas.
- En deportes de raqueta suma juegos/puntos reales acumulados.
- Gana quien tenga más puntos/juegos acumulados al terminar las rondas.

#### Eliminatoria

- El resultado solo decide ganador y avance.
- El cuadro usa ganador/perdedor, no necesita tabla de liga.

#### Manual

- Permite crear partidos concretos y editar cruces.

## Cambios visuales

- La tabla cambia columnas según deporte.
- El formulario de resultado explica qué se debe introducir.
- El panel de creación explica el sistema de resultado antes de crear.

## SQL

No requiere SQL nuevo.
