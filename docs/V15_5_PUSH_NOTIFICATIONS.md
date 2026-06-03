# V15.5 — Notificaciones push

Esta fase añade la base real de notificaciones para Grupli.

## Incluido

- Pantalla de Avisos con notificaciones reales desde Supabase.
- Marcar notificación como leída.
- Marcar todas como leídas.
- Al tocar un aviso, abre el grupo correspondiente.
- Preferencias por usuario:
  - eventos
  - finanzas
  - torneos
  - miembros
  - push habilitado
- Tabla `notifications`.
- Tabla `user_devices` para tokens FCM.
- Triggers que crean avisos cuando ocurre algo en un grupo:
  - nueva quedada
  - quedada actualizada/cancelada
  - nuevo gasto
  - nuevo torneo
  - resultado registrado
  - nuevo miembro
- Integración preparada con Firebase Cloud Messaging.

## Importante

Los avisos internos funcionan con Supabase tras ejecutar el SQL.

Para push real al móvil fuera de la app hay que configurar Firebase:

- crear proyecto Firebase
- registrar Android/iOS
- añadir claves como dart-defines/env vars
- para iOS, configurar APNs en Firebase
- generar APK/AAB/IPA con esas claves

## Variables opcionales

```text
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_VAPID_KEY=
```

## SQL

Ejecutar:

```text
supabase/patch_v15_5_push_notifications.sql
```
