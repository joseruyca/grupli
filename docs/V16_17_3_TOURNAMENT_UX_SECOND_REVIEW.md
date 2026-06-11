# Grupli v16.17.3 — Segunda revisión de UX de torneos

## Objetivo

Revisar de nuevo la fase de creación de torneos por deporte/formato y corregir incoherencias antes de seguir añadiendo funcionalidad.

## Cambios

### Americano

En el paso de sistema de resultado, el Americano ya no muestra los controles genéricos de:
- Victoria
- Empate
- Derrota

Motivo: en Americano el ranking real es individual y se calcula por juegos/puntos acumulados, no por puntos de liga genéricos.

Ahora muestra un bloque específico:
- Ranking Americano
- explicación de que cada jugador acumula juegos/puntos reales
- mantiene solo el ajuste de "Mejor de" cuando el deporte usa sets

### Desempates por deporte

Se añadieron etiquetas de desempate adaptadas al deporte:

- Tenis/Pádel:
  - diferencia de sets
  - diferencia de juegos
  - juegos a favor

- Voleibol/Ping pong:
  - diferencia de sets
  - diferencia de puntos de set
  - puntos de set a favor

- Fútbol:
  - diferencia de goles
  - goles a favor

- Basket:
  - diferencia de puntos
  - puntos a favor

Esto evita que el usuario vea "juegos" cuando está creando un torneo de voleibol o ping pong.

### Participantes

El estado vacío de la pestaña Participantes ahora cambia según el tipo de competición:

- Americano: pide jugadores individuales.
- Parejas: sugiere crear pareja o escribir `Ana / Javi`.
- Individual: sugiere añadir miembros o escribir jugadores.
- Equipos: pide nombres de equipos.

## SQL

No requiere SQL nuevo.

## Nota técnica

Se mantiene la estructura modular con `part / part of`.
