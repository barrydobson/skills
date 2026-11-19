#!/usr/bin/env bash
# Self-check for orc-ci with a stub gh that plays one scenario. Run: skills/orc/scripts/test-orc-ci.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The stub answers pr view from view.json and required checks from required (404 when empty).
# The nth pr checks call answers checks.n, or the last checks file once the sequence runs out;
# a checks file holding "none" answers like gh with no checks on the PR.
mkdir -p "$tmp/bin"
cat >"$tmp/bin/gh" <<EOF
#!/bin/sh
s="$tmp/s"
case "\$1 \$2" in
  "pr view")
    case "\$*" in *number*) [ -f "\$s/unknown" ] && { echo "GraphQL: Could not resolve to a PullRequest" >&2; exit 1; }; echo '{"number":1}' ;;
      *) cat "\$s/view.json" ;; esac ;;
  "pr checks")
    c=\$((\$(cat "\$s/count") + 1)); echo \$c >"\$s/count"
    f="\$s/checks.\$c"; [ -f "\$f" ] || f="\$(ls "\$s"/checks.* | sort -t. -k2 -n | tail -1)"
    [ "\$(cat "\$f")" = none ] && { echo "no checks reported on the 'x' branch" >&2; exit 1; }
    cat "\$f" ;;
  api\ repos/*/rules/*)
    [ -s "\$s/required" ] && { cat "\$s/required"; exit 0; }
    echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  *) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
esac
EOF
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"
url=https://github.com/example-org/example-repo/pull/7

scenario() {
  rm -rf "$tmp/s" && mkdir "$tmp/s" && echo 0 >"$tmp/s/count" && : >"$tmp/s/required"
  echo "{\"state\":\"${1:-OPEN}\",\"headRefOid\":\"abc1234def\",\"baseRefName\":\"main\",\"mergeStateStatus\":\"${2:-CLEAN}\"}" >"$tmp/s/view.json"
}
checks() { echo "$2" >"$tmp/s/checks.$1"; }
row() { echo "{\"name\":\"$1\",\"bucket\":\"$2\",\"link\":\"https://ci.example/$1\"}"; }
expect() { # expect <exit code> <output> <what>
  set +e
  out="$(./orc-ci --interval 0 "$url" 2>/dev/null)"
  code=$?
  set -e
  [ "$code" = "$1" ] && [ "$out" = "$2" ] || fail "$3: exit $code, output '$out'"
}

scenario && checks 1 "[$(row lint pending)]" && checks 2 "[$(row lint pass)]"
expect 0 "green on abc1234: 1/1 checks passed" "green after a stable poll"
[ "$(cat "$tmp/s/count")" = 3 ] || fail "green before two identical polls: $(cat "$tmp/s/count") polls"

scenario && echo build >"$tmp/s/required"
checks 1 "[$(row lint pass)]" && checks 2 "[$(row lint pass)]" && checks 3 "[$(row lint pass),$(row build pass)]"
expect 0 "green on abc1234: 1/1 required checks passed" "required check that starts late"
[ "$(cat "$tmp/s/count")" = 4 ] || fail "green before the required check ran: $(cat "$tmp/s/count") polls"

scenario && checks 1 "[$(row lint pass),$(row test fail)]"
expect 1 "check failed: test https://ci.example/test" "failed check"

scenario && checks 1 "[$(row test pass),$(row test cancel)]"
expect 1 "check failed: test https://ci.example/test" "duplicate names take the worst bucket"

scenario && echo build >"$tmp/s/required" && checks 1 "[$(row lint fail),$(row build pending)]"
checks 2 "[$(row lint fail),$(row build pass)]"
expect 0 "green on abc1234: 1/1 required checks passed" "a failing check that is not required"

scenario && checks 1 none
expect 0 "green on abc1234: no checks reported and none required" "repo with no CI"
[ "$(cat "$tmp/s/count")" = 3 ] || fail "no-CI call after $(cat "$tmp/s/count") polls"

scenario MERGED && expect 0 "merged: $url" "merged"
scenario CLOSED && expect 1 "closed without merging: $url" "closed"
scenario OPEN DIRTY && expect 1 "merge state is DIRTY: the branch conflicts with main, rebase it" "conflict"

scenario
./orc-ci --interval 0 42 >/dev/null 2>&1 && fail "bare PR number accepted"
touch "$tmp/s/unknown"
set +e
./orc-ci --interval 0 "$url" >/dev/null 2>&1
code=$?
set -e
[ "$code" = 2 ] || fail "unknown PR: exit $code"

shellcheck test-orc-ci.sh
echo "ok orc-ci"
