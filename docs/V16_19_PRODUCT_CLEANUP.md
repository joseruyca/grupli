# Grupli v16.19 — Limpieza de producto y errores visibles

## Objetivo

Dejar la app más preparada para enseñarla a usuarios reales, quitando textos técnicos y acciones de prueba que hacían que pareciera una beta interna.

## Cambios

### Errores visibles

- Eliminada la pantalla roja técnica con `details.exceptionAsString()`.
- Ahora, si Flutter necesita mostrar un error visual, aparece una pantalla humana:
  - “Algo no ha ido bien”
  - explicación sencilla
  - sin trazas técnicas

### Login y recuperación de contraseña

- `¿Olvidaste tu contraseña?` ya no muestra un mensaje técnico.
- Ahora envía un enlace de recuperación usando el email introducido.
- Los errores de login y OAuth pasan por `humanError()`.

### Textos técnicos

Se han limpiado textos visibles que mencionaban tecnologías internas:

- Supabase
- Firebase
- SQL
- APK
- webhook
- google-services
- PWA
- versiones antiguas v15

Los textos internos de código/imports se mantienen porque forman parte de la implementación, pero no se muestran al usuario.

### Moneda

- Se oculta el selector de moneda para evitar prometer algo que aún no está conectado a toda Finanzas.
- La app indica que por ahora el grupo usa euros.
- La moneda real por grupo se hará más adelante, cuando se aplique a balances, liquidaciones e histórico.

### Perfil y ajustes

- Acerca de Grupli muestra `AppConfig.appVersion`.
- Se actualiza la versión a `v16.19`.
- Se limpian textos de privacidad, soporte y notificaciones.
- Se quita el botón de aviso de prueba del perfil de usuario.

### Notificaciones

- La sección de notificaciones deja de hablar de configuración técnica.
- Los errores son humanos:
  - “No se pudieron activar las notificaciones en este dispositivo.”
  - “No se pudieron cargar los avisos. Inténtalo de nuevo.”

### Web / iconos / assetlinks

- `web/manifest.json` incluye iconos 192/512/maskable.
- Se añaden iconos básicos en `web/icons/`.
- `assetlinks.json` queda como `[]` para no publicar un SHA placeholder falso.
- El ejemplo con placeholder queda en `assetlinks.example.json`.

## Pendiente para tienda

Antes de Play Store/App Store todavía falta:

- icono final diseñado;
- splash screen final;
- firma Android release;
- SHA256 real en `assetlinks.json`;
- configuración iOS;
- política de privacidad final;
- borrado de cuenta probado;
- build release real;
- QA en móviles pequeños y grandes.

## SQL

No requiere SQL nuevo.
