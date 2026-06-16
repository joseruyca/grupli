# v16.25.1 — Encoding seguro y navegacion mas fluida

Cambios:

- Corrige el script `scripts/check_no_mojibake.ps1` para que sea ASCII-only y no pueda romperse por codificacion.
- Mantiene la base limpia en UTF-8 para evitar textos rotos en la app.
- La navegacion inferior del grupo usa `LazyIndexedStack`: las pestanas ya visitadas no se destruyen al cambiar de seccion.
- Evita recargas innecesarias al tocar de nuevo la pestana activa.
- Mantiene feedback haptico suave al cambiar de pestana.
- Mantiene la pantalla de inicio del grupo ultra limpia, sin accesos rapidos repetidos ni boton flotante que tape contenido.

No requiere SQL nuevo.
No anade librerias.
No incluye credenciales ni claves.
