#!/usr/bin/env bash
# Show what changed upstream since each vendored skill was copied.
# A vendored skill records `metadata.source` (a GitHub tree URL) and
# `metadata.upstream_sha` in its SKILL.md frontmatter. Local edits are not
# compared; this only reports upstream movement, so you can decide what to pull.
#
# Usage: tools/upstream-diff.sh [-p] [skill...]   -p prints the patches
#        tools/upstream-diff.sh --self-test
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

# frontmatter_field <file> <key>: value of an indented metadata key, or nothing.
frontmatter_field() {
  awk -v key="$2" '
    /^---$/ { n++; next }
    n == 1 && $1 == key":" { sub("^[^:]*: *", ""); print; exit }
  ' "$1"
}

# parse_source <url>: prints "owner repo path" from
# https://github.com/<owner>/<repo>/tree/<ref>/<path>.
parse_source() {
  local rest=${1#https://github.com/}
  [[ $rest != "$1" ]] || return 1
  local owner=${rest%%/*}
  rest=${rest#*/}
  local repo=${rest%%/*}
  rest=${rest#*/}
  [[ $rest == tree/* ]] || return 1
  rest=${rest#tree/}
  local path=${rest#*/}
  [[ -n $owner && -n $repo && -n $path && $path != "$rest" ]] || return 1
  echo "$owner $repo $path"
}

# gh_retry <args...>: gh api with three tries and exponential backoff.
gh_retry() {
  local try out
  for try in 1 2 3; do
    if out=$(gh api "$@" 2>&1); then
      printf '%s' "$out"
      return 0
    fi
    [[ $try == 3 ]] || sleep $((2 ** try))
  done
  echo "gh api $* failed after 3 tries: $out" >&2
  return 1
}

# Runs in a subshell so its EXIT trap cleans up only the fixture.
self_test() (
  local fixture got
  fixture=$(mktemp)
  trap 'rm -f "$fixture"' EXIT
  printf '%s\n' '---' 'name: x' 'metadata:' \
    '  source: https://github.com/o/r/tree/abc/skills/eng/x' \
    '  upstream_sha: abc' '---' 'upstream_sha: body-not-frontmatter' >"$fixture"
  got=$(frontmatter_field "$fixture" upstream_sha)
  [[ $got == abc ]] || {
    echo "FAIL frontmatter_field: '$got'" >&2
    return 1
  }
  got=$(parse_source https://github.com/o/r/tree/abc/skills/eng/x)
  [[ $got == "o r skills/eng/x" ]] || {
    echo "FAIL parse_source: '$got'" >&2
    return 1
  }
  if parse_source https://example.com/o/r/tree/abc/x >/dev/null; then
    echo "FAIL parse_source accepted a non-GitHub URL" >&2
    return 1
  fi
  if parse_source https://github.com/o/r/blob/abc/x >/dev/null; then
    echo "FAIL parse_source accepted a blob URL" >&2
    return 1
  fi
  echo "self-test passed"
)

main() {
  local patches=0
  if [[ ${1:-} == --self-test ]]; then
    self_test
    return
  fi
  if [[ ${1:-} == -p ]]; then
    patches=1
    shift
  fi

  # Global, not local: the EXIT trap runs after main returns.
  cache=$(mktemp -d)
  trap 'rm -rf "$cache"' EXIT

  local skill_md skill src sha owner repo path key branch changed
  local -a skills=("$@")
  [[ ${#skills[@]} -gt 0 ]] || skills=("$root"/skills/*/)
  for skill in "${skills[@]}"; do
    skill=$(basename "$skill")
    skill_md="$root/skills/$skill/SKILL.md"
    [[ -f $skill_md ]] || { echo "$skill: no SKILL.md" >&2 && return 1; }
    src=$(frontmatter_field "$skill_md" source)
    sha=$(frontmatter_field "$skill_md" upstream_sha)
    [[ -n $src && -n $sha ]] || continue # not vendored
    read -r owner repo path < <(parse_source "$src") || {
      echo "$skill: cannot parse source '$src'" >&2
      return 1
    }

    # One compare call per upstream repo and commit, shared by its skills.
    key="$cache/$owner-$repo-$sha.json"
    if [[ ! -f $key ]]; then
      branch=$(gh_retry "repos/$owner/$repo" --jq .default_branch)
      gh_retry "repos/$owner/$repo/compare/$sha...$branch" >"$key"
    fi

    changed=$(jq -r --arg p "$path/" \
      '.files[] | select((.filename | startswith($p)) or ((.previous_filename // "") | startswith($p))) | "  \(.status)\t\(.filename)"' "$key")
    if [[ -z $changed ]]; then
      echo "$skill: up to date ($owner/$repo ${sha:0:7})"
      continue
    fi
    echo "$skill: changed upstream since ${sha:0:7} ($owner/$repo)"
    echo "$changed"
    if [[ $patches == 1 ]]; then
      jq -r --arg p "$path/" \
        '.files[] | select((.filename | startswith($p)) or ((.previous_filename // "") | startswith($p))) | "--- \(.filename)\n\(.patch // "(no patch: binary or too large)")"' "$key"
    fi
  done
}

main "$@"
