# v16.32.6 — Web deploy rescue

Restores the web entry/deploy behavior from the last known stable base while preserving current tournament and premium work.

Changes:
- Restored stable web/index.html from v16.25.2.
- Restored stable vercel.json and vercel_build.sh from v16.25.2.
- Removed custom PageTransitionsTheme/Cupertino transition import from main.dart to avoid web/runtime divergence.
- Kept .env ignored and not included.
- No SQL changes.
- No payments.
- No secrets hardcoded.
