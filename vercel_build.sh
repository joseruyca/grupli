#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-build}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
export FLUTTER_HOME="$HOME/flutter-$FLUTTER_VERSION"
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

install_flutter() {
  echo "Installing Flutter $FLUTTER_VERSION from official Git tag..."
  rm -rf "$FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION" "$FLUTTER_HOME"
}

ensure_flutter() {
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    install_flutter
    return 0
  fi

  if ! "$FLUTTER_HOME/bin/flutter" --version | grep -q "Flutter $FLUTTER_VERSION"; then
    echo "Cached Flutter version mismatch. Reinstalling Flutter $FLUTTER_VERSION..."
    install_flutter
  fi
}

pub_get_reproducible() {
  if [ -f "pubspec.lock" ]; then
    echo "Using committed pubspec.lock."
    flutter pub get --enforce-lockfile
  else
    echo "WARNING: pubspec.lock not found. Running flutter pub get without lockfile."
    flutter pub get
  fi
}

ensure_flutter
flutter --version
flutter config --enable-web --no-analytics

if [ "$COMMAND" = "install" ]; then
  echo "Installing Flutter dependencies..."
  pub_get_reproducible
  exit 0
fi

if [ "$COMMAND" = "build" ]; then
  echo "Building Grupli web with Flutter $FLUTTER_VERSION..."
  echo "Vercel env check: only variable names are printed; values stay hidden."

  DART_DEFINES=()

  add_define_from_aliases() {
    local target="$1"
    shift
    local name=""
    local value=""

    for name in "$@"; do
      value="${!name:-}"
      if [ -n "$value" ]; then
        echo "- $target: OK from $name"
        DART_DEFINES+=("--dart-define=$target=$value")
        return 0
      fi
    done

    echo "- $target: not provided"
    return 0
  }

  resolve_app_base_url() {
    local name=""
    local value=""

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
  flutter clean
  pub_get_reproducible

  echo "Running Flutter analyze..."
  flutter analyze --no-fatal-infos --no-fatal-warnings

  echo "Building Flutter web..."
  set +e
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run "${DART_DEFINES[@]}"
  build_status=$?
  set -e

  if [ "$build_status" -ne 0 ]; then
    echo "Build with --no-wasm-dry-run failed. Retrying without it..."
    rm -rf build
    flutter build web --release --no-tree-shake-icons "${DART_DEFINES[@]}"
  fi

  if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html was not generated."
    exit 1
  fi

  if [ ! -f "build/web/main.dart.js" ]; then
    echo "ERROR: build/web/main.dart.js was not generated."
    exit 1
  fi

  echo "Grupli web build completed successfully."
  exit 0
fi

echo "ERROR: Unknown command: $COMMAND"
exit 1
