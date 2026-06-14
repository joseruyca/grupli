# Grupli v16.22.1 — Fix auditoría de seguridad y entrega limpia

Esta versión corrige dos problemas detectados al pasar `quality_gate_v16_22.ps1`:

1. Falso positivo en `supabase/functions/send-push/index.ts`: la Edge Function no contenía una clave privada real hardcodeada; solo contenía las marcas PEM necesarias para limpiar la clave recibida desde `Deno.env.get('FIREBASE_PRIVATE_KEY')`. El audit ahora solo falla si detecta un bloque PEM real con cuerpo largo dentro del archivo.
2. Error PowerShell con `Set-StrictMode`: la comprobación del texto `Falta $required` usaba comillas dobles y PowerShell intentaba resolver `$required` como variable del propio script. Se ha cambiado a comillas simples.

No se han añadido librerías nuevas. No se han introducido secretos en frontend.

## Seguridad

- `SUPABASE_SERVICE_ROLE_KEY` sigue solo en Edge Function mediante variable de entorno.
- `FIREBASE_PRIVATE_KEY` sigue solo en Edge Function mediante variable de entorno.
- Flutter no contiene claves privadas ni service role.
- La tabla `event_contributions` mantiene RLS.

## Versión

- `pubspec.yaml`: `0.16.22+16221`
- `AppData.appVersion`: `v16.22.1`
