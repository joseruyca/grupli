#!/usr/bin/env bash
set -eo pipefail

COMMAND="${1:-build}"

export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

read_env_alias() {
  for name in "$@"; do
    value="${!name:-}"
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  done
  return 0
}

print_env_presence() {
  echo "Vercel env check (names only, values hidden):"
  for name in \
    SUPABASE_URL VITE_SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL FLUTTER_SUPABASE_URL \
    SUPABASE_ANON_KEY VITE_SUPABASE_ANON_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY SUPABASE_KEY \
    APP_BASE_URL VITE_APP_BASE_URL NEXT_PUBLIC_APP_BASE_URL; do
    value="${!name:-}"
    if [ -n "$value" ]; then
      echo "- $name: OK"
    else
      echo "- $name: missing"
    fi
  done
}

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
  RESOLVED_SUPABASE_URL="$(read_env_alias SUPABASE_URL VITE_SUPABASE_URL NEXT_PUBLIC_SUPABASE_URL FLUTTER_SUPABASE_URL)"
  RESOLVED_SUPABASE_ANON_KEY="$(read_env_alias SUPABASE_ANON_KEY VITE_SUPABASE_ANON_KEY NEXT_PUBLIC_SUPABASE_ANON_KEY SUPABASE_KEY)"
  RESOLVED_APP_BASE_URL="$(read_env_alias APP_BASE_URL VITE_APP_BASE_URL NEXT_PUBLIC_APP_BASE_URL)"

  if [ -z "$RESOLVED_APP_BASE_URL" ]; then
    RESOLVED_APP_BASE_URL="https://grupli.vercel.app"
  fi

  if [ -z "$RESOLVED_SUPABASE_URL" ] || [ -z "$RESOLVED_SUPABASE_ANON_KEY" ]; then
    print_env_presence
    echo "ERROR: Missing Supabase environment variables for Vercel build."
    echo "Required: SUPABASE_URL and SUPABASE_ANON_KEY."
    echo "Also accepted aliases: VITE_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_URL and VITE_SUPABASE_ANON_KEY / NEXT_PUBLIC_SUPABASE_ANON_KEY."
    echo "Check that the variables are configured in this exact Vercel project and environment (Production/Preview)."
    exit 1
  fi

  echo "Building Grupli web for Vercel..."
  rm -rf build .dart_tool
  flutter pub get
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run \
    --dart-define=SUPABASE_URL="$RESOLVED_SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$RESOLVED_SUPABASE_ANON_KEY" \
    --dart-define=APP_BASE_URL="$RESOLVED_APP_BASE_URL" \
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
