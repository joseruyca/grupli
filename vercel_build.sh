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
  if [ -z "${SUPABASE_URL:-}" ]; then
    echo "ERROR: Missing SUPABASE_URL in Vercel Environment Variables."
    exit 1
  fi

  if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
    echo "ERROR: Missing SUPABASE_ANON_KEY in Vercel Environment Variables."
    exit 1
  fi

  echo "Building Grupli web for Vercel..."
  rm -rf build .dart_tool
  flutter pub get
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=APP_BASE_URL="${APP_BASE_URL:-https://grupli.vercel.app}" \
    --dart-define=OSM_GEOCODER_ENDPOINT="${OSM_GEOCODER_ENDPOINT:-}" \
    --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY:-}" \
    --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID:-}" \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID:-}" \
    --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-}" \
    --dart-define=FIREBASE_VAPID_KEY="${FIREBASE_VAPID_KEY:-}"

  if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html was not generated."
    exit 1
  fi

  echo "Grupli web build completed successfully."
  exit 0
fi

echo "ERROR: Unknown command: $COMMAND"
exit 1
