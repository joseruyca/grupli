# v16.22.4 — Vercel build no-env-block

Vercel build now follows the simple deployment flow again. It does not fail the build when Supabase variables are missing.

Security note: no Supabase URL/key fallback is hardcoded in frontend. If Vercel variables are absent, the web build can deploy but the app will show the safe configuration screen at runtime.

The script accepts common aliases for Supabase and Firebase environment variables and passes them through `--dart-define` when present. Values are never printed in logs.
