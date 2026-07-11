# Grupli v16.39 — Plan de producto, UX y monetización

Este documento define la dirección de la app para que siga siendo muy fácil de usar, llegue a más gente y monetice sin fastidiar la experiencia.

## Objetivo de producto

- La app debe servir muy bien en su versión gratis.
- La experiencia principal no debe depender de pagar.
- Premium debe ampliar valor, no bloquear lo esencial.
- Los anuncios deben ser suaves y nunca interferir con tareas importantes.

## Principios de UX

- Menos pasos para crear y usar cada módulo.
- Los textos deben sonar naturales, humanos y directos.
- Cada pantalla debe decir claramente qué hacer después.
- La app debe sentirse rápida aunque tenga muchas funciones.
- La jerarquía visual debe ser limpia, premium y consistente.

## Lo que debe quedar perfecto en la base gratis

- Crear grupos y torneos sin fricción.
- Registrar resultados en pocos toques.
- Ver clasificación y estado del torneo de forma clara.
- Entender qué formato se está usando sin leer demasiado.
- Corregir resultados y editar datos sin romper nada.
- Compartir información básica con facilidad.

## Monetización sin romper la experiencia

### Anuncios

- Banner pequeño en pantallas secundarias.
- Bloques nativos integrados en listas de contenido.
- Anuncios recompensados solo como opción, nunca obligatorios.
- Cero anuncios en los flujos críticos:
  - crear torneo,
  - registrar resultado,
  - revisar clasificación,
  - corregir errores.
- Límite de frecuencia muy bajo para no cansar.

### Premium

- Debe ser útil para quien organiza torneos con frecuencia.
- Debe mejorar análisis, automatización y presentación.
- Debe eliminar anuncios, pero ese no puede ser el único valor.
- Debe aportar una mejora real también en contabilidad, sin bloquear el uso gratis.

## Qué incluirá Premium

### Núcleo Premium

- Estadísticas avanzadas de torneos.
- Comparativas entre jugadores, parejas y equipos.
- Rachas, evolución y rendimiento reciente.
- Historial entre torneos y temporadas.
- Head to head más completo.
- Exportación a imagen, PDF o CSV.
- Plantillas guardadas.
- Duplicar torneos anteriores.
- Desempates personalizados.
- Más automatización de calendario y jornadas.

### Finanzas Premium

- Análisis avanzado de gastos y balances.
- Lectura rápida de quién adelanta más dinero.
- Mayor gasto, gasto medio y contexto del grupo.
- Exportación de balances y movimientos.
- Vista sin anuncios para la experiencia completa.

### Premium para grupos grandes

- Más torneos activos a la vez.
- Mejor gestión de competiciones recurrentes.
- Más control de organización y agenda.
- Reglas avanzadas para grupos que hacen torneos a menudo.

### Premium de presentación

- Resúmenes visuales más bonitos.
- Compartir resultados con estética mejorada.
- Branding del grupo o club si encaja más adelante.
- Sin anuncios en toda la app.

## Lo que debe seguir gratis

- Torneos completos y funcionales.
- Resultados y clasificación.
- Registro normal de partidos.
- Edición básica.
- Uso suficiente para que la app ya valga la pena sin pagar.

## Fases de construcción

### Fase 1: cierre de experiencia base

- Pulir torneos.
- Pulir resultados y partidos.
- Mejorar textos y vacíos.
- Reducir pasos y toques innecesarios.
- Revisar errores y validaciones.

### Fase 2: retención

- Historial útil.
- Compartir rápido.
- Acceso fácil a torneos recientes.
- Mejor navegación entre pantallas clave.

### Fase 3: monetización suave

- Colocar anuncios solo donde no molesten.
- Mostrar Premium como mejora natural.
- Evitar cualquier sensación de bloqueo agresivo.

### Fase 4: Premium real

- Estadísticas avanzadas.
- Exportación.
- Historial y comparativas.
- Plantillas y duplicado.
- Automatización avanzada.

### Fase 5: crecimiento

- Ajustes por uso real.
- Mejoras de viralidad.
- Recomendaciones y atajos.
- Optimización de conversión a Premium sin dañar la versión gratis.

## Reglas de arquitectura

- La lógica de negocio debe estar separada de la UI.
- Los deportes y formatos deben seguir centralizados.
- Premium debe estar preparado por flags y capacidades, no por lógica duplicada.
- La monetización debe poder activarse y desactivarse sin reescribir pantallas completas.

## Métricas que importan

- Tiempo para crear un torneo.
- Tiempo para registrar un resultado.
- Tasa de errores en creación y edición.
- Uso real de clasificación y resultados.
- Conversión a Premium.
- Retención en grupos que organizan torneos con frecuencia.

## Prioridad inmediata

1. Dejar torneos y resultados impecables.
2. Rematar microcopy y vacíos.
3. Definir la estructura técnica de Premium.
4. Preparar anuncios suaves.
5. Medir uso real y ajustar.

## Decisión de producto recomendada

- Gratis: uso completo para la mayoría.
- Premium: ahorro de tiempo, análisis y presentación avanzada.
- Ads: discretos, limitados y nunca invasivos.
