# Grupli v12 - Rebuild limpio

Esta versión rehace la app desde cero a nivel de interfaz Flutter.

## Principios

- Fondo blanco dentro de la app.
- Grupos siempre privados.
- Home sin wrappers compartidos que puedan dejar el body en blanco.
- Cada pantalla usa `Scaffold` directo o estructura directa estable.
- Dentro de un grupo hay navegación fija inferior:
  - Eventos
  - Calendario
  - Finanzas
  - Torneos
  - Más
- El grupo se crea solo con nombre.
- Días, hora, ubicación y mínimo pertenecen al evento, no al grupo.

## SQL

Para esta versión se recomienda ejecutar `supabase/all_in_one.sql` porque es una base limpia.
