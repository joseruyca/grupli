# Grupli v15.23 — Core hardening

Esta fase no toca login/onboarding general. Se centra en las zonas de producto que tienen que estar muy sólidas antes de beta.

## Crear grupo perfecto

- Nuevo flujo guiado de 3 pasos:
  1. nombre + tipo de grupo;
  2. portada + descripción + moneda;
  3. primeros pasos recomendados.
- Tipos de grupo:
  - deporte;
  - amigos;
  - viaje;
  - cartas;
  - otro.
- Los grupos siguen siendo privados por defecto.
- Se puede añadir portada al crear el grupo.
- Al terminar se recomienda invitar miembros, crear primer plan, añadir primer gasto y, si encaja, crear torneo.

## Invitaciones y unión al grupo

- Enlaces y códigos siguen siendo compatibles.
- Se añade regeneración de código desde ajustes del grupo.
- El código anterior deja de servir para nuevas invitaciones.
- Si alguien ya está dentro, la unión sigue siendo idempotente y no duplica miembros.
- El flujo de invitación mantiene el código pendiente si el usuario tiene que registrarse o iniciar sesión.

## Ajustes de grupo

- Ahora se puede revisar y editar:
  - nombre;
  - tipo;
  - descripción;
  - portada;
  - moneda;
  - idioma;
  - zona horaria;
  - reglas del grupo;
  - código de invitación.

## Finanzas y realtime

- Se mantiene el optimizador escalable por balance neto.
- Se mantiene el cálculo en céntimos.
- No se liquida gasto por gasto.
- La app sigue preparada para realtime en eventos, gastos, liquidaciones, torneos y miembros.

## SQL

Ejecutar `supabase/patch_v15_23_core_hardening_create_invite_finance_realtime.sql`.

No resetea datos.
