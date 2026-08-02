#!/usr/bin/env bash
# Build + run ActionsBar, rebuild+relaunch on source changes.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v fswatch >/dev/null 2>&1; then
  echo "fswatch required: brew install fswatch" >&2
  exit 1
fi

pid=""

cleanup() {
  [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

run() {
  [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
  if swift build; then
    .build/debug/ActionsBar &
    pid=$!
  fi
}

run
fswatch -o -l 0.5 Sources Package.swift | while read -r _; do
  echo "--- change detected, rebuilding ---"
  run
done
