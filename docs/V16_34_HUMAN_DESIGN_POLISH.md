# Grupli v16.34 — Human design polish

Objetivo: elevar la percepción visual de Grupli sin tocar la lógica crítica ni cambiar las dependencias web ya validadas.

Cambios aplicados:

- Tokens visuales más humanos y cálidos en `AppColors`.
- Fondo ambiental sutil fuera del marco móvil, con patrón orgánico ligero.
- Cards con radio asimétrico, sombra mínima y opción de acento lateral.
- Botones principales/secundarios con microinteracción de borde y desplazamiento suave.
- Estados de error más humanos, sin mensajes técnicos y con icono dibujado por `CustomPainter`.
- Estados vacíos más cálidos y legibles.
- Skeletons menos genéricos: estructura suave con líneas de contenido insinuadas.
- Versión actualizada a `0.16.34+16340` / `v16.34`.

Restricciones conservadas:

- `supabase_flutter: 2.8.3`
- `app_links: 6.4.1`
- Vercel con Flutter 3.41.6
- Sin hardcodear secretos
- Sin tocar SQL ni RLS
- Sin modificar flujos sensibles de Supabase Auth
- Sin introducir nuevas dependencias
