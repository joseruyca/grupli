# Grupli v15.34 — Torneos/Ligas rehechos de raíz

Esta fase elimina el flujo anterior de torneos y lo sustituye por una versión más simple, estable e intuitiva.

## Decisión técnica

No se añade parche SQL. Se mantiene el modelo canónico de `all_in_one.sql`:

- `tournaments`
- `tournament_teams`
- `matches`

La reconstrucción es principalmente de UI, navegación y flujo.

## Nuevo flujo

1. Crear competición en una sola pantalla.
2. Elegir formato:
   - Liga todos contra todos.
   - Copa / eliminatoria.
   - Americano / ranking.
3. Elegir participantes:
   - jugadores;
   - parejas;
   - equipos.
4. Elegir puntuación:
   - general;
   - fútbol;
   - tenis/pádel;
   - basket;
   - cartas/mus;
   - libre.
5. Escribir participantes en líneas separadas.
6. Crear y generar partidos automáticamente.

## Pantalla de detalle

Nueva estructura:

- Resumen
- Partidos
- Tabla
- Equipos

## Mejoras clave

- Sin FutureBuilder grande en detalle.
- Carga manual controlada con estado local.
- Menos dependencias de embeds de Supabase.
- Torneos cargan torneos, equipos y partidos por consultas separadas.
- Resultado por partido con marcador y detalle opcional.
- Clasificación automática.
- Posibilidad de renombrar participantes.
- Eliminación de participantes solo si no están en partidos.
- Regenerar calendario con confirmación.

## Inspiración de producto

El flujo está basado en patrones comunes de apps de torneos: crear torneo, añadir competidores/equipos, generar calendario/cuadro, registrar resultados y consultar clasificación/partidos.
