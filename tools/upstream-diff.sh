#!/usr/bin/env bash
# Compare vendored skills with their upstream source.
# A vendored skill records `metadata.source` (a GitHub tree URL) and
# `metadata.upstream_sha` in its SKILL.md frontmatter. That commit is the base:
# upstream changes are measured from it, and so are your local changes.
#
# Usage: tools/upstream-diff.sh [skill...]           what changed upstream since the base
#        tools/upstream-diff.sh -p [skill...]        the same, with patches
#        tools/upstream-diff.sh --local [skill...]   your local changes against the base
#        tools/upstream-diff.sh --merge [skill...]   three-way merge upstream changes into
#                                                    your copy, then move the base forward
#        tools/upstream-diff.sh --self-test
# --merge refuses a skill with uncommitted changes, leaves conflict markers for you to
# resolve, reports upstream deletions and renames without applying them, skips agents/
# (not vendored), and exits 1 if any file conflicts.
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

# set_upstream_sha <SKILL.md> <new-sha>: move the base to <new-sha> in the
# frontmatter's upstream_sha and source lines only. Copies back over the file
# so it keeps its permissions.
set_upstream_sha() {
  local old tmp
  old=$(frontmatter_field "$1" upstream_sha)
  [[ -n $old ]] || return 1
  tmp=$(mktemp)
  awk -v old="$old" -v new="$2" '
    /^---$/ { n++ }
    n == 1 && /^  (upstream_sha|source): / { gsub(old, new) }
    { print }
  ' "$1" >"$tmp"
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

# merge_into <local> <base> <upstream> <base-label> <upstream-label>: three-way merge
# of upstream's change into <local>, in place. Returns the number of conflicts.
merge_into() {
  git merge-file -L local -L "$4" -L "$5" "$1" "$2" "$3"
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

# fetch_file <owner> <repo> <path> <ref> <out>: an upstream file at <ref>, written
# straight to <out> so trailing newlines survive. Returns 2 when the file does not
# exist at <ref>, and retries other failures.
fetch_file() {
  local try err
  err=$(mktemp)
  for try in 1 2 3; do
    if gh api -H 'Accept: application/vnd.github.raw' \
      "repos/$1/$2/contents/$3?ref=$4" >"$5" 2>"$err"; then
      rm -f "$err"
      return 0
    fi
    if grep -q 'HTTP 404' "$err"; then
      rm -f "$err"
      return 2
    fi
    [[ $try == 3 ]] || sleep $((2 ** try))
  done
  echo "fetching $1/$2/$3 at $4 failed after 3 tries: $(cat "$err")" >&2
  rm -f "$err"
  return 1
}

# Runs in a subshell so its EXIT trap cleans up only the fixtures.
self_test() (
  local dir got rc
  dir=$(mktemp -d)
  trap 'rm -rf "$dir"' EXIT
  fail() {
    echo "FAIL $*" >&2
    exit 1
  }

  printf '%s\n' '---' 'name: x' 'metadata:' \
    '  source: https://github.com/o/r/tree/abc123/skills/eng/x' \
    '  upstream_sha: abc123' '---' 'upstream_sha: abc123 stays in the body' >"$dir/SKILL.md"
  got=$(frontmatter_field "$dir/SKILL.md" upstream_sha)
  [[ $got == abc123 ]] || fail "frontmatter_field: '$got'"

  got=$(parse_source https://github.com/o/r/tree/abc/skills/eng/x)
  [[ $got == "o r skills/eng/x" ]] || fail "parse_source: '$got'"
  ! parse_source https://example.com/o/r/tree/abc/x >/dev/null || fail "parse_source accepted a non-GitHub URL"
  ! parse_source https://github.com/o/r/blob/abc/x >/dev/null || fail "parse_source accepted a blob URL"

  set_upstream_sha "$dir/SKILL.md" def456
  [[ $(frontmatter_field "$dir/SKILL.md" upstream_sha) == def456 ]] || fail "set_upstream_sha: upstream_sha not moved"
  [[ $(frontmatter_field "$dir/SKILL.md" source) == https://github.com/o/r/tree/def456/skills/eng/x ]] ||
    fail "set_upstream_sha: source not moved"
  grep -qx 'upstream_sha: abc123 stays in the body' "$dir/SKILL.md" || fail "set_upstream_sha changed the body"

  # Local edit on line 2, upstream edit on line 4: merges cleanly.
  printf '%s\n' 1 2 3 4 5 >"$dir/base"
  printf '%s\n' 1 LOCAL 3 4 5 >"$dir/local"
  printf '%s\n' 1 2 3 UPSTREAM 5 >"$dir/upstream"
  rc=0
  merge_into "$dir/local" "$dir/base" "$dir/upstream" base upstream || rc=$?
  [[ $rc == 0 ]] || fail "clean merge returned $rc"
  [[ $(tr '\n' ' ' <"$dir/local") == "1 LOCAL 3 UPSTREAM 5 " ]] || fail "clean merge gave: $(tr '\n' ' ' <"$dir/local")"

  # Both edit line 2: one conflict, with markers left in the file.
  printf '%s\n' 1 LOCAL 3 >"$dir/local"
  printf '%s\n' 1 2 3 >"$dir/base"
  printf '%s\n' 1 UPSTREAM 3 >"$dir/upstream"
  rc=0
  merge_into "$dir/local" "$dir/base" "$dir/upstream" base upstream || rc=$?
  [[ $rc == 1 ]] || fail "conflicting merge returned $rc, expected 1"
  grep -q '^<<<<<<< local' "$dir/local" || fail "conflicting merge left no markers"

  echo "self-test passed"
)

# changed_files <compare.json> <path>: "status<TAB>filename<TAB>previous_filename"
# for each upstream change under <path>.
changed_files() {
  jq -r --arg p "$2/" '.files[]
    | select((.filename | startswith($p)) or ((.previous_filename // "") | startswith($p)))
    | "\(.status)\t\(.filename)\t\(.previous_filename // "")"' "$1"
}

# show_local <skill> <owner> <repo> <path> <base-sha>: diff each local file against
# the upstream file at the base.
show_local() {
  local skill=$1 owner=$2 repo=$3 path=$4 sha=$5 rel rc out any=0
  while IFS= read -r rel; do
    rc=0
    fetch_file "$owner" "$repo" "$path/$rel" "$sha" "$cache/base" || rc=$?
    if [[ $rc == 2 ]]; then
      echo "  local only: $rel"
      any=1
      continue
    fi
    [[ $rc == 0 ]] || return 1
    if ! out=$(diff -u --label "upstream ${sha:0:7}/$rel" --label "local/$rel" \
      "$cache/base" "$root/skills/$skill/$rel"); then
      echo "$out"
      any=1
    fi
  done < <(cd "$root/skills/$skill" && find . -type f | sed 's#^\./##' | sort)
  [[ $any == 1 ]] || echo "  no local changes"
}

# merge_skill <skill> <owner> <repo> <path> <base-sha> <head-sha> <compare.json>:
# apply each upstream change since the base, then move the base to <head-sha>.
# Writes the number of conflicting files to $cache/conflicts.
merge_skill() {
  local skill=$1 owner=$2 repo=$3 path=$4 sha=$5 head=$6 compare=$7
  local dir="$root/skills/$skill" status file prev rel rc conflicts=0
  while IFS=$'\t' read -r status file prev; do
    rel=${file#"$path"/}
    if [[ $rel == agents/* ]]; then
      echo "  skipped (agents/ is not vendored): $rel"
      continue
    fi
    case $status in
      modified | changed)
        if [[ ! -f $dir/$rel ]]; then
          echo "  skipped (not in your copy): $rel"
          continue
        fi
        fetch_file "$owner" "$repo" "$file" "$sha" "$cache/base"
        fetch_file "$owner" "$repo" "$file" "$head" "$cache/upstream"
        rc=0
        merge_into "$dir/$rel" "$cache/base" "$cache/upstream" \
          "upstream ${sha:0:7}" "upstream ${head:0:7}" || rc=$?
        if [[ $rc == 0 ]]; then
          echo "  merged: $rel"
        elif [[ $rc -gt 0 && $rc -lt 128 ]]; then
          echo "  CONFLICT ($rc): $rel"
          conflicts=$((conflicts + 1))
        else
          echo "git merge-file failed on $rel" >&2
          return 1
        fi
        ;;
      added)
        if [[ -e $dir/$rel ]]; then
          echo "  CONFLICT (added upstream, already in your copy): $rel"
          conflicts=$((conflicts + 1))
          continue
        fi
        mkdir -p "$(dirname "$dir/$rel")"
        fetch_file "$owner" "$repo" "$file" "$head" "$dir/$rel"
        echo "  added: $rel"
        ;;
      removed) echo "  removed upstream, left in place: $rel" ;;
      renamed) echo "  renamed upstream, not applied: ${prev#"$path"/} -> $rel" ;;
      *) echo "  $status upstream, not applied: $rel" ;;
    esac
  done < <(changed_files "$compare" "$path")
  set_upstream_sha "$dir/SKILL.md" "$head"
  echo "$conflicts" >"$cache/conflicts"
}

main() {
  local mode=report
  case ${1:-} in
    --self-test)
      self_test
      return
      ;;
    -p) mode=patches ;;
    --local) mode=local ;;
    --merge) mode=merge ;;
  esac
  [[ $mode == report ]] || shift

  # Global, not local: the EXIT trap runs after main returns.
  cache=$(mktemp -d)
  trap 'rm -rf "$cache"' EXIT

  local skill_md skill src sha owner repo path key branch head changed total=0
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

    if [[ $mode == local ]]; then
      echo "$skill: local changes against upstream ${sha:0:7} ($owner/$repo)"
      show_local "$skill" "$owner" "$repo" "$path" "$sha"
      continue
    fi

    # One head lookup and compare call per upstream repo and base, shared by its skills.
    key="$cache/$owner-$repo-$sha"
    if [[ ! -f $key.json ]]; then
      branch=$(gh_retry "repos/$owner/$repo" --jq .default_branch)
      gh_retry "repos/$owner/$repo/commits/$branch" --jq .sha >"$key.head"
      gh_retry "repos/$owner/$repo/compare/$sha...$(cat "$key.head")" >"$key.json"
    fi
    head=$(cat "$key.head")

    changed=$(changed_files "$key.json" "$path")
    if [[ -z $changed ]]; then
      echo "$skill: up to date ($owner/$repo ${sha:0:7})"
      continue
    fi

    if [[ $mode == merge ]]; then
      if [[ -n $(git -C "$root" status --porcelain -- "skills/$skill") ]]; then
        echo "$skill: has uncommitted changes, commit or stash them first" >&2
        return 1
      fi
      echo "$skill: merging upstream ${sha:0:7}..${head:0:7} ($owner/$repo)"
      merge_skill "$skill" "$owner" "$repo" "$path" "$sha" "$head" "$key.json"
      total=$((total + $(cat "$cache/conflicts")))
      continue
    fi

    echo "$skill: changed upstream since ${sha:0:7} ($owner/$repo)"
    awk -F'\t' '{ print "  " $1 "\t" $2 }' <<<"$changed"
    if [[ $mode == patches ]]; then
      jq -r --arg p "$path/" \
        '.files[] | select((.filename | startswith($p)) or ((.previous_filename // "") | startswith($p))) | "--- \(.filename)\n\(.patch // "(no patch: binary or too large)")"' "$key.json"
    fi
  done

  if [[ $mode == merge ]]; then
    if [[ $total -gt 0 ]]; then
      echo "$total file(s) conflict. Resolve the markers, then commit." >&2
      return 1
    fi
    echo "Merged. Review with git diff, then commit."
  fi
}

main "$@"
