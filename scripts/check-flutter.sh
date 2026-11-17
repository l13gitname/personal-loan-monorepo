#!/usr/bin/env bash
# One command to verify the Flutter app locally; paste the output back if something fails.
# Usage (from repo root):  ./scripts/check-flutter.sh
set -euo pipefail

cd "$(dirname "$0")/../apps/consumer_app"

step() { printf '\n=== %s ===\n' "$1"; }

step "flutter --version";        flutter --version
step "pub get";                  flutter pub get
step "build_runner";             dart run build_runner build --delete-conflicting-outputs
step "format check";             dart format --output=none --set-exit-if-changed lib test integration_test
step "analyze";                  flutter analyze
step "unit + widget tests";      flutter test

echo
echo "All checks passed."
