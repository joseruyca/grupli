# Grupli v16.12.3 — Agenda tournament events + creator cleanup

## Objetivo

Corregir bloqueo visual de Agenda cuando los partidos de torneos/ligas se añaden como eventos, y limpiar la primera pantalla del creador de torneos.

## Agenda

Problema probable:
- La tarjeta `EventAgendaCard` usaba una estructura con `Row(crossAxisAlignment: CrossAxisAlignment.stretch)` dentro de una lista vertical.
- Cuando aparecían eventos generados desde torneos, esa tarjeta podía romper el layout y dejar la Agenda sin interacción visible.

Cambio:
- `EventAgendaCard` se rehace con una estructura vertical robusta:
  - cabecera pulsable para abrir evento;
  - separador;
  - botones de asistencia abajo;
  - sin `CrossAxisAlignment.stretch` en altura no acotada.
- Se mantiene el comportamiento de:
  - abrir evento;
  - responder Voy / Duda / No;
  - refrescar Agenda.

## Creador de torneos

Cambio:
- Se sustituye “Plantillas rápidas” por “Tipo de torneo”.
- Se dejan solo cuatro opciones:
  - Liga
  - Americano
  - Eliminatoria
  - Manual
- Se quitan emojis para evitar confusión.
- Se usan iconos neutros.
- El modo rápido queda explicado: se sigue el mismo proceso, pero la app oculta ajustes técnicos y aplica valores seguros.

## SQL

No requiere SQL nuevo.
