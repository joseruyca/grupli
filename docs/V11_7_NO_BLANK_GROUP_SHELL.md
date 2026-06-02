# v11.7 — Regla anti pantalla blanca dentro de grupo

Este parche corrige el fallo visual donde al entrar en un grupo solo se veía la barra inferior y el cuerpo quedaba blanco.

## Causa

Las pantallas internas del grupo estaban usando `AppScreen`, que a su vez podía envolver scrolls dentro de layouts con altura floja. En Flutter Web esto puede acabar dejando el body sin pintar mientras `bottomNavigationBar` sí aparece.

## Cambio aplicado

Se crea `lib/ui/group_page_scaffold.dart`.

Las páginas principales del grupo ahora usan este shell estable:

- Detalle del grupo / Más
- Eventos
- Calendario
- Finanzas
- Torneos

La estructura es intencionadamente simple:

```text
Scaffold
  bottomNavigationBar fija
  body
    SafeArea
      LayoutBuilder
        SingleChildScrollView
          Center
            SizedBox(maxWidth 430)
              Padding
                contenido real
```

## Regla

No volver a montar las pestañas internas del grupo con `AppScreen`.

Las pestañas internas del grupo deben usar siempre:

```dart
GroupPageScaffold(
  groupId: groupId,
  navIndex: index,
  child: ...
)
```

## Diseño

El objetivo visual sigue siendo replicar el mockup aprobado:

- Fondo blanco
- Cards blancas con borde fino
- Teal como color principal
- Iconos claros
- Navegación inferior fija dentro del grupo
- Nada de pantallas vacías silenciosas
