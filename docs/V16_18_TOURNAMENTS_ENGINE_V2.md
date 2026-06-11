# Grupli v16.18 — Torneos Engine V2

## Decisión de producto

Se deja de parchear Torneos por piezas. Esta versión introduce un contrato único para creación, participantes, resultados y tablas.

## Contrato V2

### 1. Deporte primero

El usuario elige deporte antes que formato. El motor decide qué formatos, participantes y resultados tienen sentido.

Deportes soportados:
- Fútbol
- Pádel / Tenis
- Basket
- Voleibol
- Ping pong
- Mus / Cartas
- Dardos
- Billar
- Videojuegos
- Personalizado

### 2. Formatos válidos por deporte

- Fútbol: Liga / Eliminatoria / Manual
- Pádel/Tenis: Liga / Eliminatoria / Americano / Manual
- Basket: Liga / Eliminatoria / Manual
- Voleibol: Liga / Eliminatoria / Manual
- Ping pong: Liga / Eliminatoria / Americano / Manual
- Mus/Cartas: Liga / Eliminatoria / Americano / Manual
- Dardos: Liga / Eliminatoria / Manual
- Billar: Liga / Eliminatoria / Manual
- Videojuegos: Liga / Eliminatoria / Manual
- Personalizado: Liga / Eliminatoria / Americano / Manual

Si el usuario cambia de deporte y el formato actual ya no encaja, Grupli vuelve automáticamente a un formato válido.

### 3. Participantes por contexto

- Americano: solo jugadores individuales.
- Pádel/Tenis liga: parejas o individual.
- Fútbol/Basket/Voleibol/Videojuegos: equipos.
- Ping pong / Mus: individual o parejas.
- Dardos / Billar: individual o equipos.
- Manual: jugadores, parejas o equipos, pero explícito.

### 4. Resultado real por deporte

- Fútbol: goles.
- Basket: puntos totales.
- Pádel/Tenis: sets y juegos.
- Voleibol/Ping pong: sets y puntos de set.
- Dardos/Billar/Mus/Videojuegos: marcador directo adaptado.
- Americano: ranking individual por acumulado real.
- Eliminatoria: el resultado decide ganador y avance.

### 5. Americano

El Americano deja de comportarse como una liga genérica.

- Participantes: jugadores individuales.
- La app genera parejas rotativas.
- Intenta no repetir pareja mientras sea posible.
- Equilibra descansos y partidos jugados.
- Ranking individual.
- En Pádel/Tenis americano, por defecto se usa 1 parcial por partido y se suman juegos reales.
- En Ping pong americano, se suman puntos de set reales.

### 6. Tabla por deporte

- Fútbol: PJ, G, E, P, GF, GC, DG, PTS.
- Tenis/Pádel: PJ, V, P, SF, SC, DS, JF, JC, DJ, PTS.
- Voleibol/Ping pong: PJ, V, P, SF, SC, DS, PF, PC, DP, PTS.
- Basket: PJ, G, P, PF, PC, DP, PTS.
- Americano: Jugador, PJ, V, acumulado, contra, diferencia.

## Cambios técnicos

Nuevo archivo:

```txt
lib/features/tournaments/tournament_engine_v2.dart
```

Este archivo centraliza:
- formatos válidos por deporte;
- tipo de participante por formato;
- textos de ayuda;
- validaciones de creación;
- desempates recomendados;
- contrato de resultado.

## SQL

No requiere SQL nuevo. Usa los campos existentes:
- scoring_type
- scoring_config
- format_config
- schedule_config
- team_type
- tie_breakers

Los nuevos datos se guardan como JSON dentro de config con:
- version: 18
- engine: tournaments_v2
- sport
- participant_type

## Escenarios que hay que probar

1. Liga fútbol con 6 equipos.
2. Liga pádel por parejas con sets 6-7 / 6-4 / 6-0.
3. Liga tenis individual.
4. Americano pádel con 8 jugadores, 1 pista y 5 rondas.
5. Americano ping pong con 6 jugadores.
6. Eliminatoria fútbol con 8 equipos.
7. Manual con cruces creados con selector visual.
