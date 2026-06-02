# Grupli v10 — contrato real de producto

Esta versión corrige la dirección del proyecto para que Grupli sea una app móvil premium, no una demo web acumulada por parches.

## Reglas de producto

- Grupli es una app para Play Store y App Store.
- Fondo base blanco.
- Diseño móvil real: limpio, fácil, con jerarquía clara y sin pantallas genéricas.
- Cada grupo es privado y cerrado.
- Un grupo no tiene día, hora, ubicación, mínimo de personas ni estado público.
- La organización vive dentro del grupo.
- El creador del grupo es owner/admin.
- El owner puede nombrar más admins.
- Los miembros normales participan, confirman asistencia, pagan gastos y juegan torneos, pero no administran permisos críticos.

## Funcionalidades clave dentro de cada grupo

1. Eventos / quedadas
   - Crear quedadas.
   - Fecha y hora.
   - Ubicación.
   - Notas.
   - Mínimo de personas por evento.
   - Participantes confirman: voy / duda / no voy.
   - Ver quién falta por responder.

2. Calendario
   - Vista mensual.
   - Eventos por día.
   - Resumen de próximas quedadas.
   - Organización clara del grupo.

3. Finanzas estilo Tricount
   - Crear gasto.
   - Elegir pagador.
   - Elegir participantes.
   - Reparto igual o personalizado.
   - Ver balances.
   - Ver quién debe a quién.
   - Marcar pagos/liquidaciones.

4. Ligas y torneos
   - Crear torneo.
   - Equipos/jugadores.
   - Generar partidos.
   - Registrar resultados.
   - Clasificación automática.
   - Finalizar/reabrir torneo.

## Perfil

- Perfil escueto.
- Foto/avatar.
- Nombre visible.
- Ajustes básicos.
- No convertir perfil en red social.

## Reglas de desarrollo desde v10

- No añadir funcionalidad nueva mientras haya errores base.
- Cada cambio debe tocar el menor número posible de módulos.
- Primero estabilidad, luego diseño pantalla por pantalla.
- No mezclar SQL, diseño y lógica salvo que el cambio lo exija.
- Si una pantalla se rediseña, se comprueba que no rompe login, grupos, detalle y permisos.
