# v16.32.8 — Disable Firebase Messaging runtime crash

This build disables Firebase Messaging at runtime and removes the Firebase web plugins from the Flutter dependency graph.

Reason: the deployed web app loaded the HTML and then crashed with:

- `Null check operator used on a null value`
- `Cannot read properties of undefined (reading 'init')`

The crash happened after Flutter bootstrap, which points to a runtime plugin initialization issue rather than a Vercel build failure.

Push notifications were not production-ready yet because Android was already warning that `google-services.json` was missing. Keeping Firebase Messaging in the web bundle was therefore higher risk than value.

What changed:

- Removed `firebase_core` from `pubspec.yaml`.
- Removed `firebase_messaging` from `pubspec.yaml`.
- Removed Firebase imports from `main.dart`.
- Replaced `PushNotificationService` with a safe no-op implementation.
- Kept all tournament, agenda, finance and premium work intact.

Future reintroduction:

Push should be reintroduced as a dedicated phase with platform-specific QA, Firebase config files, VAPID key validation, and no web runtime crash risk.
