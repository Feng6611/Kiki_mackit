#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-test}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

case "$MODE" in
  test|--test|--verify|verify)
    swift test
    ;;
  build|--build)
    swift build
    ;;
  *)
    echo "usage: $0 [test|build]" >&2
    exit 2
    ;;
esac

