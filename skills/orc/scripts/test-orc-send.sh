#!/usr/bin/env bash
# Self-check for orc-send with a stub hc that logs its arguments. Run: skills/orc/scripts/test-orc-send.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

mkdir -p "$tmp/bin"
printf '#!/bin/sh\nprintf "%%s|" "$@" > "%s/hc.log"\n' "$tmp" >"$tmp/bin/hc"
chmod +x "$tmp/bin/hc"
export PATH="$tmp/bin:$PATH"
log() { cat "$tmp/hc.log"; }

# Backticks and $ in the message reach hc as text, never run.
# shellcheck disable=SC2016
printf 'Fix S1.\nRun `rm -rf $HOME` never.\n' | ./orc-send build "acme/widgets#12"
# shellcheck disable=SC2016
[ "$(log)" = 'send|acme-widgets-12|Fix S1.
Run `rm -rf $HOME` never.|' ] || fail "build send: $(log)"

echo "Round 2." | ./orc-send reviewer ABC-12
[ "$(log)" = "send|sol-abc-12|Round 2.|" ] || fail "reviewer send: $(log)"

echo "yes" | ./orc-send spec ABC-12
[ "$(log)" = "send|spec-abc-12|yes|" ] || fail "spec send: $(log)"

: >"$tmp/hc.log"
echo x | ./orc-send ci ABC-12 2>/dev/null && fail "send to ci accepted"
echo x | ./orc-send nope ABC-12 2>/dev/null && fail "unknown role accepted"
echo x | ./orc-send build "" 2>/dev/null && fail "empty key accepted"
echo x | ./orc-send build 2>/dev/null && fail "missing key accepted"
./orc-send build ABC-12 </dev/null 2>/dev/null && fail "empty message accepted"
[ -s "$tmp/hc.log" ] && fail "a rejected call reached hc: $(log)"

shellcheck -x orc-send test-orc-send.sh
echo "ok orc-send"
