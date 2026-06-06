# Grupli v15.25.5 — Perfil, eliminar grupos y navegación

## Cambios

- Perfil con botón de volver atrás visible.
- Si Perfil se abre desde un grupo, vuelve al grupo.
- Si Perfil se abre desde la barra inferior, vuelve a Inicio.
- Los grupos mostrados dentro del Perfil ahora abren el grupo correcto.
- El botón “Ver todos los grupos” abre una lista completa real.
- Desde esa lista se puede entrar directamente a cualquier grupo.
- Ajustes del grupo permite eliminar grupo con confirmación `ELIMINAR GRUPO`.
- Al eliminar un grupo, se sale automáticamente a Mis grupos y la lista se refresca.
- SQL seguro `delete_group_safe` para borrar grupos owner sin romper la protección del owner.

## SQL

Ejecutar `supabase/patch_v15_25_5_profile_group_delete_navigation.sql`.
No resetea datos.
