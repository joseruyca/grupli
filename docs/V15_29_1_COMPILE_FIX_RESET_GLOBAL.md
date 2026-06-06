# Grupli v15.29.1 — Compile fix + reset global

Corrige el error de APK:

- `onReply` nullable pasado directamente a `onTap`.

También añade:

- `supabase/reset_global_v15_29.sql`

Ese archivo es una copia clara del `all_in_one.sql` para reset global.

## Reset global

Usar solo si quieres borrar y recrear las tablas propias de Grupli:

```powershell
Get-Content ".\supabase\reset_global_v15_29.sql" | Set-Clipboard
```

No borra `auth.users` ni `storage.objects` directamente.
