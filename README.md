# Grupli v12 - Rebuild limpio

Esta versión rehace la app desde cero a nivel de interfaz Flutter.

## Principios

- Fondo blanco dentro de la app.
- Grupos siempre privados.
- Home sin wrappers compartidos que puedan dejar el body en blanco.
- Cada pantalla usa `Scaffold` directo o estructura directa estable.
- Dentro de un grupo hay navegación fija inferior:
  - Eventos
  - Calendario
  - Finanzas
  - Torneos
  - Más
- El grupo se crea solo con nombre.
- Días, hora, ubicación y mínimo pertenecen al evento, no al grupo.

## SQL

Para esta versión se recomienda ejecutar `supabase/all_in_one.sql` porque es una base limpia.

## v12.2 — Corrección de producto

Se elimina la pestaña Eventos como navegación principal. Dentro de cada grupo, la primera pestaña ahora es Inicio: resumen real del grupo con próximos eventos y asistencia directa. Calendario es donde se visualizan y crean eventos por día. Se han eliminado los ejemplos falsos de actividad reciente.


## v12.3 — Torneos y ligas

Rehace el flujo de torneos/ligas: creación guiada, formatos liga/eliminatoria/americano, participantes, generación automática de partidos, resultados, clasificación y rondas.

## v12.4 — Finanzas estilo Tricount

Mejora completa de Finanzas: balances por miembro, quién debe a quién, formulario de gasto guiado, detalle de gasto, liquidación y reapertura de pagos. No requiere SQL nuevo si ya está ejecutado el `all_in_one.sql` de v12.


## v12.5 Calendario + eventos unidos

Mejora el flujo de eventos/quedadas: Inicio muestra próximos eventos con asistencia directa; Calendario permite crear eventos desde el día seleccionado, responder asistencia, abrir detalle, editar y cancelar. No añade SQL nuevo.


## v12.6

- Quitada frase inferior dentro del grupo.
- Back dentro de pestañas vuelve a Inicio del grupo.
- Pestañas de grupo sin flecha superior.
- Torneos mejorados: importar miembros, regenerar partidos, eliminatorias limpias.


## v12.7 compile fix

Corrige los errores de análisis de v12.6: casting de share a double, EmptySlim con body opcional y limpieza de regla inválida en analysis_options.


## v12.8

Pulido compacto de Inicio de grupo: se eliminan acciones de invitación/código/miembros/ajustes de la home, se reduce el hero, se mejora densidad visual y se amplía `security_checks.sql`. No requiere SQL nuevo.


## v12.9

Calendario en español y perfil real con nombre/foto. Ejecutar `supabase/patch_v12_9_profile_avatar_storage.sql` para habilitar subida de avatares.


## v12.10 create group RPC fix

Corrige el error PGRST203 al crear grupo eliminando funciones `create_group_atomic` antiguas/sobrecargadas en Supabase. Ejecutar `supabase/patch_v12_10_create_group_rpc_overload_fix.sql`.


## v13 — Premium UI + estabilidad global

Fase de estabilización antes de seguir creciendo: pulido visual global, Miembros y roles más claros, revisión de navegación, seguridad RLS y checks SQL ampliados.

SQL opcional si ya tienes datos: `supabase/patch_v13_roles_rls_hardening.sql`.
Reset limpio: `supabase/all_in_one.sql`.


## v14 Premium product polish

Pulido visual global: tarjetas más suaves, navegación inferior mejorada, Home más clara, hero de grupo más compacto y checks SQL actualizados. No requiere SQL obligatorio.


Última mejora incluida: `docs/V14_1_SMART_GROUP_HOME.md`.

Corrección incluida: `docs/V14_2_COMPILE_FIX.md`.


Última mejora incluida: `docs/V14_3_GROUP_HOME_PREMIUM_DASHBOARD.md`.


Última mejora incluida: `docs/V14_4_CALENDAR_EVENTS_POLISH.md`.


Última mejora incluida: `docs/V14_5_FINANCES_TRICOUNT_FINAL.md`.


Última corrección incluida: `docs/V14_5_1_FINANCES_COMPILE_FIX.md`.


Última mejora incluida: `docs/V14_6_TOURNAMENTS_GUIDED_FINAL.md`.


Última mejora incluida: `docs/V14_7_MEMBERS_INVITES_PERMISSIONS.md`.
SQL recomendado: `supabase/patch_v14_7_members_permissions.sql`.


Última mejora incluida: `docs/V14_8_PROFILE_SETTINGS_FINAL.md`.


Última mejora incluida: `docs/V14_9_INVITE_LINKS_AUTO_JOIN.md`.


Última mejora incluida: `docs/V15_0_GROUP_HOME_VISUAL_PREMIUM.md`.


Última mejora incluida: `docs/V15_1_RECURRING_EVENTS_ROUTINES.md`.


Última mejora incluida: `docs/V15_2_CALENDAR_COLORS_AGENDA.md`.


Última mejora incluida: `docs/V15_3_NET_BALANCE_AUTO_SETTLEMENT.md`.


Última corrección incluida: `docs/V15_3_1_ROUTINE_BADGE_COMPILE_FIX.md`.


Última mejora incluida: `docs/V15_4_GLOBAL_VISUAL_POLISH.md`.


Última mejora incluida: `docs/V15_5_PUSH_NOTIFICATIONS.md`.


Última mejora incluida: `docs/V15_6_SECURITY_DELETE_ACCOUNT.md`.
SQL obligatorio: `supabase/patch_v15_6_security_delete_account.sql`.


Última mejora incluida: `docs/V15_7_BLUE_VISUAL_GROUP_COVER.md`.
SQL nuevo: `supabase/patch_v15_7_visual_group_cover.sql`.


Última corrección incluida: `docs/V15_7_1_VERCEL_BUILD_FIX.md`.


Última mejora incluida: `docs/V15_8_COMPACT_VISUAL_POLISH.md`.


Última mejora incluida: `docs/V15_9_TOP_ALERTS_CLEAN_NAV_VISUAL.md`.


Última corrección incluida: `docs/V15_9_1_COMPILE_FIX.md`.


Última mejora incluida: `docs/V15_10_ULTRA_SIMPLE_UX.md`.

## v15.11

- Landing de Mis grupos más limpia, sin métricas superiores innecesarias.
- Próximo plan en Inicio del grupo con fondo más visible y botones Voy/Duda/No más claros.
- Finanzas rehechas para mostrar primero qué debes, qué te deben y quién paga a quién.
- Torneos/Ligas con sistema de puntuación configurable: general, fútbol, tenis/pádel, baloncesto, mus/cartas y personalizado.
- SQL nuevo: `supabase/patch_v15_11_finance_tournament_ux.sql`.


## v15.13

- Finanzas rediseñadas con pestañas: Gastos, Saldos y Liquidar.
- Fotos de perfil en finanzas, gastos, asistencia y miembros cuando `avatar_url` exista.

## v15.14 — Repaso global de UX y navegación

- Barra inferior del grupo con acceso directo a Más.
- Pantallas con textos más claros y headers unificados.
- Mis grupos, Agenda, Finanzas y Más más limpias y con menos duplicaciones.
- Estados vacíos mejorados.
- No requiere SQL nuevo.


## v15.15

Calendario y eventos: rutinas conectadas, edición/cancelación por alcance, agenda por día más clara y asistencia con avatares.

## v15.17 / v15.18

- Torneos y ligas con sistemas de puntuación más cerrados por deporte.
- Resultados por sets/rondas con parciales y desempates secundarios.
- Cuadro de eliminatoria más visual por rondas.
- Perfil, miembros, permisos, invitaciones y notificaciones revisados.


## v15.30.1 — Cohesión visual final de Agenda

Tarjeta de próximo plan de Agenda alineada con Inicio, sin círculos decorativos y con paleta mate.


## v15.31

- Corrección de estado/refresco en APK.
- Notificaciones abren la sección correcta del grupo.
- Agenda: semana desde hoy + 7 días.
- Finanzas simplificadas a Movimientos/Saldos con detalle de saldos.


## SQL global

El reset global canónico está en `supabase/all_in_one.sql`. El archivo antiguo `reset_global_v15_29.sql` se ha eliminado para evitar ejecutar un reset desactualizado.


## v15.32 Estabilidad

Usar solo `supabase/all_in_one.sql` para reset global. No hay parches SQL incrementales en esta versión. Realtime automático está desactivado temporalmente para evitar bucles de refresco/parpadeo.
