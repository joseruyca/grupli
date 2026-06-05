# v15.22.5 — Finanzas optimizadas + revisión UX

## Objetivo

Pulir Finanzas para que funcione bien con grupos grandes, incluyendo grupos de 15, 20, 50 o 100 personas añadiendo gastos.

## Cambios clave

- Nuevo optimizador de liquidaciones.
- Grupli calcula el balance neto de todos los miembros y propone una lista corta de pagos escalable para grupos grandes, sin límite de 15 miembros.
- El cálculo trabaja en céntimos para evitar errores de redondeo.
- Si el grupo es enorme, usa un fallback greedy estable.
- La pestaña Saldos explica que Grupli cruza deudas automáticamente.
- El héroe de Finanzas ahora habla de pagos mínimos, no solo de pagos pendientes.
- La UI de saldos muestra cuántos cobran, cuántos deben y cuántos pagos mínimos hay.

## Ejemplo

Si Jose debe dinero a Marta, pero Alex debe dinero a Jose, Grupli no obliga a hacer pagos innecesarios.
Calcula el balance neto de todos y propone pagos finales para que todos queden a cero.

## Realtime

Se mantiene la actualización automática añadida en v15.22.3. Para que funcione en móvil real hay que haber ejecutado el SQL de realtime/publication en Supabase.

## SQL

Ejecutar `supabase/patch_v15_22_5_finance_optimizer_realtime.sql`.
No resetea datos.
