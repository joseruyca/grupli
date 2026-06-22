# v16.27 — Arquitectura final de Torneos

Esta fase no añade pagos reales ni cambia SQL. Ordena la base interna para que Torneos no siga creciendo con parches.

## Decisiones de producto cerradas

- Torneos pertenece al grupo, no al usuario individual.
- Premium futuro será por grupo.
- Grupos grandes y participantes amplios se mantienen gratis.
- El tercer puesto en eliminatorias se mantiene gratis.
- Premium no se muestra de forma agresiva en la pantalla principal.
- El lenguaje técnico queda fuera de la UI.

## Tipos de torneo base

- Liga
- Eliminatoria
- Americano
- Manual

## Deportes y marcadores base

- Fútbol: goles.
- Basket: puntos totales.
- Tenis / Pádel: sets y juegos.
- Voleibol: sets y puntos de set.
- Ping pong: sets y puntos.
- Cartas / Mus: partidas o tantos.
- Dardos: puntos o legs.
- Billar: partidas.
- Gaming: mapas o rondas.
- Libre: marcador simple.

## Estadísticas gratis

Las estadísticas necesarias para jugar siguen siendo gratis:

- clasificación
- partidos jugados
- victorias
- derrotas
- empates si aplica
- puntos
- goles, sets, juegos o puntos según deporte
- progreso del torneo

## Premium futuro preparado

Premium se prepara como permisos, sin pagos reales todavía:

- torneos activos ilimitados
- americano avanzado
- múltiples pistas inteligentes
- calendario automático avanzado
- mover jornadas completas
- estadísticas avanzadas
- historial de rendimiento
- rachas avanzadas
- desempates configurables
- exportar clasificación
- compartir resumen bonito
- duplicar torneo
- plantillas guardadas
- cabezas de serie
- ranking histórico del grupo

## Arquitectura interna añadida

Se centraliza la definición de:

- deportes
- tipo de marcador
- estadísticas gratis
- estadísticas premium
- permisos premium futuros
- alcance premium por grupo

La configuración queda dentro de `TournamentEngineV2` como arquitectura estable `tournaments_final_architecture_v1`.

## No incluido en esta fase

- pagos reales
- Google Play Billing
- App Store subscriptions
- Stripe
- nuevas tablas SQL
- límites duros de premium
- rediseño completo de creación
- reescritura de clasificación

