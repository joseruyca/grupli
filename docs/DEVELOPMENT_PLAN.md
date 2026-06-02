# Grupli Development Plan

## Estado actual

Base Flutter + Supabase funcionando, con Auth, grupos y miembros estructurados. La fase v5 consolida calendario y asistencia: calendario mensual, creación/edición de quedadas, detalle de asistencia, mínimos, estados Voy/Duda/No/Pendiente y cancelación.

## Orden correcto

1. Auth + grupos estable. ✅
2. Calendario + asistencia real. ✅ v5
3. Finanzas tipo Tricount.
4. Torneos completos.
5. Perfil + avatar + storage.
6. Checklist multiusuario + seguridad.
7. Pulido visual final.
8. APK debug.

## Regla de trabajo

Cada ZIP debe:

- Mantener `.env`.
- Mantener `.git`.
- No subir `.env`.
- No borrar `.git`.
- No crear otra carpeta final.
- Usar siempre `C:\Users\Jose\Desktop\grupliv2`.
- Usar siempre `https://github.com/joseruyca/grupli.git`.

## Criterio de calidad antes de pasar de fase

- Compila local.
- Funciona en Chrome.
- Se puede subir a GitHub.
- Vercel despliega automático.
- La UI se entiende a simple vista.
- Los errores se muestran con mensajes humanos.

## v6 completado

Finanzas queda estructurado para uso real: gastos, participantes, reparto igual/manual, balances netos, pagos registrados y acciones de estado.

## Siguiente fase recomendada

v7 — Torneos funcionales: equipos, generación de partidos, resultados y clasificación real.


## v8 — Perfil, avatar y ajustes reales

Añade perfil real con estadísticas básicas, avatar en Supabase Storage, ajustes persistentes por usuario, pantallas legales/base de ayuda y SQL `patch_v8_profile_settings.sql`.
