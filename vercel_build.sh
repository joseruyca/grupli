#!/usr/bin/env bash
set -e

export FLUTTER_HOME="$HOME/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

flutter --version
flutter config --enable-web

if [ "$1" = "install" ]; then
  flutter pub get
fi

if [ "$1" = "build" ]; then
  flutter pub get
  flutter build web --release \
    --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
fi
