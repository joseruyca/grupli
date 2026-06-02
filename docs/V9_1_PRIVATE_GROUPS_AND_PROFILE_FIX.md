# Grupli v9.1 — grupos privados + fix perfil ausente

## Motivo

La creación de grupo fallaba con:

`insert or update on table "groups" violates foreign key constraint "groups_owner_id_fkey"`

Esto pasaba cuando el usuario ya existía en `auth.users`, pero después de resetear las tablas de Grupli no existía su fila correspondiente en `public.profiles`.

## Solución

- Nuevo helper SQL `ensure_current_profile()`.
- `create_group_atomic()` ahora crea/actualiza el perfil del usuario antes de crear el grupo.
- `join_group_with_code()` también asegura el perfil antes de meter al usuario como miembro.
- Los grupos pasan a ser siempre privados.
- Se elimina de la UI de creación:
  - privacidad pública
  - días habituales
  - hora habitual
  - ubicación habitual
  - mínimo de personas
  - tipo obligatorio visible
- Los días, horas y mínimos pertenecen a cada quedada/evento, no al grupo.

## Regla de producto

Un grupo en Grupli es un espacio cerrado. El acceso será por:

- código
- enlace
- invitación
- QR

No habrá grupos públicos en esta fase.
