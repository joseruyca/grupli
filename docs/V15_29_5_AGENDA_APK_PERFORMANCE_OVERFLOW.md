# Grupli v15.29.5 — Agenda APK performance + overflow fix

Esta versión corrige el problema de la Agenda que en APK DEBUG mostraba texto rojo de overflow y podía sentirse lenta o congelada.

## Cambios

- Semana superior re-hecha para móvil estrecho.
- Eliminado el overflow rojo de Flutter DEBUG en la fila de días.
- Calendario mensual re-hecho sin `GridView` anidado dentro de `ListView`.
- Menos animaciones pesadas en la agenda.
- Índice interno por fecha para no recalcular eventos en cada celda.
- Recargas con debounce para que Realtime no bloquee la pantalla.
- La agenda ya no vuelve a estado de carga completa cuando ya tiene datos.
- Timeout de carga de agenda para evitar esperas largas si Supabase tarda.

## SQL

No requiere SQL nuevo.

Si todavía no se ejecutó la fase anterior, sí hay que ejecutar:

```powershell
Get-Content ".\supabase\patch_v15_29_4_agenda_definitive_fix.sql" | Set-Clipboard
```

## Prueba recomendada

1. Entra en un grupo.
2. Abre Agenda.
3. Cambia de mes varias veces.
4. Pulsa varios días.
5. Crea un evento.
6. Vuelve a Agenda.
7. Comprueba que no aparece texto rojo y que la pantalla responde fluida.
