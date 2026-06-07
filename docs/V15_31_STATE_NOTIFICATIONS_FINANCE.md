# Grupli v15.31 — Estado, notificaciones, agenda y finanzas

Esta fase corrige varios problemas estructurales que se notaban sobre todo en APK real.

## Cambios

### Estado / refresco

- Se refuerza el refresco por Realtime para cambios de perfil/avatar.
- El cambio de foto debe reflejarse mejor en otras pantallas y en otros móviles.
- Se reduce el problema de pantallas antiguas apiladas al entrar desde notificaciones.

### Notificaciones

- Las notificaciones ya no abren siempre el inicio del grupo.
- Según el tipo de aviso, abren el grupo en:
  - Agenda
  - Finanzas
  - Torneos
  - Más / miembros
- El push en background limpia mejor la pila para no volver a una pantalla antigua.

### Agenda

- La vista Semana ahora empieza siempre en el día actual.
- Muestra los próximos 7 días hacia delante.
- Se corrigen overflows que en APK DEBUG aparecían como texto rojo.

### Finanzas

- Se simplifica a 2 pestañas:
  - Movimientos
  - Saldos
- Movimientos muestra gastos y pagos registrados.
- Saldos muestra balance neto y pagos recomendados.
- Al tocar un saldo se abre el detalle de quién debe, quién cobra y los movimientos relacionados.

## Pendiente

Torneos requiere una fase separada completa. No conviene mezclarlo con esta reparación porque hay que rehacer modelo, flujo y pantallas.
