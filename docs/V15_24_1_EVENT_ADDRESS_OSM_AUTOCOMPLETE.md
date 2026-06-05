# Grupli v15.24.1 — Dirección de eventos con OpenStreetMap

## Qué cambia

- Se elimina la dependencia obligatoria de Google Places.
- El campo **Dirección o lugar** usa autocompletado con OpenStreetMap mediante Photon.
- No hace falta API key ni activar facturación.
- El usuario puede seguir escribiendo manualmente o pegar un enlace de Google Maps.
- En la ficha del evento se mantiene el botón **Ir a Google Maps**.

## Importante

El endpoint público por defecto es:

```text
https://photon.komoot.io/api/
```

Para beta y pruebas está bien. Para producción grande conviene configurar un proveedor propio o una instancia propia de Photon/OSM para controlar disponibilidad, límites y rendimiento.

## Variable opcional

```env
OSM_GEOCODER_ENDPOINT=https://photon.komoot.io/api/
```

Si se deja vacía, Grupli usa el endpoint por defecto.

## Flujo

1. Crear o editar evento.
2. Escribir una calle, sitio, bar, pista o pabellón.
3. Elegir sugerencia.
4. Guardar evento.
5. En la ficha del evento, tocar **Ir a Google Maps**.
