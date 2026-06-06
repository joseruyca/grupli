# Grupli v15.29.3 — Mejor editor de fotos

Mejora el editor de fotos de perfil y portadas de grupo.

## Problema anterior

El ajuste vertical no se sentía natural porque la previsualización usaba `BoxFit.cover + Alignment + Transform.scale`, mientras el guardado usaba otro cálculo de recorte. Eso podía hacer que mover arriba/abajo pareciera poco fiable.

## Solución

Ahora el editor usa un único cálculo real de recorte para:

- previsualizar;
- arrastrar;
- hacer zoom;
- guardar.

La zona que ves es exactamente la zona que se guarda.

## Métodos de ajuste

- Tocar una zona importante para centrarla.
- Arrastrar la imagen con el dedo.
- Pellizcar para zoom.
- Botones rápidos: Arriba, Centro, Abajo, Izquierda, Derecha.
- Control fino vertical.

## Archivos tocados

- `lib/main.dart`

No requiere SQL.
