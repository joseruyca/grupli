# v11.6 Home render rule

La pantalla Home / Mis grupos ya no usa `AppScreen`.

Motivo: el bug repetido era que el body podía quedar invisible y solo se veía la navegación inferior. Para cortar el problema de raíz, `GroupsScreen` usa ahora un `Scaffold` directo con:

- `SafeArea`
- `Center`
- `ConstrainedBox(maxWidth: 430)`
- `ListView` directo
- `AppBottomNav` en `bottomNavigationBar`

Regla: no volver a envolver la Home en `AppScreen`, `Align + SingleChildScrollView`, `Expanded` dentro de scroll ni shells genéricos.
