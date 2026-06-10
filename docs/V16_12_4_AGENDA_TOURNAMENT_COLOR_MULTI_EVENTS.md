# Grupli v16.12.4 — Agenda torneos en dorado + varios partidos mismo día

## Cambios

- Los eventos creados desde ligas/torneos ahora se detectan como eventos especiales aunque el título incluya pádel, tenis o fútbol.
- Los partidos de liga/torneo aparecen en dorado/ámbar en:
  - puntos del calendario semanal;
  - puntos del calendario mensual;
  - tarjeta del día seleccionado;
  - tarjeta del evento de Agenda;
  - tarjeta de inicio si el próximo plan es de liga/torneo.
- Si hay varios eventos el mismo día, la Agenda ya no muestra solo el primero en el bloque superior:
  - muestra todos los próximos de ese día, hasta 3 en Agenda;
  - si hay más, avisa con “+ X más”.
- En el inicio del grupo, si el próximo día tiene varios planes/partidos, se muestra una tarjeta resumen con varios eventos del mismo día.

## Motivo

Antes un partido de liga podía detectarse como partido normal si el título incluía “pádel” o “tenis”.
Ahora se prioriza detectar torneos/ligas por notas y título para que visualmente sea especial.
