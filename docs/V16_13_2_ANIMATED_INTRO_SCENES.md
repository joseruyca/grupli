# Grupli v16.13.2 — Animated intro scenes

## Objetivo

Reemplazar la intro visual genérica por mini escenas animadas hechas directamente con Flutter.

## Qué se ha cambiado

- La intro ya no usa una escena estática con un icono central.
- Cada pantalla tiene una maqueta animada propia:
  - Grupo privado.
  - Agenda y asistencia.
  - Finanzas + torneos.
- No se usan GIFs, vídeos ni imágenes externas.
- No hay referencias a apps externas.
- Las animaciones usan widgets Flutter:
  - AnimationController.
  - AnimatedBuilder.
  - TweenAnimationBuilder.
  - AnimatedContainer.
  - Transform.
  - Opacity.
- La animación se repite de forma suave para dar sensación de app viva.

## Escena 1 — Grupo privado

- Tarjeta de grupo.
- Avatares que aparecen uno a uno.
- Chip privado.
- Mini módulos de Agenda, Finanzas y Torneos.

## Escena 2 — Agenda

- Mini calendario semanal.
- Tarjeta de evento.
- Botones Voy / Duda / No.
- Contador que cambia de 3/4 a 4/4.

## Escena 3 — Finanzas y Torneos

- Pago recomendado que pasa a liquidado.
- Mini clasificación de torneo.
- Movimiento de ranking.

## Nota

Esta versión no necesita assets nuevos ni SQL.
