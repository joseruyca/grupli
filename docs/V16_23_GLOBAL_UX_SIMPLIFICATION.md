# v16.23 — Simplificación UX global

Objetivo: que Grupli sea más fácil de entender para usuarios poco tecnológicos.

## Cambios

- Tipografía ligeramente más grande y legible.
- Densidad visual menos apretada.
- Tarjetas con menos sombra y más limpieza.
- Cabeceras con textos más cortos y humanos.
- Mis grupos: tarjeta de grupo más simple, sin chips innecesarios.
- Inicio del grupo: lenguaje más directo en “Lo próximo” y actividad del grupo.
- Agenda: subtítulo más claro y leyenda de tipos menos pesada.
- Evento: asistencia más humana: “Falta 1 persona”, “Han respondido X de Y”.
- Finanzas: resumen superior más fácil de leer, menos textos técnicos, importes grandes mejor tratados.
- Se conserva la función “Qué llevamos” sin añadir complejidad.

## Seguridad

No se añaden librerías, secretos ni credenciales. No requiere SQL nuevo. Mantiene RLS existente para `event_contributions`.

## QA recomendado

- Abrir Mis grupos y comprobar lectura de tarjetas.
- Entrar en grupo y revisar “Lo próximo”.
- Abrir evento, responder Voy/Duda/No voy y revisar “Qué llevamos”.
- Abrir Agenda en semana y mes.
- Abrir Finanzas con importes grandes.
- Probar web en Vercel y APK en Android.
