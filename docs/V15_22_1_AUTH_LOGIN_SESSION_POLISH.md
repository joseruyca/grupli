# Grupli v15.22.1 — Login y recuperación de sesión en APK

Esta versión pule el inicio de sesión en Android/APK.

## Problema detectado

En un móvil de prueba podía quedarse guardada una sesión local antigua o inválida. La app intentaba cargar datos con esa sesión y mostraba el mensaje:

> Tu sesión necesita actualizarse. Cierra sesión y vuelve a entrar.

Cerrar sesión desde el navegador no limpia la sesión guardada dentro de la APK instalada en otro móvil, porque son almacenamientos distintos.

## Cambios incluidos

- Validación de sesión al arrancar la app.
- Si la sesión local está caducada o corrupta, se limpia y se devuelve al login.
- Antes de iniciar sesión por email/contraseña se limpia cualquier sesión local antigua del dispositivo.
- Botón nuevo en login: **Limpiar sesión de este móvil**.
- Los errores de login ahora distinguen mejor entre:
  - email/contraseña incorrectos;
  - email sin confirmar;
  - sesión local caducada;
  - problemas de conexión;
  - permisos/RLS.
- Los estados de error por sesión muestran botón: **Salir y volver a entrar**.

## Cómo probar

1. Instalar la APK nueva.
2. Abrir con una cuenta que ya haya usado otra APK.
3. Si aparece error de sesión, tocar **Salir y volver a entrar**.
4. En la pantalla de login, usar **Limpiar sesión de este móvil** si el móvil venía de pruebas anteriores.
5. Iniciar sesión con email y contraseña.

