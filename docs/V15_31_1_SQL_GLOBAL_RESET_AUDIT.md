# Grupli v15.31.1 — Auditoría SQL y reset global limpio

## Conclusión

Antes había dos archivos que podían confundirse como reset global:

- `supabase/all_in_one.sql`
- `supabase/reset_global_v15_29.sql`

El problema es que `reset_global_v15_29.sql` estaba desactualizado y no incluía los últimos cambios de Agenda/Realtime.

## Decisión

Desde esta versión solo debe usarse:

```text
supabase/all_in_one.sql
```

El archivo `reset_global_v15_29.sql` queda eliminado del ZIP.

## Problemas corregidos

### 1. Tablas admin/soporte no se borraban en el reset inicial

El reset anterior no borraba explícitamente:

- `app_admins`
- `support_tickets`
- `app_quality_events`
- `app_user_flags`

Aunque se borrase `profiles`, esas tablas podían quedarse vivas sin FK o con datos antiguos. Eso era peligroso para un reset global.

Ahora se borran explícitamente y en orden seguro.

### 2. Funciones nuevas no se limpiaban al principio

El reset anterior solo eliminaba algunas funciones antiguas. Ahora elimina las funciones propias de Grupli por nombre, incluyendo overloads.

### 3. Faltaba consolidar Realtime

El reset global ahora vuelve a añadir a `supabase_realtime` las tablas principales después de recrearlas.

### 4. Reset viejo eliminado

Para evitar confusión, no hay dos resets globales.

## Qué ejecutar en Supabase

```powershell
Get-Content ".\supabase\all_in_one.sql" | Set-Clipboard
```

Después:

```text
Supabase → SQL Editor → New query → pegar → Run
```

## Importante

Este SQL borra datos de Grupli:

- grupos
- eventos
- asistencias
- finanzas
- torneos
- notificaciones
- reportes
- roles admin globales

No borra usuarios de `auth.users` ni borra `storage.objects` directamente.
