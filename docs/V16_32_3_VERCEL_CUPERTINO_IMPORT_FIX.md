# v16.32.3 — Vercel Cupertino import fix

Corrección mínima para Vercel: `CupertinoPageTransitionsBuilder` requiere el import explícito de `package:flutter/cupertino.dart` en `lib/main.dart` para compilar correctamente en el entorno Linux de Vercel.

No se toca SQL, pagos, Supabase, `.env` ni lógica de producto.
