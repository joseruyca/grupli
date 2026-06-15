# v16.24 — Inicio del grupo más claro

Fase centrada solo en la pantalla de inicio del grupo cuando hay un evento próximo.

## Cambios

- Banner del grupo algo más compacto para que el evento gane protagonismo.
- Frase de contexto bajo el banner: indica si hay planes pendientes de confirmar.
- Botón de la sección `Lo próximo` cambiado de `Calendario` a `Ver planes`.
- Tarjeta del próximo evento con pregunta explícita: `¿Vas a venir?`.
- Botones de asistencia cortos y claros: `Voy`, `Quizás`, `No`.
- Se separa el estado del grupo de los botones: ahora aparece una frase con respuestas y pendientes.
- `Último del grupo` pasa a `Últimos cambios`.
- Las filas recientes son más humanas: `Plan: ...`, `Gasto: ...`, `Pendiente · importe`.
- Añadidos accesos rápidos grandes a Agenda, Gastos, Torneos y Miembros.
- El botón flotante `+` pasa a ser `Crear plan`, para que la acción sea obvia.

## Seguridad

- No requiere SQL nuevo.
- No añade librerías.
- No toca Supabase/RLS.
- No añade claves ni credenciales.
