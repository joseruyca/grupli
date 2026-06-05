# Grupli v15.21.1 — Fix APK Android navegación y tarjetas

## Qué corrige

- Evita que los botones nativos de Android tapen la barra inferior de Grupli.
- Añade SafeArea global inferior en MaterialApp.
- Ajusta el estilo de barras del sistema para Android moderno / edge-to-edge.
- Corrige las tarjetas de grupos de la pantalla Mis grupos:
  - área táctil completa;
  - texto visible;
  - sin Spacer en una columna con altura no acotada;
  - tap más fiable en APK real.

## Por qué pasa

En Android 15+ las apps que apuntan a SDK 35 pueden entrar en modo edge-to-edge y la navegación del sistema se dibuja sobre la app si no se respetan los insets.

## Prueba recomendada

1. Instalar APK nueva.
2. Abrir Mis grupos.
3. Tocar cualquier tarjeta de grupo.
4. Comprobar que entra al grupo.
5. Comprobar que la barra inferior queda por encima de los botones nativos del móvil.
