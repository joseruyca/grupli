# Grupli v15.30 — Rediseño premium de Agenda

Esta fase rediseña la pantalla Agenda para que tenga la misma estética que el resto de Grupli y vaya fluida en APK.

## Cambios principales

- Rediseño visual completo de Agenda.
- Nueva tarjeta hero de próximo plan.
- Selector de vista `Semana / Mes`.
- Vista semanal limpia, grande y táctil.
- Vista mensual rediseñada sin GridView anidado pesado.
- Cards del día más claras.
- Empty state premium con CTA integrado.
- Se elimina el botón flotante como acción principal para evitar sensación de parche.
- CTA integrado en hero, día seleccionado y estado vacío.
- Se mantiene carga defensiva y refresco con debounce de v15.29.5.

## Objetivo UX

La pantalla sigue esta narrativa:

1. Qué viene ahora.
2. Qué vista quiero usar: Semana o Mes.
3. Qué día estoy viendo.
4. Qué planes hay ese día.
5. Crear plan sin perder contexto.

## SQL

No requiere SQL nuevo.
