# Grupli v16.32.3 - web recovery baseline

This package keeps the v16.32.2 app code and tournament improvements, but applies the proven web dependency compatibility fix:

- `supabase_flutter: 2.8.3`
- `app_links: 6.4.1`

Reason: `supabase_flutter 2.8.3` requires `app_links >=3.5.0 <7.0.0`, so `app_links ^7.0.0` cannot resolve.

No application logic, Supabase SQL, Firebase code, tournament code, or Vercel environment variables were changed in this recovery package.
