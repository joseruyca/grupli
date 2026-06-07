# Grupli v15.30.2 — Fix compilación Agenda

Corrige el error de compilación introducido en v15.30.1 en `CalendarTab`.

## Error corregido

`Undefined name group` dentro de `_CalendarTabState`.

## Solución

La tarjeta `AgendaPremiumHero` ahora recibe `widget.group`, que es el grupo correcto pasado a la pantalla de Agenda.

No requiere SQL.
