# V11.1 Vercel build fix

El fallo más probable del build web era el bloque `assets:` de `pubspec.yaml`.

El proyecto no usa imágenes locales mediante `Image.asset` ni `AssetImage`, pero `pubspec.yaml` declaraba:

```yaml
assets:
  - assets/
```

En Git, una carpeta vacía no se sube. En Vercel, esa carpeta puede no existir y Flutter Web puede fallar al compilar por una entrada de assets inexistente.

Cambio aplicado:
- se elimina la declaración `assets:` mientras no haya assets reales.
- no se toca Supabase.
- no se cambia navegación ni funcionalidades.
