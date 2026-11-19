#!/usr/bin/env bash
# Self-check for orc-label with a stub hc that logs its arguments. Run: skills/orc/scripts/test-orc-label.sh
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
export PATH="$tmp/bin:$PATH" HC_TERMINAL_ID=t9
log() { cat "$tmp/hc.log"; }

./orc-label phase review
[[ "$(log)" =~ ^label\|t9\|bob\.phase=review\|bob\.at\.review=[0-9]{10}\|bob\.stopped=\|$ ]] || fail "phase review: $(log)"

./orc-label phase spec ABC-12
[[ "$(log)" =~ ^label\|t9\|bob\.phase=spec\|bob\.at\.spec=[0-9]+\|bob\.stopped=\|bob\.ticket=ABC-12\|bob\.round=0\|$ ]] || fail "phase spec with key: $(log)"

./orc-label stop "AC4 waits on a scan"
[ "$(log)" = "label|t9|bob.stopped=AC4 waits on a scan|" ] || fail "stop: $(log)"

./orc-label round 2
[ "$(log)" = "label|t9|bob.round=2|" ] || fail "round: $(log)"

./orc-label pr https://github.com/example-org/example-repo/pull/42
[ "$(log)" = "label|t9|orch.pr=https://github.com/example-org/example-repo/pull/42|" ] || fail "pr: $(log)"

: >"$tmp/hc.log"
./orc-label phase reveiw 2>/dev/null && fail "unknown phase accepted"
./orc-label phase "spec build" 2>/dev/null && fail "two phases accepted"
./orc-label stop "" 2>/dev/null && fail "empty stop accepted"
./orc-label round two 2>/dev/null && fail "non-numeric round accepted"
./orc-label pr 42 2>/dev/null && fail "bare PR number accepted"
./orc-label nope 2>/dev/null && fail "unknown subcommand accepted"
HC_TERMINAL_ID='' ./orc-label round 1 2>/dev/null && fail "ran without HC_TERMINAL_ID"
[ -s "$tmp/hc.log" ] && fail "a rejected call reached hc: $(log)"

shellcheck orc-label test-orc-label.sh
echo "ok orc-label"
