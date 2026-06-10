# v12.4 — Finanzas con reparto sencillo

Esta fase convierte Finanzas en una herramienta real para grupos privados.

## Objetivo de producto

La pantalla Finanzas debe responder de forma rápida a estas preguntas:

- cuánto se ha gastado en el grupo;
- quién ha pagado cada cosa;
- quién participa en cada gasto;
- quién debe dinero a quién;
- qué pagos concretos dejarían el grupo a cero;
- qué gastos ya están liquidados.

## Cambios principales

- Resumen superior con saldo del usuario y dinero pendiente del grupo.
- Cálculo de balances por miembro.
- Liquidación recomendada: lista de pagos mínimos tipo “Carlos paga a Ana 8,50 €”.
- Nuevo formulario de gasto más claro:
  - concepto;
  - importe total;
  - pagador;
  - dividir entre todos o algunos miembros;
  - preview automático del importe por persona;
  - nota opcional.
- Detalle de gasto:
  - total;
  - quién pagó;
  - participantes;
  - parte de cada uno;
  - estado pagado/pendiente;
  - marcar gasto liquidado;
  - reabrir pagos;
  - eliminar gasto.

## Reglas de cálculo

- El pagador se considera pagado automáticamente.
- Cada participante tiene una parte igual del gasto.
- Si un participante ya ha pagado su parte, esa deuda no aparece en la liquidación recomendada.
- Los balances se calculan solo con importes pendientes de liquidar.
- El gasto total histórico sigue mostrando todo lo gastado.

## Regla de arquitectura

No se recupera la estructura rota anterior. Todo sigue dentro del rebuild limpio v12 y sin `AppScreen`.
