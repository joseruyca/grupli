# Grupli v16.17.1 — Tournament creation UX review fix

## Objetivo

Revisión de la fase v16.17 de creación de torneos.

La dirección era correcta, pero quedaban incoherencias importantes en el método de añadir participantes después de crear el torneo.

## Correcciones

### 1. Creación de torneo

En el paso de participantes:

- Si el torneo es Americano, solo se permite cargar jugadores individuales.
- Si la competición usa parejas, el botón de cargar miembros se oculta para evitar que se creen jugadores sueltos por error.
- Si la competición usa equipos, el botón de cargar miembros se oculta para evitar confundir miembros del grupo con equipos.
- Los textos de ayuda cambian según el caso.

### 2. Detalle del torneo / Participantes

La pestaña Participantes ahora se adapta mejor:

- Americano:
  - muestra "Jugadores del americano";
  - no muestra botón de crear pareja;
  - explica que Grupli rota las parejas.

- Parejas:
  - muestra "Parejas participantes";
  - permite crear pareja visualmente;
  - permite escribir parejas como `Ana / Javi`.

- Individual:
  - muestra "Jugadores participantes";
  - permite añadir miembros del grupo.

- Equipos:
  - muestra "Equipos participantes";
  - no muestra botón de miembros ni pareja;
  - usa "Escribir equipos".

### 3. Protección adicional

Aunque algún botón se llegase a mostrar por error:

- Crear pareja queda bloqueado si el torneo no es de parejas.
- Añadir miembros queda bloqueado si el torneo es por equipos o parejas.
- En Americano se bloquean parejas fijas.

### 4. Americano

Se oculta la acción de "No presentado / victoria admin." en partidos de Americano, porque un partido de Americano representa dos parejas rotativas dentro de un ranking individual. Esa acción especial necesita una lógica propia y no debe aplicarse como si fuera un equipo contra otro.

## SQL

No requiere SQL nuevo.

## Nota

No cambia el sistema de puntuación ni la estructura de base de datos. Es una mejora de seguridad/UX sobre el flujo de participantes.
