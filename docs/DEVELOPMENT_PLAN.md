# Grupli Development Plan

## Estado actual

Base Flutter + Supabase funcionando, con Auth, grupos, miembros, calendario, finanzas, torneos, perfil y ajustes estructurados.

## Orden correcto

1. Auth + grupos estable.
2. Calendario + asistencia real.
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
