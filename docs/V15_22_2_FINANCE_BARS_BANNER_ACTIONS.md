# Grupli v15.22.2 — Finanzas visuales + acciones reales del banner

## Finanzas

Se rediseña la pestaña **Saldos** para que sea mucho más rápida de entender:

- Barras horizontales por miembro.
- Verde = a esa persona le deben dinero.
- Rojo = esa persona debe dinero.
- Debajo aparece **Quién debe a quién** con los pagos mínimos recomendados.
- Cada liquidación puede marcarse como pagada.
- Se mantiene la pestaña de gastos y el detalle editable de gastos.
- Se mantiene la pestaña Liquidar para una vista centrada solo en pagos pendientes e historial.

## Banner del grupo

Se corrigen los botones del banner principal del grupo:

- Se elimina el chip “Privado” del banner.
- El botón editar abre los ajustes reales del grupo.
- El botón de tres puntos abre acciones rápidas:
  - editar grupo;
  - miembros;
  - copiar enlace;
  - compartir invitación;
  - ver todo;
  - reportar problema.

## Ajustes del grupo

Se añade edición del nombre del grupo desde ajustes, además de la portada existente.

## SQL

No requiere SQL nuevo. Usa la tabla `groups` ya existente y las políticas RLS actuales para actualizar nombre/portada del grupo.
