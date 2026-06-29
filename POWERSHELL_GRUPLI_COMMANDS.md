# Grupli v16.32.4 — comandos PowerShell

Versión estable basada en v16.32.2 + dependencias web corregidas:

- `supabase_flutter: 2.8.3`
- `app_links: 6.4.1`

## Comprobar dependencias clave

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
Select-String -Path ".\pubspec.yaml" -Pattern "supabase_flutter|app_links"
```

Debe salir:

```text
supabase_flutter: 2.8.3
app_links: 6.4.1
```

## Subir solo si la carpeta está limpia y actualizada

```powershell
cd "$env:USERPROFILE\Desktop\grupliv2"
git status
```

No usar `push --force`.
