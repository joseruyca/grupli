# Grupli v11 — especificación visual y funcional de pantallas

Esta versión convierte el mockup aprobado en una base de app real. El objetivo no es llenar pantallas de opciones, sino que cada usuario entienda en menos de tres segundos dónde está, qué puede hacer y qué está pasando en su grupo.

## 1. Splash / Bienvenida

Pantalla inicial con fondo blanco y una tarjeta hero grande en degradado teal. Dentro aparece el icono de grupo, la marca `grupli` y el mensaje principal: organizar el grupo y disfrutar más. El botón principal es `Comenzar`; debajo queda `Iniciar sesión` como acceso secundario. La pantalla comunica que Grupli es una app privada para organizar grupos, no una red social pública.

## 2. Inicio de sesión

Pantalla blanca, limpia y directa. Tiene cabecera con botón de volver, título grande, campos de email y contraseña, botón principal para entrar y accesos secundarios a registro y recuperación. La interfaz debe evitar ruido visual. Más adelante se podrán activar botones OAuth reales si se conectan Google o Apple en Supabase.

## 3. Home / Mis grupos

Lista todos los grupos privados del usuario. Arriba aparece `Grupli`, el saludo y un resumen breve. La pantalla ofrece dos acciones claras: crear un grupo nuevo o entrar con código. Cada grupo se muestra en una card con nombre, número de miembros, código/invitación y los cuatro módulos principales: eventos, calendario, finanzas y ligas. El objetivo es que el usuario no tenga que pensar: entra en un grupo y organiza.

## 4. Crear / Unirse a grupo

El flujo se divide mentalmente en dos caminos: crear grupo o unirse a uno existente. Crear grupo solo pide el nombre. Unirse usa código. No se pregunta por días, hora, ubicación, mínimo de personas, tipo público/privado ni nada que corresponda a una quedada concreta. Todos los grupos son privados por defecto.

## 5. Crear grupo simple

Pantalla mínima con un campo: `Nombre del grupo`. El texto auxiliar explica que el grupo es privado y que se entra por invitación, código o QR. El creador del grupo queda como owner/admin inicial. Desde el detalle del grupo podrá nombrar otros admins.

## 6. Detalle del grupo / Overview

Es la pantalla central de un grupo. Arriba tiene una hero card con degradado, nombre del grupo, candado privado, número de miembros y rol del usuario. Debajo aparecen acciones rápidas: invitar, copiar código, miembros y ajustes. Luego se muestra el código de invitación con botones copiar/compartir. Más abajo aparecen las cuatro tarjetas principales: Eventos, Calendario, Finanzas y Torneos. La zona final contiene administración: miembros, editar grupo, regenerar código, salir o eliminar si eres owner.

## 7. Navegación interna del grupo

Cada pantalla dentro de un grupo lleva barra inferior fija con cinco accesos: Eventos, Calendario, Finanzas, Torneos y Más. Esta barra no sustituye a la navegación global de la app; solo aparece dentro de un grupo. Sirve para moverse entre las cuatro funciones clave sin volver atrás.

## 8. Eventos / Quedadas

Pantalla para crear y consultar eventos concretos del grupo. Un evento tiene título, fecha, hora, lugar, descripción opcional y mínimo de asistentes. Los miembros pueden responder `Voy`, `Duda` o `No voy`. La pantalla muestra próximas quedadas y permite abrir cada detalle para ver asistencia.

## 9. Crear / Editar evento

Formulario pensado para no abrumar. Campos: título, fecha, hora, lugar, notas opcionales y mínimo de asistentes. Debe indicar quién puede responder y qué significa cada respuesta. Los admins podrán editar o cancelar eventos; los miembros responderán asistencia.

## 10. Detalle de evento / Asistencia

Muestra toda la información del evento: fecha, hora, lugar, notas, organizador y estado. La asistencia se resume en tres bloques visibles: voy, duda, no voy. Debajo aparece la lista de miembros con su respuesta. El sistema debe avisar si se alcanza o no el mínimo de asistentes.

## 11. Calendario

Vista mensual del grupo. Los días con eventos aparecen marcados. Al seleccionar un día se listan los eventos de ese día debajo. Desde aquí se puede crear un nuevo evento en la fecha seleccionada. Esta pantalla sirve para organizarse visualmente y evitar confusiones de fechas.

## 12. Finanzas / Resumen

Funciona como un Tricount sencillo. Arriba se ve el saldo del usuario, lo pendiente del grupo y pagos abiertos. Después aparece quién debe a quién con pagos recomendados para dejar el grupo a cero. Más abajo están los movimientos: cenas, pistas, gasolina, compras, etc.

## 13. Añadir gasto

Formulario con concepto, importe, quién pagó y participantes. Permite reparto igual y prepara reparto personalizado. La pantalla debe explicar cuánto paga cada persona antes de guardar. El objetivo es que nadie tenga que hacer cuentas fuera de la app.

## 14. Torneos / Ligas

Lista torneos activos y finalizados. Cada torneo muestra formato, equipos/jugadores, estado y progreso. Dentro se pueden añadir equipos, generar partidos, meter resultados y ver clasificación. Está pensado para pádel, fútbol, cartas, tenis o cualquier competición de grupo.

## 15. Perfil / Ajustes

Perfil escueto. Foto, nombre, email, grupos del usuario y estadísticas básicas. Ajustes contiene notificaciones, privacidad, ayuda y cierre de sesión. No debe ser una red social ni un perfil complejo.

## Reglas de producto

- Todos los grupos son privados.
- El acceso se hace por invitación, código, enlace o QR.
- El creador es owner y puede nombrar admins.
- Las cuatro funciones clave viven dentro de cada grupo: Eventos, Calendario, Finanzas y Torneos.
- La barra inferior interna del grupo debe estar siempre visible dentro de esas funciones.
- Fondo blanco, interfaz clara, moderna y premium.
- Nada de formularios largos si no son necesarios.
- Cada pantalla debe tener una acción principal clara.
