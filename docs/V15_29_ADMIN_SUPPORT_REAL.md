# Grupli v15.29 — Admin/soporte más real

Esta fase mejora el panel de administración para que el dueño de la app pueda controlar mejor el estado de Grupli antes de beta.

## Roles

- `owner`: control total de la app.
- `support`: puede ver/responder reportes, pero no gestionar usuarios críticos.
- `viewer`: solo métricas y estado general.

## Mejoras añadidas

### Panel admin por secciones

- Reportes
- Usuarios
- Grupos
- Dispositivos push
- Actividad/calidad

### Reportes

El admin/support puede:

- marcar como en revisión;
- resolver;
- cerrar;
- responder al usuario con `admin_note`.

El usuario ve la respuesta de soporte en su lista de reportes.

### Usuarios

Solo `owner` puede ver la lista de usuarios y marcar:

- activo;
- bloqueado.

El bloqueo queda guardado como estado administrativo en `app_user_flags`.

### Grupos

Solo `owner` puede ver una vista general de grupos:

- owner;
- número de miembros;
- eventos;
- gastos;
- torneos.

### Dispositivos

Solo `owner` puede ver dispositivos registrados para push:

- usuario;
- plataforma;
- versión;
- estado;
- último visto.

### Calidad

Se muestran eventos internos recientes para revisar actividad técnica y soporte.

## SQL

Ejecutar:

```powershell
Get-Content ".\supabase\patch_v15_29_admin_support_real.sql" | Set-Clipboard
```

No resetea la base de datos.
