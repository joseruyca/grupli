# Grupli v15.25.3 — Roles de administración de app

Esta fase deja cerrado el modelo de administración global de Grupli con tres roles:

- `owner`: control total de la app. Solo cuentas propias o de máxima confianza.
- `support`: puede ver y responder reportes de usuarios. No debe tocar acciones críticas de usuarios.
- `viewer`: solo puede ver métricas y estado general. No puede modificar datos ni reportes.

## Cómo entrar como owner

1. La cuenta debe existir en Supabase Auth.
2. Ejecuta `supabase/patch_v15_25_3_admin_roles_owner_support_viewer.sql`.
3. Inicia sesión en la app con `ruyca58@gmail.com`.
4. Ve a `Perfil → Panel admin`.

El SQL asegura como `owner` estas cuentas:

- `joseruyca@gmail.com`
- `ruyca58@gmail.com`

## Gestionar roles desde SQL

```sql
select public.admin_set_app_admin_by_email('persona@dominio.com', 'support');
select public.admin_set_app_admin_by_email('persona@dominio.com', 'viewer');
select public.admin_set_app_admin_by_email('persona@dominio.com', 'owner');
select public.admin_remove_app_admin_by_email('persona@dominio.com');
```

Solo un `owner` puede ejecutar correctamente esas funciones.

## Comprobar administradores

```sql
select
  p.email,
  p.full_name,
  a.role,
  a.created_at
from public.app_admins a
join public.profiles p on p.id = a.user_id
order by
  case a.role when 'owner' then 1 when 'support' then 2 else 3 end,
  a.created_at desc;
```

## Permisos previstos

### Owner

Puede usar todo el panel admin y futuras acciones críticas:

- métricas;
- reportes;
- usuarios;
- grupos;
- dispositivos;
- roles;
- acciones críticas.

### Support

Puede ayudar en soporte:

- ver reportes;
- marcar reportes en revisión;
- resolver reportes;
- ver señales básicas de calidad.

No debe poder bloquear/borrar usuarios ni cambiar roles.

### Viewer

Puede ver estado general:

- usuarios totales;
- grupos totales;
- reportes abiertos;
- críticos;
- calidad general.

No ve detalles sensibles de reportes ni puede modificar nada.
