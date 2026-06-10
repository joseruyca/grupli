# Grupli v16.12.5 — Limpieza UI Agenda/Torneos/Finanzas

## Cambios

### Finanzas
- En Pagos recomendados el botón ya no dice “Pagado”.
- Ahora dice “Registrar” con color teal, para que no parezca que el pago ya está hecho.
- La acción sigue registrando el pago cuando el usuario la pulsa.

### Creador de torneos
- Eliminado el bloque visible “Modo rápido recomendado”.
- Eliminado el selector rápido/avanzado visible.
- La creación muestra directamente Liga, Americano, Eliminatoria y Manual.
- La pantalla de formato entra directamente en la vista completa con vueltas, jornadas, rondas y pistas.
- Liga ya no fuerza visualmente fútbol por defecto; usa puntuación general hasta que el usuario elige deporte.

### Liga
- El texto de jornadas ahora cambia según las vueltas:
  - muestra jornadas por vuelta;
  - muestra total de jornadas según vueltas.

### Sorteo / anti-trampas
- Al generar emparejamientos automáticos se sortea el orden de participantes.
- Esto afecta a liga, eliminatoria y americano.
- La explicación de eliminatoria ahora indica que los cruces y byes se asignan después del sorteo.

### Pistas
- Límite visible subido de 8 a 12 pistas/mesas simultáneas.
- Mantiene límites razonables para no bloquear móviles.

### Calendario de torneos
- Eliminados de la interfaz:
  - duración de partido;
  - separación entre turnos.
- Se mantienen valores internos seguros por defecto.

### Agenda
- Si hay varios partidos de liga/torneo el mismo día, Agenda usa una tarjeta compacta agrupada.
- Evita mostrar varias tarjetas enormes una debajo de otra.
- Los eventos de liga/torneo se mantienen en dorado/ámbar.
- La tarjeta de inicio también agrupa varios eventos del mismo día.

## SQL

No requiere SQL nuevo.
