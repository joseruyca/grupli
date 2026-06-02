# Reglas para rediseñar páginas después de v9

## Regla principal

A partir de v9, cada página se cambia de una en una.

No se debe tocar a la vez:

- Home
- Detalle grupo
- Miembros
- Calendario
- Finanzas
- Torneos
- Perfil
- Ajustes

## Checklist antes de tocar una página

1. La app compila.
2. La ruta actual funciona.
3. La función principal de esa página funciona.
4. El cambio solo toca archivos de esa feature y componentes UI compartidos si es imprescindible.
5. Se prueba local.
6. Se sube con commit claro.

## Commits recomendados

```text
Polish Grupli home screen
Polish group detail screen
Polish members screen
Polish calendar screen
Polish finances screen
Polish tournaments screen
Polish profile screen
Polish settings screen
```

## Criterio visual

La app debe seguir el concepto aprobado:

- clara a simple vista;
- estilo distintivo pero no loco;
- sin colores llamativos;
- sin fondos oscuros;
- sin aspecto genérico IA;
- cards limpias;
- botones evidentes;
- navegación sencilla.
