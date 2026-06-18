# v16.26.1 Web Safe Restore

Base: v16.26 premium fluidity supplied as known-working reference.

This rescue build keeps the v16.26 product code and removes startup-time web plugins that can crash before the app paints when dependency versions or web configuration drift:

- removed firebase_core and firebase_messaging from the app build
- removed app_links from the app build
- kept Supabase runtime configuration through dart-define
- kept Vercel build flow from the stable reference
- added .gitattributes to keep LF endings for Vercel shell scripts

Push notifications and mobile app links are disabled in this restore build. They should be reintroduced later with platform-specific imports after the web deployment is stable.
