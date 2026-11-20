#!/usr/bin/env bash
# Self-check for flow-dir. Run: skills/flow/scripts/test-flow-dir.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

real="$(cd "$tmp" && pwd -P)"
out="$(TMPDIR="$tmp/" ./flow-dir "Acme/Widgets#12")"
[ "$out" = "$real/flow-acme-widgets-12" ] || fail "path: $out"
[ -d "$out" ] || fail "no run directory"
[ "$(stat -f %Lp "$out" 2>/dev/null || stat -c %a "$out")" = 700 ] || fail "run directory is not private"
[ "$(TMPDIR="$tmp" ./flow-dir "Acme/Widgets#12")" = "$out" ] || fail "second run gave another path"

./flow-dir "" 2>/dev/null && fail "empty key accepted"
./flow-dir 2>/dev/null && fail "missing key accepted"
TMPDIR='' ./flow-dir ABC-1 2>/dev/null && fail "ran without TMPDIR"

shellcheck -x flow-dir test-flow-dir.sh
echo "ok flow-dir"
