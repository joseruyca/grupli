# Grupli v16.21 — Security Baseline Audit

## Objetivo

Cerrar una línea base de seguridad antes de seguir añadiendo funciones.

Esta versión se centra en:

- eliminar claves/API keys hardcodeadas del frontend;
- obligar a que Supabase URL y publishable/anon key lleguen por entorno;
- reforzar `.gitignore`;
- añadir auditoría automática de secretos;
- añadir auditoría SQL de RLS/policies;
- mantener las operaciones sensibles fuera del frontend.

## Cambios aplicados

### 1. Sin fallback de Supabase en Flutter

Se han eliminado del frontend:

- URL real de Supabase hardcodeada;
- JWT/anon key hardcodeada.

Ahora `SUPABASE_URL` y `SUPABASE_ANON_KEY` deben llegar por:

- `.env` local + scripts de build;
- variables de entorno de Vercel.

Si faltan, la app muestra una pantalla segura de configuración pendiente y los scripts de build fallan antes de crear APK/web.

### 2. Scripts de build más estrictos

Estos scripts fallan si faltan `SUPABASE_URL` o `SUPABASE_ANON_KEY`:

- `scripts/build_android_debug_apk.ps1`
- `scripts/build_android_release_apk.ps1`
- `scripts/build_web_release.ps1`
- `vercel_build.sh`

### 3. Auditoría automática

Nuevo script:

```powershell
scripts/security_audit_v16_21.ps1
```

Comprueba:

- `.env` ignorado por Git;
- `google-services.json` ignorado;
- keystores ignorados;
- `.env` no trackeado;
- ausencia de JWT hardcodeados en frontend;
- ausencia de URL real de Supabase hardcodeada en frontend;
- ausencia de `service_role` en frontend;
- ausencia de claves privadas en frontend;
- presencia básica de RLS/policies en SQL.

### 4. Quality gate

Nuevo alias:

```powershell
scripts/quality_gate_v16_21.ps1
```

Y el quality gate existente ejecuta primero:

```powershell
scripts/security_audit_v16_21.ps1
```

### 5. Auditoría SQL manual

Nuevo archivo:

```text
supabase/security_baseline_audit_v16_21.sql
```

Sirve para revisar en Supabase:

- tablas públicas sin RLS;
- tablas sin policies;
- policies demasiado permisivas;
- buckets públicos;
- funciones security definer.

## Implicaciones de seguridad

- La `anon/publishable key` de Supabase no es un secreto de backend, pero no debe estar hardcodeada en el código.
- El frontend solo puede usar claves públicas y siempre protegido por RLS.
- `service_role`, Firebase private key, APNs keys y cualquier secreto real solo pueden vivir en backend/Edge Functions/secrets.
- Cualquier operación sensible debe pasar por Edge Function y validación server-side.

## Pendiente para fases siguientes

- Revisar RLS tabla por tabla con datos reales.
- Revisar Storage buckets y policies.
- Añadir tests de permisos owner/admin/member.
- Mover borrar cuenta, transferir owner y push reales a Edge Functions.
- Revisar que no haya `.env` trackeado en GitHub.
