# Grupli v16.6.2 — Compile fix

Corrección de compilación tras v16.6.1.

## Problema

Flutter fallaba en `lib/main.dart` porque la tabla de clasificación tenía una lista `const` de columnas, pero una columna usaba una variable dinámica:

`isAmericano ? 'Jugador' : 'Equipo'`

Eso no puede estar dentro de una lista `const`.

## Solución

Se ha quitado el `const` de la lista `columns` y se han dejado como `const` las columnas estáticas.

## SQL

No requiere SQL nuevo.
