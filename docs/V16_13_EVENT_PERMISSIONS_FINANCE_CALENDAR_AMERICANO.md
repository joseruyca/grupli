# Grupli v16.13 — Eventos, finanzas, colores y Americano

## Cambios

### Eventos
- En el detalle de un evento, los botones Editar evento y Cancelar evento solo aparecen si el usuario actual creó ese evento.
- Si el evento lo creó otra persona o viene sin `created_by`, solo se puede responder asistencia.

### Finanzas
- En pagos recomendados, la acción pasa a llamarse Liquidar.
- El diálogo de confirmación también usa Liquidar para evitar confusión con Confirmar/Pagado.

### Agenda / calendario
- Se añade una leyenda compacta de colores del calendario basada en los tipos reales de evento del grupo.
- Los días siguen mostrando puntos de distintos colores según el tipo de evento:
  - partido;
  - entrenamiento;
  - cena;
  - reunión;
  - torneo/liga;
  - quedada.

### Americano
- Se refuerza el generador de rondas:
  - prioriza que un jugador no repita pareja si existe otra opción;
  - reduce rivales repetidos;
  - equilibra descansos;
  - equilibra partidos jugados.
- Se añade cálculo de rondas recomendadas para intentar cubrir todas las parejas antes de repetir.
- El texto del creador explica mejor el funcionamiento:
  - ranking individual;
  - cada jugador suma los puntos que consigue;
  - las parejas van cambiando;
  - gana quien acaba con más puntos tras las rondas.
