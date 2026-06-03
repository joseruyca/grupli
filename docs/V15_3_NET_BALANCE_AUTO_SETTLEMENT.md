# V15.3 — Finanzas con balance neto y liquidación automática

Cambios principales:

- Finanzas calcula el balance neto real por persona.
- Si alguien debía dinero y después paga un gasto nuevo, Grupli compensa automáticamente ambas cosas en el balance.
- La pantalla muestra:
  - deuda bruta
  - dinero real que hay que mover
  - dinero compensado automáticamente
- El plan de pago se renombra como liquidación automática.
- Los pagos recomendados ahora explican que son el mínimo necesario tras compensar deudas cruzadas.
- Los balances individuales se ordenan por importancia.
- Crear gasto explica que el nuevo gasto se compensará con saldos anteriores.
- No requiere SQL nuevo.

Regla de producto:

Pagado por persona - parte que le corresponde = balance neto.
Los balances positivos son personas a las que les deben dinero.
Los balances negativos son personas que deben dinero.
Grupli genera el menor conjunto razonable de pagos para dejar el grupo a cero.
