# Grupli v15.21 — Admin + soporte + calidad

Esta fase añade la base para controlar Grupli como dueño de la app.

## Incluye

- Panel admin privado visible solo para el owner/admin de la app.
- Sistema de reportes/soporte desde Perfil y desde Más dentro de cada grupo.
- Tabla `support_tickets` para que los usuarios reporten bugs, dudas y sugerencias.
- Tabla `app_quality_events` para guardar señales internas útiles sin bloquear al usuario.
- Tabla `app_admins` para controlar quién puede ver el panel admin.
- RPC `admin_overview()` para métricas generales.
- RPC `ensure_owner_admin()` para asignar como owner admin al correo `joseruyca@gmail.com` cuando inicia sesión.

## Flujo de uso

1. Ejecutar `supabase/patch_v15_21_admin_support_quality.sql`.
2. Iniciar sesión con `joseruyca@gmail.com`.
3. Ir a Perfil.
4. Entrar en `Panel admin`.
5. Revisar reportes abiertos, críticos y eventos de calidad.

## Importante

El panel no es público. Si el SQL todavía no está ejecutado, la app no se rompe: simplemente no muestra el panel admin.

La siguiente fase recomendada es `v15.22 — Push notifications reales` con Firebase completo, tokens, edge functions y control de entrega.
