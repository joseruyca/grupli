# Grupli web recovery baseline

Baseline estable v16.33:
- Flutter validado localmente: 3.41.6
- supabase_flutter: 2.8.3
- app_links: 6.4.1
- Vercel debe usar `vercel_build.sh`
- Generar y commitear `pubspec.lock` antes de desplegar

Reglas:
- No actualizar `supabase_flutter` y `app_links` por separado.
- No borrar `pubspec.lock` después de generarlo.
- No hacer `git push --force`.
- No subir `.env`.
