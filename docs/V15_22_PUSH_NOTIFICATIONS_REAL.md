# v15.22 — Push notifications reales

Esta fase deja Grupli preparada para recibir notificaciones push reales en APK Android usando Firebase Cloud Messaging + Supabase.

## Qué incluye

- Registro del token FCM del móvil en `user_devices`.
- Permiso de notificaciones en Android 13+.
- Handler de push en segundo plano.
- Listener para abrir la app desde una notificación.
- Botón para activar push en el dispositivo.
- Botón para enviar un aviso de prueba desde Ajustes de notificaciones.
- Edge Function `supabase/functions/send-push`.
- SQL `patch_v15_22_push_notifications_real.sql`.
- Script `scripts/configure_firebase_android.ps1`.
- Guía para crear el vídeo de intro/demo.

## Qué necesitas tú

No puedo incluir estos archivos porque son privados de tu Firebase/Supabase:

- `android/app/google-services.json`.
- `SUPABASE_SERVICE_ROLE_KEY`.
- `FIREBASE_CLIENT_EMAIL`.
- `FIREBASE_PRIVATE_KEY`.

Sin eso la APK compila, pero no recibe push reales.

## Flujo real

1. El usuario instala la APK.
2. Inicia sesión.
3. Entra en Avisos o Ajustes de notificaciones.
4. Pulsa `Activar push en este dispositivo`.
5. Android pide permiso.
6. Firebase genera token.
7. Grupli guarda el token en Supabase.
8. Supabase crea una fila en `notifications`.
9. Database Webhook llama a `send-push`.
10. Firebase entrega la notificación al móvil.

## Pasos Firebase Android

1. Firebase Console → Create project.
2. Añadir app Android.
3. Package name exacto:

```text
com.joseruyca.grupli
```

4. Descargar `google-services.json`.
5. Ponerlo aquí:

```text
android/app/google-services.json
```

6. Ejecutar:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
.\scripts\configure_firebase_android.ps1
```

Ese script actualiza Android y rellena las variables Firebase en `.env`.

## SQL

Ejecutar:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Get-Content ".\supabase\patch_v15_22_push_notifications_real.sql" | Set-Clipboard
```

Pegar en Supabase SQL Editor y Run.

## Edge Function

Necesitas Supabase CLI enlazado al proyecto.

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
supabase functions deploy send-push --no-verify-jwt
```

Configura secretos:

```powershell
supabase secrets set SUPABASE_URL="https://TU-PROYECTO.supabase.co"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="TU_SERVICE_ROLE_KEY"
supabase secrets set FIREBASE_PROJECT_ID="TU_FIREBASE_PROJECT_ID"
supabase secrets set FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxx@tu-proyecto.iam.gserviceaccount.com"
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## Webhook en Supabase

Supabase Dashboard → Database → Webhooks → Create webhook.

- Table: `notifications`.
- Event: `Insert`.
- Type: Supabase Edge Function.
- Function: `send-push`.
- Method: POST.
- Añadir auth header con service key.

## Prueba

1. Instala APK.
2. Inicia sesión.
3. Perfil/Más → Notificaciones.
4. Pulsa `Activar push en este dispositivo`.
5. Pulsa `Enviar aviso de prueba`.
6. Bloquea el móvil o manda la app a segundo plano.
7. Si Firebase + Edge Function + Webhook están bien configurados, llegará la notificación.

