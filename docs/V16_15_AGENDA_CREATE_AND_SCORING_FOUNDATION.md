# Grupli v16.15 — Agenda create button and tournament scoring foundation

## Cambios incluidos

### Agenda

- Se añade botón visible `Crear` en la cabecera de Agenda.
- El botón crea un evento usando el día seleccionado en el calendario.
- El empty state sigue manteniendo su acción de crear evento.

### Torneos y ligas

Esta versión no reescribe toda la sección de torneos. Es una primera corrección segura para evitar que los deportes con sets se entiendan mal.

#### Resultados por sets

Antes, cuando se introducía un resultado como:

```txt
6-7
6-4
6-0
```

La tarjeta del partido podía dar la sensación de que cada set era un punto genérico.

Ahora:
- el marcador principal se muestra como `Sets 2 - 1`;
- debajo se muestran los juegos/puntos reales: `juegos 18-11 · 6-7 · 6-4 · 6-0`;
- se guardan en `result_details`:
  - sets;
  - sets_a;
  - sets_b;
  - games_a;
  - games_b;
  - score_model.

#### Americano con deportes de sets

En Americano, si el deporte usa sets, la clasificación individual suma los juegos/puntos ganados por cada jugador, no solo los sets.

Ejemplo:
- pareja A gana 6-7, 6-4, 6-0
- el partido queda `Sets 2-1`
- pero para el ranking de Americano se suman los juegos/puntos reales ganados.

Esto encaja mejor con el funcionamiento de un Americano, donde cada jugador debe acumular puntos/juegos con parejas rotativas.

## Lo que queda por hacer en una fase específica de Torneos

La sección de torneos necesita una reestructuración de producto, no solo parches:

1. Elegir deporte/competición.
2. Elegir formato:
   - Liga
   - Eliminatoria
   - Americano
   - Manual
3. Según el deporte, mostrar un formulario de resultado específico:
   - fútbol: goles;
   - basket: puntos;
   - tenis/pádel: sets y juegos;
   - voleibol/ping pong: sets y puntos;
   - cartas: partidas/rondas;
   - personalizado.
4. En cada formato, aplicar ranking distinto:
   - liga: puntos de victoria/empate/derrota + desempates;
   - americano: puntos/juegos acumulados individualmente;
   - eliminatoria: ganador avanza;
   - manual: clasificación editable.
5. Mejorar la creación de participantes/equipos/parejas antes de generar partidos.

## SQL

No requiere SQL nuevo.
