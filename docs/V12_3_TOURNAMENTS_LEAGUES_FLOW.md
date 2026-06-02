# Grupli v12.3 — Ligas y torneos bien planteados

Esta versión rehace el flujo de Torneos/Ligas sobre la base limpia v12.

## Enfoque de producto

El usuario no debe pelearse con configuraciones técnicas. El flujo correcto es:

1. Crear competición
2. Elegir formato
3. Elegir tipo de participante
4. Añadir participantes
5. Generar partidos automáticamente
6. Registrar resultados
7. Ver clasificación o cuadro
8. Finalizar o reabrir competición

## Formatos incluidos

### Liga todos contra todos

Pensada para grupos estables. Todos juegan contra todos y se calcula una tabla por:

- puntos
- diferencia
- goles/puntos a favor
- nombre como desempate final estable

### Eliminatoria / Copa

Pensada para torneos rápidos. Crea el primer cuadro con emparejamientos directos. Después de completar una ronda, se puede generar la siguiente ronda con los ganadores.

Regla actual: la eliminatoria simple necesita número par de participantes. Recomendado: 2, 4, 8 o 16.

### Americano / Ranking

Pensado para pádel, tenis, juegos o grupos donde se quiere rotar y acumular resultados. En esta versión usa el mismo motor de partidos que una liga, pero el texto y la experiencia están preparados para convertirlo en rondas rotativas más avanzadas después.

## Pantallas nuevas/mejoradas

- `Torneos / Ligas`: resumen, activos/finalizados y lista clara.
- `Nueva competición`: formulario guiado por tarjetas.
- `Detalle de competición`: hero, siguiente paso, métricas y secciones.
- `Resumen`: explicación, próximos partidos y top clasificación.
- `Tabla`: clasificación automática.
- `Partidos`: resultados por rondas.
- `Participantes`: añadir/quitar antes de generar partidos.

## Reglas de estabilidad

- No se usa la estructura antigua rota.
- No se cambia SQL en esta versión.
- No se mete navegación externa innecesaria.
- El torneo se gestiona dentro del grupo.
