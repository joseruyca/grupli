# Grupli v15.25.2 — Foto de grupo completa, perfil y navegación

## Cambios

- La portada del grupo ocupa todo el panel del banner.
- Las tarjetas de grupos en “Mis grupos” usan la foto como fondo completo.
- Se eliminan los fondos con estampado/iconos y el tinte azul fuerte sobre la portada.
- El botón de tres puntos de la parte superior del grupo se sustituye por el perfil propio del usuario.
- El banner del grupo mantiene solo el botón de editar.
- El editor de imagen deja de depender de controles raros:
  - arrastrar con el dedo para mover la imagen;
  - pellizcar para hacer zoom;
  - slider de zoom solo como apoyo.
- Se mantiene el recorte para:
  - portada de grupo en formato banner;
  - foto de perfil en formato cuadrado/circular.
- Se revisan rutas principales de navegación:
  - atrás desde el grupo vuelve correctamente;
  - desde perfil se puede volver al grupo;
  - los accesos de resumen siguen llevando a Agenda, Finanzas o Torneos.

## Nota

No requiere SQL nuevo.
No resetea base de datos.
