# v16.22.6 - Event contributions UX polish

Mejora de la función **Qué llevamos** dentro del detalle del evento.

## Cambios

- Tarjeta más simple y fácil de entender.
- Se eliminan los botones duplicados **Editar** y **Quitar** dentro de cada aportación.
- Solo queda una acción principal grande: **Añadir lo que llevo** o **Editar lo que llevo**.
- El modal usa el título natural **¿Qué vas a llevar?**.
- El campo usa **Yo llevo...**.
- Las ideas rápidas se adaptan al tipo de evento:
  - deporte/torneo/entrenamiento: pelotas, agua, petos, bomba, botiquín...
  - cena: bebida, postre, pan, tortilla, hielo...
  - fiesta/karaoke/cumpleaños: bebida, hielo, vasos, altavoz, micrófono...
  - reunión: documentos, ordenador, cargador...
- **Quitar lo que llevo** pasa al modal de edición y conserva la confirmación posterior.

## Seguridad

No se añaden claves, tokens ni credenciales.
No se añaden librerías.
No requiere SQL nuevo.
Se mantiene la tabla `event_contributions` con RLS creada en v16.22.
