# Grupli v16.6.1 — Revisión y pulido de torneos

Revisión estática de la v16.6 tras completar Liga, Manual, Eliminatoria y Americano.

## Ajustes aplicados

- En el dashboard de Torneos, los partidos de Americano ya muestran las parejas completas.
- En la reprogramación por lote, la vista previa ya muestra parejas completas de Americano.
- La tabla de Americano ahora se presenta como **Ranking individual**.
- En Americano, la columna principal se muestra como **Jugador** en vez de Equipo.
- Al elegir Americano en la creación, se aplica puntuación libre/general por defecto para que el ranking sume puntos/juegos individuales.
- Limpieza menor de variables locales innecesarias.

## Revisión funcional

La base de torneos queda estructurada así:

- Liga: clasificación, desempates, resultados especiales e historial.
- Manual: editor visual, partidos con selectores, duplicar jornada y reordenar.
- Eliminatoria: cuadro visual, byes, cabezas de serie, siguiente ronda y tercer puesto.
- Americano: rotación, ranking individual, descansos, evitar repeticiones y rondas por pista.

## Pendiente de comprobar en PC

Este entorno no tiene Flutter instalado, por lo que la validación final debe hacerse con:

```powershell
flutter analyze
.\scripts\build_android_debug_apk.ps1
```
