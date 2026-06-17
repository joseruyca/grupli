# v16.32.2 — Vercel pinned Flutter fix

Objetivo: hacer que Vercel compile con una versión fija de Flutter en lugar de usar siempre la última `stable` disponible.

Cambios:

- `vercel_build.sh` instala Flutter `3.35.7` por defecto.
- Si Vercel tiene cacheada otra versión de Flutter, la reemplaza.
- Primero intenta descargar el SDK oficial de Flutter para Linux.
- Si la descarga falla, usa el tag de GitHub de Flutter como respaldo.
- Ejecuta `flutter analyze` dentro del build de Vercel para que el error real aparezca en logs.
- Mantiene el fallback del build web sin `--no-wasm-dry-run`.
- No toca SQL.
- No toca pagos reales.
- No añade claves ni secretos.

Motivo: el build local estaba funcionando, pero Vercel podía estar usando una versión `stable` distinta a la local. Al fijar la versión se elimina esa diferencia.
