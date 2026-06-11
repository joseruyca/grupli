# Idiomas y moneda — plan correcto

## Idiomas

Para lanzar Grupli como mínimo en español e inglés, lo correcto es no traducir pantalla por pantalla a mano dentro de `main.dart`.

Hay que hacer:

1. Crear un sistema de localización.
2. Extraer textos a claves.
3. Tener archivos:
   - `app_es.arb`
   - `app_en.arb`
4. Usar `context.l10n.xxx` en las pantallas.
5. Guardar idioma preferido del usuario.
6. Permitir usar idioma del dispositivo por defecto.

## Moneda

No conviene convertir gastos antiguos dinámicamente cada vez que se abre Finanzas, porque el tipo de cambio cambia con el tiempo y rompería balances históricos.

Modelo recomendado:

- Cada grupo tiene una moneda base: EUR, USD, GBP...
- Cada gasto guarda:
  - moneda original,
  - importe original,
  - moneda base del grupo,
  - tipo de cambio usado en ese momento,
  - importe convertido a moneda base.
- Si cambias la moneda del grupo:
  - opción A: afecta solo a nuevos gastos.
  - opción B: conversión histórica con confirmación fuerte y snapshot del tipo de cambio.
- Para producción, usar tipos de cambio fijados por fecha, no tasas en vivo sin guardar.

Recomendación: primero implementar selector de moneda base solo para nuevos gastos. Luego añadir conversión histórica como acción premium/avanzada.
