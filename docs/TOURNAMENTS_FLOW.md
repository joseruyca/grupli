# Grupli Torneos

## v7

Esta fase convierte torneos en una funcionalidad real básica.

Incluye:

- Crear torneo.
- Crear equipos.
- Generar partidos todos contra todos.
- Registrar resultado.
- Reabrir resultado.
- Borrar partido pendiente.
- Calcular clasificación real.
- Finalizar/reabrir torneo.
- Eliminar torneo.

## Flujo recomendado

1. Crear torneo.
2. Entrar al torneo.
3. Ir a Equipos.
4. Añadir equipos.
5. Ir a Partidos.
6. Generar partidos.
7. Meter resultados.
8. Ver Tabla.
9. Finalizar torneo.

## Cálculo

La clasificación se calcula en Flutter con `tournament_calculator.dart`, separada de la UI para evitar romper pantallas.

Campos:

- PJ: partidos jugados.
- PG: partidos ganados.
- PE: empates.
- PP: derrotas.
- DG: diferencia.
- Pts: puntos.

## Próximas mejoras

- Equipos con miembros reales.
- Eliminatorias.
- Torneo americano.
- Calendario de partidos con fecha.
- Historial de campeones.
