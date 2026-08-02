#!/usr/bin/env bash
# Build + run ActionsBar, rebuild+relaunch on source changes.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v fswatch >/dev/null 2>&1; then
  echo "fswatch required: brew install fswatch" >&2
  exit 1
fi

cleanup() {
  pkill -f "ActionsBar.app/Contents/MacOS/ActionsBar" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

run() {
  pkill -f "ActionsBar.app/Contents/MacOS/ActionsBar" 2>/dev/null || true
  if ./Scripts/build-app.sh; then
    open ActionsBar.app
  fi
}

run
fswatch -o -l 0.5 Sources Package.swift | while read -r _; do
  echo "--- change detected, rebuilding ---"
  run
done
