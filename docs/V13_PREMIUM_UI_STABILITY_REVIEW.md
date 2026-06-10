# Grupli v13 — Premium UI + estabilidad global

Esta fase no añade una funcionalidad grande nueva. Su objetivo es estabilizar y pulir la app para que empiece a sentirse como una app real de Play Store / App Store.

## Cambios de interfaz

- Cards más limpias, con bordes finos, sombra muy suave y radio consistente.
- Botones principales y secundarios con altura uniforme y menos sensación de prototipo.
- Bottom navigation más compacto.
- Estadísticas compactas para evitar pantallas largas innecesarias.
- Inicio de grupo más centrado en información útil: próxima quedada, asistencia, estado del grupo, gastos y torneos.
- Microtextos más claros y menos genéricos.

## Navegación

La estructura de navegación se mantiene así:

1. Mis grupos.
2. Entrar en grupo.
3. Dentro del grupo: Inicio / Calendario / Finanzas / Torneos / Más.
4. Si estás en Calendario, Finanzas, Torneos o Más y pulsas atrás, vuelve a Inicio del grupo.
5. Desde Inicio puedes volver a Mis grupos.

## Miembros y roles

- Se diferencia claramente owner, admin y miembro.
- Owner/admin pueden hacer admin, quitar admin y expulsar miembros.
- El owner no se puede degradar ni expulsar.
- Los miembros normales ven permisos claros.
- La pantalla muestra el código de invitación, pero como contexto, no como acción protagonista del Inicio.

## Finanzas

Se mantiene el flujo con reparto claro:

- Gasto total.
- Quién pagó.
- Participantes.
- Reparto.
- Quién debe a quién.
- Liquidación recomendada.
- Balances individuales.
- Marcar como liquidado / reabrir.

## Torneos y ligas

Se mantiene el flujo guiado:

- Crear competición.
- Elegir formato.
- Elegir participantes.
- Añadir miembros del grupo.
- Generar partidos.
- Registrar resultados.
- Ver clasificación.
- Finalizar competición.

## SQL y RLS

- `all_in_one.sql` incorpora las reglas v13.
- `patch_v13_roles_rls_hardening.sql` endurece roles sin resetear datos.
- `security_checks.sql` comprueba RLS, funciones RPC, grupos privados, owner único y políticas.

## Regla para siguientes fases

No añadir más funciones grandes hasta que las pantallas principales se vean compactas, coherentes y estables.
