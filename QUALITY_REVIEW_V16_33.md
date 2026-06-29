# Grupli v16.33 Quality Review

Cambios aplicados:
- Vercel fijado a Flutter 3.41.6 y build reproducible.
- Compatibilidad web mantenida: supabase_flutter 2.8.3 + app_links 6.4.1.
- Preparado para usar pubspec.lock si está commiteado.
- Arranque más resistente: si Supabase no inicializa, la app muestra pantalla controlada en vez de quedar en blanco.
- Primer arranque más resistente: si falla la recuperación de sesión/preferencias, la app sigue mostrando entrada/onboarding.
- Compatibilidad futura Flutter: import explícito de Cupertino y PageTransitionsTheme no const.
- Web index actualizado con mobile-web-app-capable.
- Añadido .gitattributes para evitar cambios de finales de línea.
- Añadido quality gate local scripts/quality_gate_v16_33.ps1.

No se ha tocado:
- Lógica de torneos.
- SQL de Supabase.
- Claves o secretos.
- Firebase funcional.
