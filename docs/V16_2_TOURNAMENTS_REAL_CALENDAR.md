# V16.2 — Torneos: calendario real

Cambios incluidos:

- Vista previa del calendario antes de crear el torneo.
- Configuración de varias pistas/mesas/campos simultáneos.
- Reparto de partidos por turnos: si hay varias pistas, los partidos de la misma jornada se programan en paralelo.
- Nombre automático de pista/mesa: Pista 1, Pista 2, etc.
- Reprogramación de jornada completa o lote de partidos desde Partidos/Ajustes.
- Cambio en lote de fecha, hora, duración, separación, ubicación y pista.
- Sincronización con Agenda:
  - crea eventos si no existen;
  - actualiza eventos si ya estaban vinculados;
  - cancela el evento al cancelar un partido;
  - al quitar fecha de un partido se cancela/quita el evento asociado.
- Abrir el evento de Agenda desde el menú de cada partido vinculado.

No requiere SQL nuevo si ya se ejecutó el `supabase/all_in_one.sql` de v16.
