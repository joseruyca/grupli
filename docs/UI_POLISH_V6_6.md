# Grupli v6.6 UI polish

Objetivo: acercar la app al mockup elegido sin romper la lógica.

## Mejoras

- Home de grupos más clara y más parecida a app real.
- Estado vacío útil.
- Carga visible.
- Error visible.
- Cards de grupo con jerarquía más clara.
- Crear grupo más guiado:
  - Deportivo
  - Social
  - Otro
  - Privado / Público
  - Días habituales
  - Hora
  - Ubicación
  - Mínimo de personas
- `create_group_atomic` incluido también en `all_in_one.sql`.

## Regla

No seguir con nuevas fases hasta confirmar:
1. Se ve la home después del login.
2. Se puede crear un grupo.
3. El grupo aparece en la lista.
4. Al tocar el grupo se abre el detalle.
