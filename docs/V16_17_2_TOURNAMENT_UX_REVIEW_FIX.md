# Grupli v16.17.2 — Revisión de UX de creación de torneos

## Objetivo

Revisar la v16.17.1 después de la nueva UX de creación de torneos y cerrar incoherencias antes de seguir metiendo funcionalidad.

## Correcciones incluidas

### 1. Formatos compatibles por deporte

La pantalla de formato ya no enseña Americano para todos los deportes.

Americano queda reservado para deportes/juegos donde tiene sentido una rotación individual con parejas variables:

- Tenis / Pádel
- Ping pong
- Mus / Cartas
- Personalizado

Para deportes como fútbol, basket, voleibol, videojuegos, dardos o billar se prioriza:

- Liga
- Eliminatoria
- Manual

Esto evita crear por error un "Americano de fútbol" o una competición con lógica incompatible.

### 2. Cambio de deporte seguro

Si el usuario había elegido Americano y después cambia a un deporte que no lo soporta, Grupli vuelve automáticamente a Liga.

Así se evita guardar una combinación incoherente de:

- formato americano
- deporte no compatible
- participantes mal interpretados

### 3. Desempates en deportes con sets

Había una incoherencia en la clasificación de deportes con sets.

Antes:
- `set_difference`
- `game_difference`

acababan comparando la misma métrica secundaria.

Ahora:
- `set_difference` compara diferencia de sets.
- `game_difference` compara diferencia de juegos/puntos de set.
- `games_for` compara juegos/puntos a favor.

Ejemplo Tenis/Pádel:
- Sets 2-1 afecta a diferencia de sets.
- Juegos 18-11 afecta a diferencia de juegos.

### 4. Enfrentamiento directo más real para sets

El desempate directo ahora también usa métricas secundarias cuando el deporte va por sets.

Orden interno del directo:
1. puntos del enfrentamiento;
2. diferencia principal;
3. marcador principal a favor;
4. diferencia secundaria;
5. secundaria a favor.

En tenis/pádel esto evita que dos partidos igualados se deshagan sin mirar juegos.

## SQL

No requiere SQL nuevo.

## Nota

No se ha ejecutado `flutter analyze` en este entorno. Ejecutarlo en local antes de generar APK.
