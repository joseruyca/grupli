# v16.22.3 — Vercel env aliases

Fix del script de Vercel. No cambia claves ni credenciales.

- Vercel sigue recibiendo variables por entorno.
- No se hardcodea Supabase en frontend.
- Se aceptan nombres alternativos comunes para evitar errores de deploy:
  - SUPABASE_URL, VITE_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_URL, FLUTTER_SUPABASE_URL
  - SUPABASE_ANON_KEY, VITE_SUPABASE_ANON_KEY, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_KEY
- Si falta configuración, el log muestra solo nombres de variables y nunca valores.
