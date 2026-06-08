# Grupli v16.4 — Manual perfecto

Esta versión mejora el formato manual de torneos para que no dependa solo de escribir emparejamientos en texto.

## Incluye

- Editor visual de partidos manuales durante la creación del torneo.
- Añadir partido con selectores de participante A y participante B.
- Fechas individuales desde la creación: cada partido puede tener su propia fecha, hora, duración, pista, ubicación y notas.
- Importar desde texto se mantiene como alternativa rápida, pero el editor visual tiene prioridad.
- Añadir partidos manuales después de crear el torneo desde la pestaña Partidos.
- Duplicar jornada completa en torneos manuales.
- Reordenar partidos dentro de una jornada con Subir/Bajar.
- La Agenda se sincroniza si el partido manual tiene fecha y se marca añadir a Agenda.

## Notas

No requiere SQL nuevo respecto a la v16 si ya se ejecutó `supabase/all_in_one.sql`.

## Prueba recomendada

1. Crear torneo manual.
2. Añadir 4 participantes.
3. En Formato, usar el editor visual para crear 3 partidos con fechas diferentes.
4. Crear torneo con Agenda activada.
5. Entrar en Partidos.
6. Añadir un partido nuevo con selectores.
7. Duplicar una jornada.
8. Reordenar partidos con Subir/Bajar.
9. Comprobar que los partidos con fecha aparecen correctamente en Agenda.
