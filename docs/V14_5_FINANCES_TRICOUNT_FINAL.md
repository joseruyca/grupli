# V14.5 — Finanzas con reparto claro definitivo

Esta fase pule Finanzas para que sea una de las funciones fuertes de Grupli.

## Cambios

- Hero financiero con lectura clara:
  - Todo está cuadrado
  - Te deben X
  - Debes X
  - Hay pagos pendientes
- Métricas compactas:
  - total histórico
  - gastos abiertos
  - gastos liquidados
- Plan de pagos recomendado para dejar el grupo a cero.
- Balances individuales mejor presentados.
- Gastos abiertos separados del historial liquidado.
- Crear gasto mejorado:
  - pagador
  - dividir entre todos
  - dividir entre algunos
  - reparto manual por persona
  - preview del reparto antes de guardar
- Detalle de gasto mejorado:
  - marcar participante como pagado/pendiente
  - el estado del gasto se actualiza según los pagos
  - marcar todo como liquidado
  - reabrir pagos
  - eliminar gasto

## SQL

No requiere SQL nuevo. Usa la tabla `expense_participants.share_amount` que ya existía desde v12.
