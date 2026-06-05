# v15.22.6 — Finanzas sin límite práctico de miembros

## Motivo

La versión anterior documentaba el optimizador exacto para hasta 15 saldos activos. Eso no encaja con Grupli: un grupo puede tener 15, 20, 50 o 100 miembros.

## Cambio aplicado

- Eliminado el límite de 15 miembros activos.
- Las liquidaciones usan ahora un algoritmo escalable por balance neto.
- Funciona en céntimos para evitar errores de redondeo.
- No liquida gasto por gasto: primero calcula cuánto queda realmente a favor o en contra cada persona.
- Después cruza deudores y receptores para proponer una lista corta de pagos.
- Con N personas con saldo activo, genera como máximo N-1 pagos útiles.

## Ejemplo

Si una persona debe dinero, pero otra persona le debe a ella, Grupli no obliga a pagar siguiendo cada gasto original. Cruza todos los movimientos y propone quién debe pagar a quién para dejar el grupo a cero.

## Nota técnica

Para grupos muy grandes no se usa una búsqueda combinatoria exponencial, porque no es viable en móvil. Se usa un método estable, rápido y escalable, similar a la lógica que debe tener una app real para grupos numerosos.

## SQL

No requiere SQL nuevo sobre v15.22.5.
