#!/usr/bin/env bash
# Self-check for orc-stop with a stub hc that logs each call. Run: skills/orc/scripts/test-orc-stop.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The stub logs each call on one line and answers get from a list of live names.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/hc" <<EOF
#!/bin/sh
echo "\$*" >>"$tmp/hc.log"
[ "\$1" = get ] && { grep -qx "\$2" "$tmp/live"; exit \$?; }
exit 0
EOF
chmod +x "$tmp/bin/hc"
export PATH="$tmp/bin:$PATH"
log() { cat "$tmp/hc.log"; }

printf 'abc-12\nsol-abc-12\n' >"$tmp/live"
: >"$tmp/hc.log"
./orc-stop ABC-12
[ "$(grep -v '^get ' "$tmp/hc.log")" = "kill abc-12
rm abc-12
kill sol-abc-12
rm sol-abc-12" ] || fail "stop all: $(log)"
[ "$(grep -c '^get ' "$tmp/hc.log")" = 5 ] || fail "stop all did not check every role: $(log)"

printf 'spec-abc-12\nabc-12\n' >"$tmp/live"
: >"$tmp/hc.log"
./orc-stop ABC-12 spec
[ "$(log)" = "get spec-abc-12
kill spec-abc-12
rm spec-abc-12" ] || fail "stop one role: $(log)"

: >"$tmp/hc.log"
./orc-stop ABC-12 spec nope 2>/dev/null && fail "unknown role accepted"
./orc-stop "" 2>/dev/null && fail "empty key accepted"
./orc-stop 2>/dev/null && fail "missing key accepted"
[ -s "$tmp/hc.log" ] && fail "a rejected call reached hc: $(log)"

shellcheck -x orc-stop test-orc-stop.sh
echo "ok orc-stop"
