# V15.6 — Revisión SQL/RLS + errores humanos + borrar cuenta

Cambios principales:

- Nueva RPC segura `delete_my_account(confirm_text text)`.
- El usuario debe escribir `ELIMINAR` para borrar la cuenta.
- El borrado elimina:
  - perfil
  - foto/avatar del bucket `avatars`
  - dispositivos push
  - notificaciones
  - ajustes
  - asistencia personal
  - gastos pagados/creados por el usuario
  - grupos donde el usuario sea owner
  - membresías en otros grupos
  - usuario de Supabase Auth
- Trigger `protect_owner_role()` ajustado para permitir borrados internos controlados durante eliminación de cuenta.
- Errores visibles más humanos:
  - permisos
  - sesión caducada
  - conexión
  - restricciones de datos
  - Supabase/PostgREST
- `security_checks.sql` ampliado.

## SQL obligatorio

Ejecutar:

```powershell
Get-Content ".\\supabase\\patch_v15_6_security_delete_account.sql" | Set-Clipboard
```

Luego pegar en Supabase SQL Editor y ejecutar.
