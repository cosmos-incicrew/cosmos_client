#!/usr/bin/env bash
# Vercel 자동 배포용 빌드 스크립트.
#
# Vercel 은 Flutter 를 기본 지원하지 않으므로, 빌드 단계에서 Flutter SDK 를 내려받아
# 웹을 빌드한다. dart-define 값은 Vercel 프로젝트 환경변수에서 주입된다
# (SUPABASE_URL / SUPABASE_ANON_KEY / GOOGLE_WEB_CLIENT_ID / API_BASE_URL).
# 출력은 build/web (Vercel Output Directory 와 일치).
set -euo pipefail

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
fi
export PATH="$PATH:$(pwd)/_flutter/bin"

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-}"
