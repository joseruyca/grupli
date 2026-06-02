# Grupli v11.5 — réplica funcional del mockup aprobado

Esta versión traduce el mockup aprobado a código Flutter real. El objetivo no es añadir nuevas tablas ni tocar Supabase, sino dejar la interfaz y navegación con la estructura visual correcta antes de pulir cada página al detalle.

## 1. Splash / bienvenida
Pantalla blanca con una tarjeta hero vertical en degradado teal. Dentro aparece el icono de grupos, el nombre `grupli`, el mensaje principal y el botón `Comenzar`. El fondo del hero tiene pequeños iconos repetidos de eventos, calendario, finanzas, torneos, candado y QR para comunicar visualmente las funciones de la app sin saturar.

## 2. Inicio de sesión
Pantalla limpia, blanca y centrada en el formulario. Arriba hay título grande, subtítulo y botón de volver. Aparecen accesos sociales visuales para Google y Apple, separador `o`, campos de email y contraseña, enlace de recuperación y botón principal teal.

## 3. Home / Mis grupos
La home pasa a llamarse `Mis grupos`, igual que el mockup. Muestra saludo, tres métricas compactas, lista de grupos privados con miniatura, avatares simulados, número de eventos y acceso rápido. Abajo mantiene la navegación global con Inicio, Avisos y Perfil.

## 4. Crear / unirse a grupo
La entrada se mantiene desde la home y bottom sheet de código. No se piden datos que no pertenecen al grupo. Los grupos son privados por defecto y el acceso será por código/enlace/QR.

## 5. Crear grupo simple
Formulario mínimo: solo nombre del grupo. Debajo se explica que el grupo es privado, que nadie lo encuentra públicamente y que eventos, gastos y torneos se configuran dentro del grupo. El botón final crea el grupo.

## 6. Detalle del grupo / Overview
Pantalla con hero superior en degradado, nombre del grupo, candado y número de miembros. Debajo hay cuatro acciones rápidas: Invitar, Código, Miembros y Ajustes. Después aparece una tarjeta de actividad/código y una sección de funciones principales.

## 7. Pestañas principales dentro del grupo
Todas las pantallas internas del grupo usan navegación inferior fija con cinco pestañas: Eventos, Calendario, Finanzas, Torneos y Más. Esto permite moverse entre las cuatro funciones clave y la vista general sin volver atrás.

## 8. Eventos / Quedadas
Pantalla interna conectada a la navegación de grupo. La idea visual es lista de próximos eventos con estado de asistencia, participantes y botón para crear evento. La base actual se mantiene funcional.

## 9. Crear / editar evento
Cada evento tiene título, fecha, hora, lugar, notas y mínimo de asistentes. La asistencia se gestiona dentro del evento, no en el grupo.

## 10. Detalle de evento / Asistencia
Muestra datos del evento, resumen de Voy / Duda / No voy y lista de miembros con su respuesta. El usuario puede confirmar asistencia desde el detalle.

## 11. Calendario
Vista mensual para organizar todas las quedadas. Los días con eventos quedan marcados y abajo aparece la agenda del día seleccionado.

## 12. Finanzas
Resumen del grupo con saldo, pendientes, gastos recientes y balances. Se mantiene como función tipo Tricount.

## 13. Añadir gasto
Formulario para concepto, importe, quién pagó y reparto entre participantes.

## 14. Torneos / Ligas
Listado de torneos activos y finalizados. Cada torneo tiene estado y acceso a clasificación, partidos y equipos.

## 15. Perfil / Ajustes
Perfil escueto con foto, nombre, email, métricas básicas, editar perfil, cambiar foto, ajustes y cerrar sesión.

## Reglas de producto
- Todos los grupos son privados.
- El creador del grupo es owner/admin.
- Un grupo contiene cuatro funciones principales: Eventos, Calendario, Finanzas y Torneos.
- Días, hora, lugar y mínimo de personas pertenecen a cada evento, no al grupo.
- La navegación inferior del grupo debe estar siempre disponible dentro de las funciones del grupo.
- Fondo blanco, cards limpias, teal como acción principal, iconografía clara y bordes suaves.
