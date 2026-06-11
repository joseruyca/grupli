# Grupli v16.16.1 — Tournament scoring review

## Revisión

La v16.16 iba en la dirección correcta, pero durante la revisión se detectaron puntos importantes:

1. La app ya permitía elegir Voleibol, Ping pong, Dardos, Billar y Videojuegos, pero el `CHECK` SQL de `tournaments.scoring_type` todavía no aceptaba esos valores.
2. Si no se actualizaba SQL, la app podía acabar creando el torneo sin guardar bien el deporte.
3. En Americano, la tabla mostraba dos columnas casi duplicadas: juegos/puntos acumulados y PTS.
4. Los resultados por sets aceptaban demasiados parciales para un "mejor de 3" o "mejor de 5".
5. Había pequeños textos a corregir.

## Cambios

- Añadido `supabase/patch_v16_16_1_tournament_scoring_types.sql`.
- Actualizado `supabase/all_in_one.sql`.
- Americano: la tabla se centra en el total acumulado, contra y diferencia.
- Sets: validación según `best_of`.
- Mejorado mensaje cuando falta el parche SQL.
- Corregidos textos de creación.

## Nota de producto

La lógica de deporte primero es correcta, pero todavía hay margen para mejorar la UX de creación:
- seleccionar deporte;
- seleccionar formato;
- después mostrar el formulario de participantes adecuado;
- parejas con selector visual;
- americano con jugadores individuales obligatorios.

Esa mejora debe ir en una fase de UX específica para no mezclar cambios de base de datos y lógica de puntuación.
