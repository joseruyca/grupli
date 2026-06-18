# v16.32.5 — Web rescue: arranque estable

Esta fase revierte el arranque web a la estructura estable que ya funcionaba antes de los cambios de guardas/loader.

Cambios:
- `web/index.html` vuelve a ser mínimo y estable.
- `main.dart` vuelve al arranque directo probado: inicializa configuración, Supabase y ejecuta `runApp`.
- Se mantiene el import de Cupertino necesario para las transiciones.
- `vercel.json`, `.gitattributes` y `vercel_build.sh` quedan en LF.
- No se toca SQL.
- No se toca `.env`.
- No se añaden pagos.
- No se añaden librerías.

Motivo:
La web ya compilaba, pero se quedaba en blanco al abrir. En esa situación hay que eliminar cambios de arranque que puedan interferir con Flutter Web y volver a la base probada.
