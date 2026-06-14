# Grupli v16.22 — Qué llevamos en eventos

## Objetivo

Añadir una función muy simple para eventos: cada miembro puede decir qué va a llevar, sin que el creador tenga que repartir tareas.

Nombre de producto: **Qué llevamos**.

## UX incluida

- Tarjeta nueva dentro del detalle del evento.
- Botón claro: **Añadir lo que llevo**.
- Si ya has añadido algo, el botón cambia a **Editar lo que llevo**.
- Diálogo sencillo con texto libre y sugerencias rápidas: Bebida, Comida, Hielo, Vasos, Pelotas, Altavoz, Postre y Agua.
- Cada usuario puede editar o quitar solo su propia aportación desde la app.
- Diseño pensado para ser entendido por cualquier persona: texto claro, frases cortas, sin estados complicados.

## Seguridad

- No se han añadido claves, tokens ni credenciales al frontend.
- No hay operaciones sensibles en cliente.
- Las aportaciones se guardan en `event_contributions` con RLS.
- Solo miembros del grupo pueden leer aportaciones del evento.
- Cada usuario solo puede crear/editar su aportación.
- Owner/admin puede borrar aportaciones desde políticas RLS para moderación futura.
- La tabla valida longitud entre 2 y 240 caracteres.
- Un trigger fija `group_id` desde el evento para evitar manipulación desde frontend.

## SQL

- El reset global `supabase/all_in_one.sql` ya incluye la tabla.
- Para actualizar una base existente sin reset, ejecutar:

```sql
supabase/patch_v16_22_event_contributions.sql
```

## Versión

- `pubspec.yaml`: `0.16.22+16220`
- `AppData.appVersion`: `v16.22`
