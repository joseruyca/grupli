# Grupli v12.10 — Fix crear grupo RPC

## Problema

Supabase tenía más de una función `create_group_atomic` guardada:

- `create_group_atomic(p_name text)`
- `create_group_atomic(p_name text, p_type text, p_privacy text, p_default_days text, p_default_time text, p_default_location text, p_min_people integer)`

Como una de las versiones antiguas tenía parámetros con valores por defecto, PostgREST no sabía cuál ejecutar cuando Flutter llamaba a:

```dart
rpc('create_group_atomic', params: {'p_name': name})
```

Por eso aparecía:

```text
PGRST203 Could not choose the best candidate function
```

## Solución

Ejecutar:

```sql
supabase/patch_v12_10_create_group_rpc_overload_fix.sql
```

Ese parche elimina todas las versiones antiguas y deja solo una función oficial:

```sql
create_group_atomic(p_name text)
```

## Regla de producto

Crear grupo debe seguir siendo simple:

- nombre
- privado siempre
- sin días
- sin hora
- sin público/privado
- sin mínimo de personas

Los eventos son los que tienen fecha, hora, ubicación, mínimo y asistencia.
