# Grupli v16.17 — UX de creación de torneos

## Objetivo

Cerrar el flujo de creación para que Torneos no parezca un formulario genérico.

La app debe guiar según el deporte y el formato:

1. Nombre + deporte.
2. Formato.
3. Participantes adecuados.
4. Sistema de resultado.
5. Calendario.
6. Revisión.

## Cambios principales

### Orden de creación

Antes se añadían participantes antes de elegir bien el formato. Eso hacía raro el flujo para Americano, Manual y Eliminatoria.

Ahora el usuario elige primero:

- deporte;
- formato;
- y después la app pide jugadores, parejas o equipos según corresponda.

### Americano

- Solo permite jugadores individuales.
- Explica que no hay parejas fijas.
- Explica ranking individual y parejas rotativas.
- Mantiene rondas recomendadas y pistas/mesas.

### Pádel / tenis

- En liga/eliminatoria permite elegir:
  - parejas;
  - individual.
- El texto cambia según la elección.
- El placeholder enseña ejemplos reales tipo `Ana / Javi`.

### Fútbol / basket / volley / esports

- Fija el tipo como equipos.
- Evita que el usuario cree una liga de fútbol con “parejas” por error.

### Ping pong / dardos / billar / mus

- Permite jugadores, parejas o equipos.
- La app recomienda individual por defecto.

### Manual

- Permite jugadores, parejas o equipos.
- El selector visual de partidos se mueve al paso de participantes.
- También mantiene importación por texto como opción secundaria.

### Eliminatoria

- Añade control claro de sorteo:
  - sorteo automático recomendado;
  - o usar orden de participantes como cabeza de serie.
- Si el sorteo está desactivado, el orden funciona como seed.

## No requiere SQL

Esta versión no cambia tablas ni políticas.
