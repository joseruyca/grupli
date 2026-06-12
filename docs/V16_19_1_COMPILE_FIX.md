# Grupli v16.19.1 — Compile fix

## Motivo

`flutter analyze` y la creación de APK fallaban porque `StatusNotice` seguía aceptando solo:

```dart
StatusNotice(ok: ..., text: ...)
```

pero la limpieza de producto v16.19 añadió avisos informativos con:

```dart
StatusNotice(icon: ..., title: ..., body: ...)
```

## Cambio

`StatusNotice` ahora soporta ambos usos:

- modo simple: `ok + text`;
- modo informativo: `icon + title + body`.

## SQL

No requiere SQL nuevo.
