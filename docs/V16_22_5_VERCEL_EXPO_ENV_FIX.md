# v16.22.5 - Vercel Expo env alias fix

This patch fixes Vercel builds that already use legacy Expo-style environment variable names:

- EXPO_PUBLIC_SUPABASE_URL
- EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY

The build script maps them safely to Flutter dart-defines:

- SUPABASE_URL
- SUPABASE_ANON_KEY

No Supabase credentials are hardcoded in the frontend. No service_role key is used.
