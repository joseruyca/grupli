# v15.35.1 - Tournament build fix

Corrección puntual sobre v15.35.

## Arreglado

- Se sustituye el parámetro inválido `minHeight` usado directamente en `Container` por `constraints: BoxConstraints(minHeight: 90)`.
- Corrige el error de compilación Android:
  `Error: No named parameter with the name 'minHeight'.`

## Nota

No cambia la lógica de torneos ni el SQL respecto a v15.35, salvo conservar los archivos ya incluidos.
