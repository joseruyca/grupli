# V15.7.1 — Vercel build fix

Corrección de despliegue:

- Se restaura `vercel_build.sh`, necesario porque `vercel.json` llama a:
  - `bash vercel_build.sh install`
  - `bash vercel_build.sh build`
- El script usa `flutter analyze --no-fatal-infos --no-fatal-warnings`, así los avisos de lint no bloquean Vercel.
- Mantiene los `--dart-define` para:
  - Supabase
  - APP_BASE_URL
  - Firebase/FCM opcional

No cambia la interfaz ni requiere SQL nuevo.
