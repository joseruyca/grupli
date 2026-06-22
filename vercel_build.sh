#!/usr/bin/env bash
set -eo pipefail

COMMAND="${1:-build}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.7}"
export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

install_flutter() {
  echo "Installing pinned Flutter $FLUTTER_VERSION..."
  rm -rf "$FLUTTER_HOME"

  ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  TMP_ARCHIVE="/tmp/flutter_${FLUTTER_VERSION}.tar.xz"

  if command -v curl >/dev/null 2>&1; then
    echo "Downloading Flutter SDK archive..."
    if curl -fL --retry 3 --retry-delay 2 -o "$TMP_ARCHIVE" "$ARCHIVE_URL"; then
      tar -xf "$TMP_ARCHIVE" -C "$HOME"
      rm -f "$TMP_ARCHIVE"
      return 0
    fi
  fi

  echo "Archive download failed. Falling back to Git tag $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION" "$FLUTTER_HOME"
}

ensure_flutter() {
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    install_flutter
    return 0
  fi

  if ! "$FLUTTER_HOME/bin/flutter" --version | grep -q "Flutter $FLUTTER_VERSION"; then
    echo "Cached Flutter version does not match $FLUTTER_VERSION. Reinstalling..."
    install_flutter
  fi
}

ensure_flutter
flutter --version
flutter config --enable-web --no-analytics

if [ "$COMMAND" = "install" ]; then
  echo "Installing Flutter dependencies..."
  flutter pub get
  exit 0
fi

if [ "$COMMAND" = "build" ]; then
  echo "Building Grupli web for Vercel with pinned Flutter $FLUTTER_VERSION..."
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
  flutter pub get

  echo "Running Flutter analyze in Vercel..."
  flutter analyze --no-fatal-infos --no-fatal-warnings

  echo "Trying Flutter web build with --no-wasm-dry-run..."
  set +e
  flutter build web --release --no-tree-shake-icons --no-wasm-dry-run "${DART_DEFINES[@]}"
  build_status=$?
  set -e

  if [ "$build_status" -ne 0 ]; then
    echo "First web build failed. Retrying without --no-wasm-dry-run..."
    rm -rf build
    flutter build web --release --no-tree-shake-icons "${DART_DEFINES[@]}"
  fi

  if [ ! -f "build/web/index.html" ]; then
    echo "ERROR: build/web/index.html was not generated."
    exit 1
  fi

  echo "Grupli web build completed successfully."
  exit 0
fi

echo "ERROR: Unknown command: $COMMAND"
exit 1
