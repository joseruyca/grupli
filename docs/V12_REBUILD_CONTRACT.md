# Grupli v12 - Contrato de reconstrucción

## Objetivo

Construir Grupli como una app móvil premium para Play Store y App Store, no como una web improvisada.

## Pantallas base

1. Splash / bienvenida: tarjeta hero teal, logo, claim y acciones.
2. Login / registro: formulario limpio con Google, Apple, email y contraseña.
3. Home / Mis grupos: lista de grupos privados, stats y acciones crear/unirse.
4. Crear grupo: simple, solo nombre. El grupo siempre es privado.
5. Detalle / Más del grupo: cabecera visual, acciones de invitación, miembros, ajustes y actividad.
6. Eventos: próximos eventos, confirmaciones, crear evento.
7. Calendario: vista mensual y agenda diaria.
8. Finanzas: resumen con reparto sencillo, gastos recientes y añadir gasto.
9. Torneos: lista de ligas/torneos y crear torneo.
10. Perfil: escueto, foto/nombre/ajustes/cerrar sesión.

## Reglas técnicas

- No usar `AppScreen` global para Home ni pantallas de grupo.
- No meter días/hora/ubicación en creación de grupo.
- No hacer grupo público.
- No avanzar a nueva pantalla si la actual queda en blanco o sin body.
- SQL y Flutter son dos capas separadas: el ZIP no modifica Supabase por sí mismo.
