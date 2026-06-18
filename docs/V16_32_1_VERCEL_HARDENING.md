# v16.32.1 - Vercel hardening

Cambios de seguridad y build:

- `.env` queda ignorado por Git.
- Se elimina la variable local `radius` sin uso que bloqueaba `flutter analyze` cuando los scripts tratan warnings como error.
- `vercel_build.sh` ahora intenta compilar con `--no-wasm-dry-run` y, si Vercel/Flutter no acepta esa opción o falla por compatibilidad del flag, reintenta sin ese flag.
- No se añaden pagos reales.
- No se añade SQL.
- No se añaden librerías.
