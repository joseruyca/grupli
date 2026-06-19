# v16.25.3 Web Safe Restore

Base: v16.25.2 tournament-results-by-sport.

Changes:
- Removed Firebase Core / Firebase Messaging from the Flutter dependency graph.
- Removed app_links from the Flutter dependency graph.
- PushNotificationService is temporarily a safe no-op.
- External deep links are temporarily disabled to avoid web plugin bootstrap crashes.
- Supabase, groups, agenda, finances and tournaments remain unchanged.

Reason:
The web build deployed successfully but the browser crashed at runtime with `Cannot read properties of undefined (reading 'init')` and a blank page. This rescue removes optional web plugins from startup and keeps the web app independent from Firebase configuration.
