# v16.32.7 - Web runtime rescue

- Startup now catches initialization failures instead of leaving a blank page.
- Supabase session recovery has a timeout so the web shell cannot stay loading forever.
- Web index shows a visible fallback while Flutter loads and a visible error if bootstrap fails.
- Old Flutter/Grupli caches and service workers are cleared before loading the current bundle.
- Vercel config uses filesystem-first routing before SPA fallback.
- No SQL, payments or secrets changed.
