# Grupli v16.20 — Build Stability Pass

## Objetivo

Cerrar la Fase 0: que la app pueda analizarse y generar builds sin errores reales antes de seguir añadiendo producto.

## Cambios

- Versión interna actualizada a `v16.20`.
- `pubspec.yaml` actualizado a `0.16.20+16200`.
- Añadido `.gitignore` para evitar subir `.env`, `build`, `.dart_tool`, keystores y archivos locales.
- Añadido `scripts/quality_gate_v16_20.ps1`.
- Añadido `scripts/build_web_release.ps1`.
- `build_android_debug_apk.ps1` ahora ejecuta `flutter analyze --no-fatal-infos --no-fatal-warnings` antes de crear APK y bloquea si hay errores reales.
- `build_android_release_apk.ps1` hace el mismo control antes de release.
- Limpieza de avisos no críticos de analyzer para que `flutter analyze` se centre en errores reales.
- Eliminados warnings menores de variables/código no usado detectados en la revisión local.

## Criterio de terminado

Para cerrar esta fase en local debe pasar:

```powershell
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
.\scripts\build_android_debug_apk.ps1
.\scripts\build_web_release.ps1
```

O todo junto:

```powershell
.\scripts\quality_gate_v16_20.ps1
```

## Notas

- Los avisos de `google-services.json` no bloquean APK debug. Solo indican que las push reales no funcionarán hasta configurar Firebase Android.
- No requiere SQL nuevo.
