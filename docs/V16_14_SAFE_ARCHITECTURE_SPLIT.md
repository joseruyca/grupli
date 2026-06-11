# Grupli v16.14 — Safe architecture split

## Objetivo

Reducir el riesgo técnico de tener toda la app dentro de `lib/main.dart`.

Antes:
- `lib/main.dart` tenía más de 20.000 líneas.
- Cualquier cambio en Agenda, Finanzas o Torneos tocaba el mismo archivo gigante.
- Era más fácil romper otra pantalla sin querer.

Ahora:
- `lib/main.dart` queda como entrada principal de la app.
- Las pantallas grandes se separan por módulos.
- Se usa `part` / `part of` para que el cambio sea seguro y no obligue a reescribir imports, dependencias ni referencias internas de golpe.

## Estructura nueva

```txt
lib/
  main.dart

  core/
    app_data/
      app_data.dart
    theme/
      app_colors.dart
    widgets/
      shared_widgets.dart

  features/
    onboarding/
      onboarding.dart
    auth/
      auth.dart
    groups/
      groups.dart
    agenda/
      agenda.dart
    finances/
      finances.dart
    tournaments/
      tournaments.dart
    profile/
      profile_members_admin.dart
```

## Qué se ha movido

- AppColors → `core/theme/app_colors.dart`
- AppData → `core/app_data/app_data.dart`
- Onboarding / intro animada → `features/onboarding/onboarding.dart`
- Welcome / auth / shell inicial → `features/auth/auth.dart`
- Crear/unir grupos, dashboard de grupo y más → `features/groups/groups.dart`
- Eventos, calendario y agenda → `features/agenda/agenda.dart`
- Finanzas → `features/finances/finances.dart`
- Torneos → `features/tournaments/tournaments.dart`
- Miembros, perfil, ajustes, soporte y admin → `features/profile/profile_members_admin.dart`
- Widgets compartidos → `core/widgets/shared_widgets.dart`

## Por qué se usa `part`

Es una transición segura.

Con `part`, todos los archivos siguen perteneciendo a la misma librería de Dart. Eso permite que:
- no haya que rehacer cientos de imports ahora;
- no se rompan referencias privadas existentes;
- el comportamiento de la app se mantenga igual;
- podamos modularizar de verdad por fases.

## Siguiente paso recomendado

Cuando la app base esté más estable:

1. Crear modelos y servicios separados.
2. Sacar Supabase/AppData por dominios:
   - groups_data.dart
   - agenda_data.dart
   - finance_data.dart
   - tournament_data.dart
3. Convertir poco a poco `part` en imports reales.
4. Añadir tests de algoritmos de Finanzas y Torneos.

## SQL

No requiere SQL nuevo.
