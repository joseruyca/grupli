# V15.1 — Rutinas / eventos repetitivos

Esta fase añade rutinas al crear eventos.

## Qué permite

- Crear evento único.
- Convertir un evento en rutina.
- Frecuencia:
  - cada semana
  - cada 2 semanas
  - cada mes
- Elegir cuántos eventos se generan.
- Ejemplo: partido todos los jueves a las 20:00.

## Cómo funciona ahora

La app genera varias ocurrencias reales en el calendario, usando el primer día y hora elegidos como referencia.

Ejemplo:
- Título: Partido semanal
- Fecha inicial: jueves 20:00
- Frecuencia: cada semana
- Eventos: 8

Resultado:
- se crean 8 eventos independientes, uno por cada jueves.

## Ventaja

Funciona ya con la base de datos actual, sin migración SQL obligatoria.

## Limitación consciente

En esta versión, cada evento generado se puede editar/cancelar por separado.
Más adelante se puede añadir edición avanzada de serie:
- solo este evento
- este y siguientes
- toda la rutina
