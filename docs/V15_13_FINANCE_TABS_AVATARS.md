# v15.13 — Finanzas por pestañas + fotos de perfil globales

Cambios principales:

- Finanzas deja de ser una pantalla vertical larga.
- Nueva navegación interna:
  - Gastos
  - Saldos
  - Liquidar
- La pestaña Gastos muestra la lista clara de gastos y total.
- La pestaña Saldos muestra balance por persona.
- La pestaña Liquidar muestra únicamente los pagos mínimos recomendados.
- Si un usuario tiene `avatar_url` en su perfil, se muestra su foto en:
  - Finanzas
  - Pagos recomendados
  - Balances
  - Detalle de gastos
  - Crear gasto
  - Asistencia a eventos
  - Miembros
- Si no hay foto, se mantiene fallback con iniciales.
- No requiere SQL nuevo si ya se ejecutaron los parches de avatar anteriores.
