# v15.22.3 — SQL de liquidaciones + realtime + pulido

Esta versión corrige dos puntos importantes detectados en APK:

1. **Fallos SQL al liquidar pagos**
   - Se añade una función segura `create_settlement_payment_atomic`.
   - La app intenta registrar liquidaciones mediante RPC para evitar errores de RLS.
   - Si la función aún no existe, mantiene compatibilidad con el insert directo.

2. **Cambios visibles en directo entre móviles**
   - Se habilita realtime en tablas clave del grupo.
   - `GroupShell` escucha cambios de eventos, asistencia, gastos, participantes, liquidaciones, torneos, partidos y miembros.
   - La pantalla de Mis grupos también se actualiza si hay cambios de grupos/miembros.
   - Los refrescos están debounced para no recargar varias veces seguidas.

## SQL necesario

Ejecutar:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v15_22_3_sql_realtime_polish.sql" | Set-Clipboard
```

Después pegar en Supabase SQL Editor y pulsar Run.

No resetea datos.
