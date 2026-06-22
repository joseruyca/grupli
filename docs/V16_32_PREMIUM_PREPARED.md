# v16.32 — Premium preparado

Objetivo: preparar Grupli Premium como una capa de permisos y experiencia, sin activar pagos reales todavía.

## Decisiones de producto

- Premium será por grupo, no por usuario individual.
- Si un grupo activa Premium en el futuro, todos los miembros lo disfrutan dentro de ese grupo.
- Grupos grandes siguen siendo gratis.
- Participantes amplios siguen siendo gratis.
- El tercer puesto en eliminatorias sigue siendo gratis.
- La versión gratis debe permitir organizar grupos reales.
- Premium debe ahorrar tiempo, añadir estadísticas y mejorar la presentación.

## Gratis

- Grupos grandes.
- Participantes amplios.
- Liga básica.
- Eliminatoria básica.
- Manual básico.
- Americano básico.
- Resultados por deporte.
- Clasificación básica.
- Tercer puesto.
- Editar partidos uno a uno.
- Añadir partidos a Agenda.

## Premium futuro

- Torneos activos ilimitados.
- Americano avanzado.
- Múltiples pistas inteligentes.
- Calendario automático avanzado.
- Mover jornadas completas.
- Estadísticas avanzadas.
- Historial de rendimiento.
- Rachas avanzadas.
- Desempates configurables.
- Exportar clasificación.
- Compartir resumen bonito.
- Duplicar torneo.
- Plantillas guardadas.
- Cabezas de serie.
- Ranking histórico del grupo.
- Personalización visual del grupo.

## Cambios técnicos

- Añadida capa `GrupliPremium`.
- Añadido modelo `GroupPremiumEntitlement`.
- Añadida pantalla `PremiumGroupScreen` en ajustes del grupo.
- Añadido bloqueo suave `showPremiumFeatureGate` para futuras funciones premium.
- Centralizados los permisos premium para evitar pegotes en botones sueltos.
- Los pagos siguen desactivados con `billingEnabled = false`.
- No se añade SQL nuevo.
- No se añaden librerías.
- El frontend queda preparado, pero no decide solo si un grupo es Premium.

## Seguridad

Cuando se activen pagos en una fase posterior, la app deberá consultar el estado Premium desde backend/Supabase. El frontend no debe validar compras ni suscripciones por sí solo.
