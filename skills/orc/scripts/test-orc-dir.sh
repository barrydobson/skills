#!/usr/bin/env bash
# Self-check for orc-dir. Run: skills/orc/scripts/test-orc-dir.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

real="$(cd "$tmp" && pwd -P)"
out="$(TMPDIR="$tmp/" ./orc-dir "Acme/Widgets#12")"
[ "$out" = "$real/orc-acme-widgets-12" ] || fail "path: $out"
[ -d "$out/rollback" ] || fail "no rollback directory"
[ "$(stat -f %Lp "$out" 2>/dev/null || stat -c %a "$out")" = 700 ] || fail "run directory is not private"
[ "$(TMPDIR="$tmp" ./orc-dir "Acme/Widgets#12")" = "$out" ] || fail "second run gave another path"

./orc-dir "" 2>/dev/null && fail "empty key accepted"
./orc-dir 2>/dev/null && fail "missing key accepted"
TMPDIR='' ./orc-dir ABC-1 2>/dev/null && fail "ran without TMPDIR"

shellcheck -x orc-dir test-orc-dir.sh
echo "ok orc-dir"
