# Grupli v16.0 — Refactor técnico y SQL limpio

Esta fase debe hacerse separada de v15.29. No conviene mezclar un refactor grande con cambios de admin/soporte.

## Objetivo

Reducir el riesgo técnico antes de beta:

- separar `main.dart` por módulos;
- consolidar SQL;
- dejar scripts limpios;
- revisar RLS;
- preparar la app para mantenimiento real.

## Estructura recomendada

```text
lib/
  core/
    config/
    theme/
    utils/
    widgets/
  data/
    app_data.dart
    realtime_service.dart
    push_service.dart
  features/
    auth/
    groups/
    calendar/
    finances/
    tournaments/
    members/
    profile/
    admin/
    support/
```

## SQL limpio

Crear un `supabase/all_in_one_v16.sql` consolidado que incluya:

- perfiles;
- grupos;
- miembros;
- eventos;
- asistencia;
- finanzas;
- liquidaciones;
- torneos;
- notificaciones;
- soporte;
- admin roles;
- realtime;
- storage;
- RLS.

## Regla

No hacer refactor funcional agresivo sin probar antes cada módulo.
