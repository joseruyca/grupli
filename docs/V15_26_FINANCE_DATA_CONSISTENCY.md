# Grupli v15.26 — Finanzas y datos consistentes

Objetivo: dejar Finanzas con una lógica clara y estable antes de seguir endureciendo invitaciones, realtime y admin.

## Principio de producto

Grupli no debe liquidar gasto por gasto. El modelo correcto es:

1. **Gastos** = historial de lo que se ha pagado.
2. **Saldos** = balance neto real de cada miembro.
3. **Liquidar** = pagos mínimos recomendados para dejar el grupo a cero.

## Mejoras incluidas

- Confirmación antes de registrar una liquidación.
- Las liquidaciones registradas se pueden deshacer.
- Deshacer una liquidación vuelve a meter ese importe en el balance neto.
- Se añade RPC segura `cancel_settlement_payment_atomic`.
- Se mantiene la lógica por céntimos para evitar errores de redondeo.
- Se refuerza Realtime en `settlement_payments`.
- Textos de Finanzas más claros: pagos mínimos por balance neto.

## Casos que hay que probar

- 1 persona paga por todos.
- Varias personas pagan gastos distintos.
- Alguien no participa en un gasto.
- Reparto manual.
- Editar gasto después de creado.
- Eliminar gasto.
- Marcar liquidación como pagada.
- Deshacer una liquidación.
- Dos móviles viendo el mismo grupo.
- Grupo grande con muchos miembros y muchos gastos.
- Redondeos con céntimos.

## SQL

Ejecutar `supabase/patch_v15_26_finance_data_consistency.sql`.

No resetea la base de datos.
