# v15.27 — Invitaciones reales móvil/web

Objetivo: que un enlace de invitación funcione bien tanto en navegador como en APK Android instalada.

## Qué incluye

- Lectura de enlaces en web: `https://grupli.vercel.app/join/CODIGO`.
- Lectura de enlaces en APK Android con `app_links`.
- Soporte de Android App Links para `https://grupli.vercel.app/join/...`.
- Soporte de esquema propio `grupli://join/CODIGO` como respaldo técnico.
- Si el usuario no ha iniciado sesión, se guarda la invitación y se le lleva al login/registro.
- Si el usuario ya tiene sesión, se une al grupo y se abre el grupo directamente.
- Evita duplicar la misma invitación si el sistema dispara el enlace dos veces.
- Script para preparar `AndroidManifest.xml` con intent filters.
- Archivo `.well-known/assetlinks.json` para verificación Android.

## Importante sobre Android App Links

Para que Android abra directamente la APK al tocar un enlace `https://grupli.vercel.app/join/CODIGO`, el dominio debe publicar:

```text
https://grupli.vercel.app/.well-known/assetlinks.json
```

Ese archivo debe contener el SHA256 real de la firma Android.

En esta versión se deja un placeholder que debes reemplazar.

## Sacar SHA256 Android

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\print_android_sha256.ps1
```

Copia el SHA256 y reemplaza:

```text
REEMPLAZA_ESTE_VALOR_CON_EL_SHA256_DE_LA_FIRMA_ANDROID
```

en:

```text
web/.well-known/assetlinks.json
```

Después:

```powershell
git add -A
git commit -m "Configure Android asset links fingerprint"
git push -u origin main
```

## Pruebas recomendadas

1. Crear grupo.
2. Copiar enlace de invitación.
3. Abrir enlace en navegador sin sesión.
4. Registrarse o iniciar sesión.
5. Confirmar que entra al grupo.
6. Instalar APK.
7. Enviar enlace por WhatsApp.
8. Tocar enlace desde el móvil.
9. Confirmar que abre la app y entra al grupo.
10. Regenerar código y probar que el enlace anterior ya no sirve.

## Nota de producción

El SHA256 debug sirve para APK de prueba. Para Play Store/release necesitarás el SHA256 de la firma release o del certificado de App Signing de Google Play.
