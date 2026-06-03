# V14.5.1 — Fix de compilación de Finanzas

Corrige el error de Dart:

`The argument type 'num' can't be assigned to the parameter type 'double'`

Causa:
- En algunos cálculos de reparto se usaba `0` en un operador ternario.
- Dart infería `num` en vez de `double`.

Solución:
- Cambiado a `0.0` en los cálculos de:
  - reparto igual
  - reparto manual
  - preview de Finanzas

No cambia SQL.
