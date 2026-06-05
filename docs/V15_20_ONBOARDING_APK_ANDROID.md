# Grupli v15.20 — Onboarding + APK Android real

## Qué incluye

- Onboarding inicial de 3 pantallas para nuevos usuarios.
- Botón para volver a ver la introducción desde la pantalla de bienvenida.
- La intro se guarda en `shared_preferences` y no vuelve a salir después de pulsar Empezar/Saltar.
- Si el usuario abre un enlace de invitación, se salta la intro para entrar directo al flujo de registro/login.
- Scripts para crear la carpeta Android y generar APK instalable.
- Package Android por defecto: `com.joseruyca.grupli`.

## Qué NO incluye todavía

- Firma final para Play Store.
- Icono final nativo de Android.
- Push notifications reales enviadas desde servidor.
- Panel admin/soporte.

Eso queda para las siguientes fases:

- v15.21 — Admin + soporte + calidad.
- v15.22 — Push notifications reales.

## Crear APK debug

Desde PowerShell:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
.\scripts\build_android_debug_apk.ps1
```

APK generada:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Instalar APK debug por USB

Con el móvil conectado, depuración USB activada:

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
.\scripts\install_android_debug_apk.ps1
```

## Crear APK release de prueba

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
.\scripts\build_android_release_apk.ps1
```

APK generada:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## Notas importantes

- Si no existe la carpeta `android/`, el script la crea con `flutter create --platforms=android`.
- El script lee `.env` y pasa las variables necesarias con `--dart-define`.
- `.env` y `.git` no deben subirse a GitHub.
- Para push reales más adelante hará falta Firebase y `google-services.json`.
- Para Play Store hará falta firma definitiva, icono, capturas, política de privacidad y pruebas.
