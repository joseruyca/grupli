# v16.32.4 - Web startup guard

Esta fase corrige el caso en el que Vercel despliega correctamente pero la web queda en blanco.

Cambios:
- `main.dart` queda protegido con `runZonedGuarded`.
- Si Supabase/Firebase/configuración falla al arrancar, la app muestra una pantalla visible en vez de quedar en blanco.
- `web/index.html` incluye un cargador visible y captura errores de bootstrap/JavaScript.
- `vercel_build.sh`, `vercel.json` y `.gitattributes` quedan con saltos LF reales.

No añade SQL, no cambia pagos y no toca claves.
