# Grupli v15.22.4 — Auth user delete/admin cleanup fix

Esta fase corrige el error de Supabase:

`Failed to delete user: Database error deleting user`

## Causa

El borrado directo desde `Authentication > Users` podía fallar porque el usuario tenía datos relacionados en tablas públicas:

- grupos creados como owner;
- gastos pagados por ese usuario;
- participantes de gastos;
- tickets de soporte;
- dispositivos push;
- notificaciones;
- avatars en Storage.

Además, el trigger que protege al owner de un grupo podía bloquear cascades administrativos.

## Qué cambia

- `expenses.paid_by` ahora usa `ON DELETE CASCADE`.
- `protect_owner_role()` sigue protegiendo al owner dentro de la app, pero no bloquea borrados admin.
- La política de `group_members` impide expulsar al owner desde la app.
- Se añade RPC:

```sql
select public.admin_delete_user_by_email('email@dominio.com', 'ELIMINAR USUARIO');
```

- `delete_my_account('ELIMINAR')` queda actualizado para tablas nuevas.

## Uso recomendado

Para borrar un usuario problemático, usa SQL Editor:

```sql
select public.admin_delete_user_by_email('usuario@dominio.com', 'ELIMINAR USUARIO');
```

Después revisa `Authentication > Users`. El usuario debería haber desaparecido.

## No resetea datos

Este parche no borra la base de datos y no elimina usuarios por sí solo. Solo corrige las reglas y añade la función segura.
