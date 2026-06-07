# Grupli v15.31.2 — Startup LateInitialization fix

Corrige el fallo visible en APK:

`LateInitializationError: Field '' has not been initialized.`

## Causa principal

En `AuthedShell` existía:

```dart
late int tab;
```

pero no se inicializaba antes de usarlo en `pages[tab]`.

## Corrección

```dart
int tab = 0;
```

Además se hizo más robusto el listener de auth:

- `_authSub` pasa a ser nullable;
- `dispose` usa `_authSub?.cancel()`;
- el listener de app links se lanza con `unawaited`.

No requiere SQL.
