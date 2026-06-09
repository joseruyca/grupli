# Grupli v16.12.1 — Tournament compile fix

Corrección pequeña sobre v16.12.

## Problema

La función `tournamentTieBreakers` requiere dos argumentos:

```dart
tournamentTieBreakers(tournament, scoringType)
```

En el editor del torneo se estaba llamando con un solo argumento:

```dart
tournamentTieBreakers(tournament)
```

Eso rompía `flutter analyze` y la compilación Android.

## Solución

Se actualiza la llamada a:

```dart
tournamentTieBreakers(tournament, originalScoringType)
```

## SQL

No requiere SQL nuevo.
