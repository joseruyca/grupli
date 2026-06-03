# V14.9 — Invitaciones reales con link directo + join automático

Esta fase convierte el código privado en una invitación real.

## Qué cambia

- Enlace directo del grupo:
  - https://grupli.vercel.app/join/CODIGO
- Compartir invitación manda link + código.
- Copiar link desde Más.
- La pantalla de bienvenida detecta `/join/CODIGO`.
- Si el usuario no tiene sesión:
  - se guarda la invitación pendiente
  - inicia sesión o crea cuenta
  - al entrar, Grupli intenta unirlo automáticamente
- Si el usuario ya tiene sesión:
  - al abrir el link, se une automáticamente y entra en el grupo.
- Si ya pertenecía al grupo:
  - se abre el grupo igualmente.
- El campo “Unirme a un grupo” acepta código o enlace.

## Notas

- No requiere SQL nuevo.
- Requiere que Vercel mantenga el rewrite `/(.*) -> /index.html`, ya incluido.
- Para APK/iOS, el siguiente paso será configurar deep links nativos (`grupli://join/CODIGO` y universal links/app links).
