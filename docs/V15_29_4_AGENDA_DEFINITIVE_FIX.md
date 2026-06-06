# Grupli v15.29.4 — Reparación definitiva de Agenda

La agenda se ha cambiado para que no pueda quedarse en blanco.

## Cambios

- La pantalla ya no depende de un `FutureBuilder` que pueda dejar todo el contenido sin pintar.
- El encabezado, tarjeta principal, calendario y botones siempre se renderizan.
- Si falla la carga, aparece un bloque visible con reintentar/crear plan.
- Se pasa el `groupId` real desde `GroupShell`, en vez de depender del mapa del grupo.
- `AppData.events()` usa primero la RPC `group_events_with_attendance`.
- Si la RPC no existe todavía, cae a consulta directa.
- Si falla el embed de asistencias, cae a eventos simples.

## SQL

Ejecutar:

```powershell
Get-Content ".\supabase\patch_v15_29_4_agenda_definitive_fix.sql" | Set-Clipboard
```

No resetea nada.
