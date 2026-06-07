# Grupli v15.32.1 — Home refresh + navegación al crear/unirse

Objetivo: corregir un problema de raíz en el flujo de creación/unión a grupos.

## Problema detectado

Antes, al crear un grupo y pulsar **Entrar al grupo**, la pantalla del grupo se abría desde la pantalla interna de creación usando `pushAndRemoveUntil`.

Eso dejaba detrás una pantalla de **Mis grupos** con datos antiguos. Al volver atrás desde el grupo, el usuario veía la lista vieja y tenía que refrescar manualmente o moverse de pantalla.

## Solución aplicada

Ahora las pantallas internas no abren directamente el grupo.

En su lugar devuelven un resultado de navegación:

```dart
{
  'action': 'open',
  'groupId': groupId,
}
```

La pantalla **Mis grupos** recibe ese resultado, refresca su lista y después abre el grupo. Al volver atrás, la lista ya está recargada.

## Cambios incluidos

- Crear grupo devuelve resultado a Mis grupos.
- Unirse con código devuelve resultado a Mis grupos.
- Invitaciones desde enlace devuelven resultado al shell principal.
- Mis grupos refresca antes y después de abrir un grupo nuevo.
- El bloque "Crear o unirte a otro grupo" ahora es un botón real.
- Se mantiene `all_in_one.sql` como único SQL global. No se añade parche SQL.
- Versión interna: v15.32.1.

## Prueba recomendada

1. Entrar en navegador.
2. Crear grupo.
3. Pulsar Entrar al grupo.
4. Volver atrás a Mis grupos.
5. El grupo debe aparecer sin refrescar manualmente.

Repetir con:

- Crear grupo → Volver a mis grupos.
- Unirse con código.
- Abrir invitación.
