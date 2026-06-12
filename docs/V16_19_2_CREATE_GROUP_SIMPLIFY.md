# Grupli v16.19.2 — Create group simplify

## Objetivo

Simplificar la creación de grupos y quitar elementos que no aportan valor real al usuario.

## Cambios

- Eliminado "Tipo de grupo" del flujo de creación.
- Los grupos se crean como grupo privado genérico (`otro`) por defecto.
- Sustituida la parrilla de tipos por una tarjeta clara de "Grupo privado".
- Eliminado "Tipo de grupo" de Ajustes del grupo.
- Eliminado "Acerca de Grupli" del Perfil.
- Actualizada versión interna a v16.19.2.

## Decisión de producto

El tipo de grupo no aportaba una mejora real porque Agenda, Finanzas y Torneos funcionan independientemente de si el grupo es de deporte, amigos, viaje o cartas. Además añadía fricción en el primer paso.

Si en el futuro hace falta personalización, será mejor pedirla dentro de cada sección:

- Torneos pregunta deporte/formato.
- Finanzas pregunta moneda y reparto.
- Agenda pregunta tipo de evento.
