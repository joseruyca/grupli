#!/usr/bin/env bash
set -euxo pipefail

export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export CI=true

if [ ! -d "$FLUTTER_HOME/.git" ]; then
  rm -rf "$FLUTTER_HOME"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

flutter --version
flutter config --enable-web --no-analytics

if [ "$1" = "install" ]; then
  flutter pub get
fi

if [ "$1" = "build" ]; then
  flutter clean
  rm -rf build .dart_tool
  flutter pub get
  flutter analyze --no-fatal-infos --no-fatal-warnings
  flutter build web --release --no-tree-shake-icons \
    --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
fi
