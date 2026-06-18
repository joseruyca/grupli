#!/usr/bin/env bash
set -eo pipefail

COMMAND="${1:-build}"

export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

if [ ! -d "$FLUTTER_HOME/.git" ]; then
  echo "Installing Flutter stable..."
  rm -rf "$FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

flutter --version
flutter config --enable-web --no-analytics

if [ "$COMMAND" = "install" ]; then
  echo "Installing Flutter dependencies..."
  flutter pub get
  exit 0
fi

if [ "$COMMAND" = "build" ]; then
  echo "Building Grupli web for Vercel..."
  echo "Vercel env check: only variable names are printed; values stay hidden."

  DART_DEFINES=()

  add_define_from_aliases() {
    target="$1"
    shift
    for name in "$@"; do
      value="${!name:-}"
      if [ -n "$value" ]; then
        echo "- $target: OK from $name"
        DART_DEFINES+=("--dart-define=$target=$value")
        return 0
      fi
    done
    echo "- $target: not provided; build continues without hardcoded fallback"
    return 0
  }

  resolve_app_base_url() {
    for name in APP_BASE_URL VITE_APP_BASE_URL NEXT_PUBLIC_APP_BASE_URL; do
      value="${!name:-}"
      if [ -n "$value" ]; then
        echo "- APP_BASE_URL: OK from $name"
        DART_DEFINES+=("--dart-define=APP_BASE_URL=$value")
        return 0
      fi
    done
    echo "- APP_BASE_URL: using public default https://grupli.vercel.app"
    DART_DEFINES+=("--dart-define=APP_BASE_URL=https://grupli.vercel.app")
  }

  add_define_from_aliases SUPABASE_URL SUPABASE_URL EXPO_PUBLIC_SUPABASE_URL VITE_SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL FLUTTER_SUPABASE_URL
  add_define_from_aliases SUPABASE_ANON_KEY SUPABASE_ANON_KEY SUPABASE_PUBLISHABLE_KEY EXPO_PUBLIC_SUPABASE_ANON_KEY EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY VITE_SUPABASE_ANON_KEY VITE_SUPABASE_PUBLISHABLE_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY SUPABASE_KEY FLUTTER_SUPABASE_ANON_KEY FLUTTER_SUPABASE_PUBLISHABLE_KEY
  resolve_app_base_url
  add_define_from_aliases OSM_GEOCODER_ENDPOINT OSM_GEOCODER_ENDPOINT VITE_OSM_GEOCODER_ENDPOINT NEXT_PUBLIC_OSM_GEOCODER_ENDPOINT
  add_define_from_aliases FIREBASE_API_KEY FIREBASE_API_KEY VITE_FIREBASE_API_KEY NEXT_PUBLIC_FIREBASE_API_KEY
  add_define_from_aliases FIREBASE_APP_ID FIREBASE_APP_ID VITE_FIREBASE_APP_ID NEXT_PUBLIC_FIREBASE_APP_ID
  add_define_from_aliases FIREBASE_MESSAGING_SENDER_ID FIREBASE_MESSAGING_SENDER_ID VITE_FIREBASE_MESSAGING_SENDER_ID NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
  add_define_from_aliases FIREBASE_PROJECT_ID FIREBASE_PROJECT_ID VITE_FIREBASE_PROJECT_ID NEXT_PUBLIC_FIREBASE_PROJECT_ID
  add_define_from_aliases FIREBASE_VAPID_KEY FIREBASE_VAPID_KEY VITE_FIREBASE_VAPID_KEY NEXT_PUBLIC_FIREBASE_VAPID_KEY

  rm -rf build .dart_tool
  flutter pub get
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run "${DART_DEFINES[@]}"

  if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html was not generated."
    exit 1
  fi

  echo "Grupli web build completed successfully."
  exit 0
fi

echo "ERROR: Unknown command: $COMMAND"
exit 1
