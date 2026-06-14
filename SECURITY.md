# Grupli Security Baseline

## Principios obligatorios

- No hardcodear secretos, service role keys, private keys, tokens ni credenciales en Flutter/web.
- `SUPABASE_URL` y `SUPABASE_ANON_KEY`/publishable key llegan por entorno, nunca como fallback en código.
- `SUPABASE_SERVICE_ROLE_KEY`, Firebase private key, APNs keys y credenciales externas solo viven en backend/Edge Functions/secrets.
- El frontend solo puede operar sobre tablas con Row Level Security activa.
- Las operaciones sensibles deben pasar por backend/Edge Functions y validación server-side.

## Antes de cada build

```powershell
.\scripts\security_audit_v16_21.ps1
.\scripts\quality_gate_v16_21.ps1
```

## Archivos que no deben subirse

- `.env`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `*.jks`
- `*.keystore`
- `key.properties`
- `*.p8`
- `*.pem`
