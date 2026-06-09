# Grupli v16.12.2 — Agenda tap fix

Corrección centrada en la Agenda.

## Problema

En algunos dispositivos la pantalla de Agenda podía sentirse bloqueada: botones de asistencia, días, cambio semana/mes o tarjetas no respondían bien.

## Cambios

- El hero superior de Agenda deja de reutilizar la tarjeta del dashboard y usa la tarjeta propia de Agenda.
- Los controles principales de Agenda pasan a `GestureDetector` con `HitTestBehavior.opaque`:
  - selector Semana/Mes;
  - días de la semana;
  - calendario mensual;
  - flechas de mes;
  - cabecera de evento;
  - botones Voy/Duda/No.
- No requiere SQL nuevo.

## Prueba

1. Entrar en Agenda.
2. Cambiar Semana/Mes.
3. Pulsar días del calendario.
4. Crear plan.
5. Abrir tarjeta de evento.
6. Pulsar Voy/Duda/No.
