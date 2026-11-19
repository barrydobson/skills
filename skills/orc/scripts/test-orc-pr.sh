#!/usr/bin/env bash
# Self-check for orc-pr with stub gh and hc. Run: skills/orc/scripts/test-orc-pr.sh (needs jq)
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The stub gh logs its arguments, then answers pr list from prs.json through its --jq filter, as gh does.
# The stub hc logs its arguments.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<EOF
#!/bin/sh
printf '%s|' "\$@" >"$tmp/gh.log"
while [ "\$1" != --jq ]; do shift; done
jq -r "\$2" "$tmp/prs.json"
EOF
printf '#!/bin/sh\nprintf "%%s|" "$@" > "%s/hc.log"\n' "$tmp" >"$tmp/bin/hc"
chmod +x "$tmp/bin/gh" "$tmp/bin/hc"
export PATH="$tmp/bin:$PATH" HC_TERMINAL_ID=t9
pr() { echo "{\"state\":\"$1\",\"url\":\"https://github.com/example-org/example-repo/pull/$2\"}"; }
run() { # run <expected exit> <expected output> <what> <args...>
  local want="$1" out="$2" what="$3" code
  shift 3
  : >"$tmp/hc.log"
  set +e
  got="$(./orc-pr "$@" 2>/dev/null)"
  code=$?
  set -e
  [ "$code" = "$want" ] && [ "$got" = "$out" ] || fail "$what: exit $code, output '$got'"
}

echo "[$(pr MERGED 7)]" >"$tmp/prs.json"
run 0 "MERGED https://github.com/example-org/example-repo/pull/7" "merged" "Acme/Widgets#12" example-org/example-repo
[ "$(cat "$tmp/gh.log")" = 'pr|list|-R|example-org/example-repo|--head|worktree-acme-widgets-12|--state|all|--json|state,url|--jq|(map(select(.state == "MERGED")) + .) | first // empty | "\(.state) \(.url)"|' ] || fail "gh call: $(cat "$tmp/gh.log")"
[ "$(cat "$tmp/hc.log")" = "label|t9|orch.pr=https://github.com/example-org/example-repo/pull/7|" ] || fail "merged label: $(cat "$tmp/hc.log")"

echo "[$(pr CLOSED 6),$(pr MERGED 8)]" >"$tmp/prs.json"
run 0 "MERGED https://github.com/example-org/example-repo/pull/8" "merged wins over closed" ABC-12 example-org/example-repo

echo "[$(pr OPEN 9)]" >"$tmp/prs.json"
run 1 "OPEN https://github.com/example-org/example-repo/pull/9" "open" ABC-12 example-org/example-repo
[ "$(cat "$tmp/hc.log")" = "label|t9|orc.stopped=PR not merged|" ] || fail "open label: $(cat "$tmp/hc.log")"

echo "[]" >"$tmp/prs.json"
run 2 "" "no PR" ABC-12 example-org/example-repo
run 2 "" "bad repo" ABC-12 example-repo
run 2 "" "empty key" "" example-org/example-repo
run 2 "" "missing repo" ABC-12
[ -s "$tmp/hc.log" ] && fail "a rejected call labelled the head: $(cat "$tmp/hc.log")"

shellcheck -x orc-pr test-orc-pr.sh
echo "ok orc-pr"
