# Grupli Architecture Guardrails

## Objetivo

Evitar que al cambiar una funcionalidad se rompa otra.

## Organización obligatoria

Cada funcionalidad debe vivir dentro de `lib/features/<feature>`:

- `screens/`: interfaz de la funcionalidad.
- `<feature>_repository.dart`: acceso a Supabase.
- calculadoras/helpers propios si la lógica crece.

Ejemplos actuales:

- `features/groups`
- `features/calendar`
- `features/finances`
- `features/tournaments`
- `features/profile`
- `features/settings`

## Reglas

1. Las pantallas no deben consultar Supabase directamente.
2. Supabase solo se toca desde repositories.
3. Los cálculos no deben ir mezclados con widgets grandes.
4. UI reutilizable siempre en `lib/ui`.
5. Colores, radios, tipografía y espacios siempre en `lib/theme`.
6. Si una pantalla necesita mucho cálculo, crear archivo tipo `*_calculator.dart`.
7. No tocar `all_in_one.sql` sin añadir también un patch si ya hay una base de datos creada.
8. Cada ZIP debe mantener `.env` y `.git`.

## Patrón recomendado por funcionalidad

```text
feature/
  screens/
    feature_screen.dart
  feature_repository.dart
  feature_calculator.dart
```

## Antes de pasar de fase

- `flutter analyze`
- crear datos reales
- comprobar usuario A/B si hay permisos
- comprobar Vercel después del push
