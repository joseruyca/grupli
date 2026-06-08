# Grupli v15.34.1 — Fix compilación Torneos

Corrige el error de compilación de la reconstrucción de torneos:

```text
The getter 'diff' isn't defined for the type 'TeamStanding'
```

La tabla de clasificación ahora usa `standing.goalDifference`, que es el getter real del modelo.

No requiere SQL.
