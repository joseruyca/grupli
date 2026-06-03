# V15.7 — Rediseño visual azul + foto de grupo

Objetivo: reducir ruido visual, mejorar jerarquía y dar identidad propia a cada grupo.

## Cambios principales

- Paleta movida a tonos azules premium.
- Inicio del grupo simplificado.
- Eliminada la sección de acciones rápidas del Inicio.
- Hero del grupo con soporte de foto/cover.
- Mis grupos muestra la foto del grupo cuando existe.
- Ajustes del grupo permite cambiar o quitar la foto.
- Tarjeta principal de evento más limpia y directa.
- Textos del dashboard reducidos.
- Torneos simplificado: fuera duplicaciones de crear rápido/flujo recomendado en la pantalla principal.
- Finanzas con textos más cortos y visual menos pesado.
- Cards, sombras y bordes refinados.

## SQL requerido

Ejecutar `supabase/patch_v15_7_visual_group_cover.sql` para añadir:

- `groups.cover_url`
- bucket público `group-covers`
- políticas de Storage para que solo owner/admin puedan subir/editar fotos del grupo
- `get_my_groups()` actualizado para devolver `cover_url`

## Nota

La funcionalidad existente se mantiene. Esta fase se centra en claridad visual y foto de grupo.
