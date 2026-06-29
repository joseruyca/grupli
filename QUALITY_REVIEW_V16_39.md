# Grupli v16.39.0 — Loading cleanup + agenda compile fix

Objetivo: corregir el loader inicial que se veía artificial y asegurar que la build web no falla por null-safety en Agenda.

Cambios:
- CenterLoader vuelve a un indicador CircularProgressIndicator estándar, centrado y claro.
- Pantalla inicial cambia a texto simple: "Cargando...".
- Eliminado el icono de carga dibujado que generaba una sensación rara en la pantalla inicial.
- Corregida comprobación nullable en Agenda: asistencia propia puede ser null.
- Mantiene supabase_flutter 2.8.3 y app_links 6.4.1.
- Mantiene Vercel en Flutter 3.41.6 con dependencias bloqueables.

No se toca:
- SQL/RLS.
- Supabase Auth.
- Firebase.
- Modelo de datos.
- Dependencias críticas.
