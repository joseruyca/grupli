# Grupli v15.32.2 — Fix torneo setState Future

Esta versión corrige un fallo de Flutter en Torneos al crear/abrir una competición.

## Problema

Flutter mostraba:

```text
setState() callback argument returned a Future
```

La causa era que algunas llamadas a `setState` devolvían indirectamente un `Future`, por ejemplo:

```dart
setState(() => future = AppData.tournament(widget.tournamentId));
```

Aunque compila, Flutter lo detecta en runtime y rompe la pantalla.

## Corrección

Se han convertido esas llamadas en bloques síncronos:

```dart
setState(() {
  future = AppData.tournament(widget.tournamentId);
});
```

También se ha cambiado el arranque de `TournamentDetailScreen` para inicializar el `future` directamente en `initState`, sin llamar a `setState` durante el inicio.

## Revisado

Se han revisado las llamadas de `setState` que asignaban `Future` en:

- Mis grupos.
- Miembros.
- Torneo detalle.
- Ajustes/miembros del grupo.
- Reportes del perfil.

## SQL

No requiere SQL nuevo.

Se mantiene la regla de v15.32:

- único reset global: `supabase/all_in_one.sql`
- comprobaciones: `supabase/security_checks.sql`
- sin `patch_*.sql`
