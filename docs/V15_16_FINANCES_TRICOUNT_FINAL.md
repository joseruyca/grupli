# v15.16 — Finanzas final con reparto claro

Objetivo: dejar Finanzas como una sección rápida, clara y accionable.

## Cambios

- Pestañas principales: Gastos, Saldos y Liquidar.
- Liquidaciones recomendadas marcables como pagadas.
- Al registrar una liquidación se guarda en `settlement_payments`.
- Los balances se recalculan restando los pagos ya registrados.
- Historial breve de pagos registrados.
- Edición de gastos existentes:
  - concepto
  - importe
  - pagador
  - participantes
  - reparto manual
  - nota
- Avatares en gastos, saldos, liquidaciones, detalle y creación/edición.

## SQL

Ejecutar `supabase/patch_v15_16_finances_settlements_final.sql`.
