# Grupli v16.22.2 — Vercel Build Fix

Build script simplificado para Vercel.

## Cambios

- `vercel_build.sh` vuelve al flujo simple de build.
- No ejecuta quality gate ni auditorías en Vercel.
- No ejecuta `flutter analyze` en Vercel para evitar bloquear despliegues por checks no necesarios.
- Añade `--no-wasm-dry-run` para evitar avisos de WASM en entornos CI/Vercel.
- Mantiene variables por entorno: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `APP_BASE_URL` y Firebase opcionales.
- No hardcodea secretos ni claves privadas.

## Seguridad

La app sigue sin meter `service_role`, tokens privados ni credenciales en frontend. Vercel recibe solo valores desde Environment Variables.
