# Grupli v16.11 — Editor completo de torneos

Esta fase se centra en edición real, no en modo live.

## Objetivo

Que el organizador pueda mantener un torneo vivo sin tener que borrar y volver a crear.

## Incluye

- Editor visual de participantes.
- Añadir miembros del grupo sin escribir texto.
- Crear parejas visualmente desde miembros del grupo.
- Avatares en la lista de participantes cuando existen.
- Añadir participantes por texto sigue disponible.
- Editar nombre del torneo.
- Editar deporte y reglas antes de que haya resultados.
- Bloqueo de cambios peligrosos si ya hay resultados registrados.
- Reprogramación de jornada/lote con vista previa.
- Confirmación fuerte antes de aplicar cambios masivos de fechas.
- Historial del torneo más claro desde Ajustes.
- Historial de cada partido sigue disponible desde el menú del partido.

## Reglas de seguridad UX

- Si ya hay resultados, se bloquea cambiar deporte/reglas.
- Regenerar partidos ya estaba bloqueado si hay resultados.
- Reprogramar solo afecta partidos no jugados.
- Las fechas se muestran antes de guardar.
- Los eventos de Agenda se actualizan si están vinculados.

## Prueba recomendada

1. Crear una liga.
2. Entrar en Participantes.
3. Añadir miembros del grupo con el selector visual.
4. Crear una pareja con dos miembros.
5. Renombrar un participante.
6. Entrar en Ajustes y cambiar nombre/deporte antes de meter resultados.
7. Registrar un resultado.
8. Volver a Ajustes y comprobar que las reglas quedan bloqueadas.
9. Mover una jornada completa con vista previa y confirmación.
10. Revisar historial del torneo.
