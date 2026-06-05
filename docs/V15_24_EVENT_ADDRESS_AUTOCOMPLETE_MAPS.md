# Grupli v15.24 — Dirección con autocompletar + Google Maps

## Qué incluye

- Campo opcional **Dirección o lugar** al crear o editar eventos.
- Autocompletado de direcciones, calles y sitios usando OpenStreetMap / Photon.
- Si no hay API key configurada, el campo sigue funcionando de forma manual.
- En la ficha del evento aparece una tarjeta de dirección.
- Botón **Ir a Google Maps** para abrir la dirección del evento en Google Maps.
- Soporta web y APK Android.

## Configuración necesaria

Añadir en `.env`:

```env
OSM_GEOCODER_ENDPOINT=https://photon.komoot.io/api/
```

No hace falta API key. Opcionalmente puedes añadir `OSM_GEOCODER_ENDPOINT` en Vercel si quieres usar otro endpoint compatible.

## APIs de Google recomendadas

En Google Cloud / Google Maps Platform activa:

- Photon / OpenStreetMap
- Maps URLs no necesita API key para abrir el enlace, pero el autocompletar sí.

## Seguridad de la API key

Para producción, restringe la clave:

- Android: por package name y SHA-1.
- Web: por dominio `https://grupli.vercel.app`.

## Nota técnica

Grupli guarda la dirección elegida en el campo existente `events.location`, así que no requiere SQL nuevo.
