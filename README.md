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

## v12.2 — Corrección de producto

Se elimina la pestaña Eventos como navegación principal. Dentro de cada grupo, la primera pestaña ahora es Inicio: resumen real del grupo con próximos eventos y asistencia directa. Calendario es donde se visualizan y crean eventos por día. Se han eliminado los ejemplos falsos de actividad reciente.


## v12.3 — Torneos y ligas

Rehace el flujo de torneos/ligas: creación guiada, formatos liga/eliminatoria/americano, participantes, generación automática de partidos, resultados, clasificación y rondas.

## v12.4 — Finanzas estilo Tricount

Mejora completa de Finanzas: balances por miembro, quién debe a quién, formulario de gasto guiado, detalle de gasto, liquidación y reapertura de pagos. No requiere SQL nuevo si ya está ejecutado el `all_in_one.sql` de v12.


## v12.5 Calendario + eventos unidos

Mejora el flujo de eventos/quedadas: Inicio muestra próximos eventos con asistencia directa; Calendario permite crear eventos desde el día seleccionado, responder asistencia, abrir detalle, editar y cancelar. No añade SQL nuevo.


## v12.6

- Quitada frase inferior dentro del grupo.
- Back dentro de pestañas vuelve a Inicio del grupo.
- Pestañas de grupo sin flecha superior.
- Torneos mejorados: importar miembros, regenerar partidos, eliminatorias limpias.
