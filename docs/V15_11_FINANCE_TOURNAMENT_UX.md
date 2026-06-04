# v15.11 — Finanzas visuales + torneos con puntuación configurable

Cambios incluidos:

- Mis grupos: eliminada la fila superior de métricas `grupos / miembros / eventos` para dejar la landing más limpia.
- Inicio del grupo: la tarjeta de próximo plan tiene fondo más marcado y los botones `Voy / Duda / No` usan relleno de color cuando están seleccionados.
- Finanzas: pantalla rehecha para leer de un vistazo:
  - resumen personal: `debes`, `te deben` o `estás a cero`;
  - tabla directa de `quién paga a quién`;
  - balance por persona;
  - gastos recientes debajo, sin métricas técnicas tipo compensado/restado.
- Torneos / Ligas: al crear competición se elige sistema de puntuación:
  - General
  - Fútbol
  - Tenis / Pádel
  - Baloncesto
  - Mus / Cartas
  - Personalizado
- Se guarda `scoring_type` y `scoring_config` en Supabase cuando el patch SQL está aplicado. Si aún no está aplicado, la app crea el torneo con fallback para no bloquear la demo.

SQL recomendado:

`supabase/patch_v15_11_finance_tournament_ux.sql`
