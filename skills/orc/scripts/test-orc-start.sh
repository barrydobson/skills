#!/usr/bin/env bash
# Self-check for orc-start with a stub hc that logs each call. Run: skills/orc/scripts/test-orc-start.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -r "$tmp"' EXIT
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# The stub logs each call as args joined by |, one call per record, and answers get from a list of live names.
mkdir -p "$tmp/bin" "$tmp/repo"
cat >"$tmp/bin/hc" <<EOF
#!/bin/sh
{ printf '%s|' "\$@"; printf '\n--\n'; } >>"$tmp/hc.log"
[ "\$1" = get ] && { grep -qx "\$2" "$tmp/live" 2>/dev/null; exit \$?; }
exit 0
EOF
chmod +x "$tmp/bin/hc"
export PATH="$tmp/bin:$PATH" HC_TERMINAL_ID=t9 SHELL=/bin/zsh
: >"$tmp/live"
log() { cat "$tmp/hc.log"; }
has() { grep -qF -- "$1" "$tmp/hc.log" || fail "$2: missing '$1' in $(log)"; }
hasnt() { grep -qF -- "$1" "$tmp/hc.log" && fail "$2: unexpected '$1' in $(log)" || true; }

: >"$tmp/hc.log"
echo "ABC-12" | ./orc-start spec ABC-12 "$tmp/repo"
has "run|--bg|--name|spec-abc-12|--label|orch.ticket=ABC-12|--cwd|$tmp/repo|--|/bin/zsh|-ic|exec claude --permission-mode auto \"\$@\"|orc|" "spec run"
has '<hc from="t9 head" reach="hc send t9 when done or stuck">' "spec tag"
has "$(head -1 ../prompts/spec.md)" "spec prompt"
has "Parent: hc send t9" "spec parent line"
has "ABC-12
</hc>|" "spec body and closing tag"
has "label|t9|orc.phase=spec|" "spec phase"
has "orc.ticket=ABC-12|orc.round=0|" "spec ticket label"
hasnt "kill|" "spec with nothing stale"

: >"$tmp/hc.log"
echo "spec text" | ./orc-start build "acme/widgets#12" "$tmp/repo" sonnet
has "--name|acme-widgets-12|" "build name from a GitHub key"
has "exec claude --worktree acme-widgets-12 --permission-mode auto --model sonnet \"\$@\"|" "build command"
has "orc.phase=build|" "build phase"

: >"$tmp/hc.log"
echo "brief" | ./orc-start reviewer ABC-12 "$tmp/repo"
has "--name|sol-abc-12|" "reviewer name"
has 'exec codex --no-daemon -a never -c default_permissions=\"reviewer\"' "reviewer command"
# shellcheck disable=SC2016
has '$(dirname $(git rev-parse --path-format=absolute --git-common-dir))' "reviewer trust path left for the agent's shell"
has "orc.phase=review|" "reviewer phase"
has "label|t9|orc.round=1|" "reviewer round"

: >"$tmp/hc.log"
echo finish-abc-12 >"$tmp/live"
echo "checks" | ./orc-start finish ABC-12 "$tmp/repo"
has "kill|finish-abc-12|" "stale terminal killed"
has "rm|finish-abc-12|" "stale terminal removed"
[ "$(grep -n '^kill|' "$tmp/hc.log" | cut -d: -f1)" -lt "$(grep -n '^run|' "$tmp/hc.log" | cut -d: -f1)" ] || fail "stale terminal cleaned after the run: $(log)"
grep -q "^label|" "$tmp/hc.log" && fail "finish set a label: $(log)"
: >"$tmp/live"

: >"$tmp/hc.log"
echo ci-abc-12 >"$tmp/live"
./orc-start ci ABC-12 "$tmp/repo" https://github.com/example-org/example-repo/pull/42 </dev/null
has "kill|ci-abc-12|" "stale ci terminal killed"
has "run|--bg|--name|ci-abc-12|--label|orch.ticket=ABC-12|--cwd|$tmp/repo|--|$PWD/orc-ci|https://github.com/example-org/example-repo/pull/42|" "ci run"
has "orc.phase=ci|" "ci phase"
: >"$tmp/live"

: >"$tmp/hc.log"
echo x | ./orc-start build ABC-12 "$tmp/repo" 2>/dev/null && fail "build without a model accepted"
echo x | ./orc-start build ABC-12 "$tmp/repo" gpt 2>/dev/null && fail "unknown model accepted"
echo x | ./orc-start spec ABC-12 "$tmp/repo" opus 2>/dev/null && fail "model on a non-build role accepted"
./orc-start ci ABC-12 "$tmp/repo" 42 </dev/null 2>/dev/null && fail "ci without a PR URL accepted"
echo x | ./orc-start finish ABC-12 "$tmp/repo" https://github.com/o/r/pull/1 2>/dev/null && fail "fourth argument on finish accepted"
echo x | ./orc-start review ABC-12 "$tmp/repo" 2>/dev/null && fail "unknown role accepted"
echo x | ./orc-start spec ABC-12 "$tmp/nope" 2>/dev/null && fail "missing cwd accepted"
echo x | ./orc-start spec "" "$tmp/repo" 2>/dev/null && fail "empty key accepted"
./orc-start spec ABC-12 "$tmp/repo" </dev/null 2>/dev/null && fail "empty body accepted"
echo x | HC_TERMINAL_ID='' ./orc-start spec ABC-12 "$tmp/repo" 2>/dev/null && fail "ran without HC_TERMINAL_ID"
[ -s "$tmp/hc.log" ] && fail "a rejected call reached hc: $(log)"

shellcheck -x orc-start orc-lib.sh test-orc-start.sh
echo "ok orc-start"
