# v15.13.1 — Compile fix

Corrección rápida de compilación tras el rediseño de Finanzas.

## Cambios

- Arreglado `FinanceSegmentedTabs`: se usaba `items.length`, pero esa variable no existía.
- Ahora usa `labels.length`, que corresponde a las pestañas reales: Gastos, Saldos y Liquidar.

No requiere SQL nuevo.
