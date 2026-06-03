# V14.7 — Miembros, invitaciones y permisos

## Cambios de producto

- Pestaña Más convertida en centro de control del grupo.
- Bloque de acceso privado con código visible, copiar y compartir.
- Pantalla de miembros más clara:
  - owner protegido
  - admins separados
  - miembros separados
  - rol actual del usuario explicado
  - acciones seguras para hacer admin, quitar admin y expulsar
- Matriz de permisos:
  - Owner
  - Admin
  - Miembro
- Acción de salir del grupo para miembros/admins.
- El owner queda protegido y no puede expulsarse ni degradarse.

## SQL recomendado

`supabase/patch_v14_7_members_permissions.sql`

No resetea datos. Añade RPCs seguras para gestionar roles y salida del grupo. La app incluye fallback, pero este parche deja el comportamiento más robusto.
