# shellcheck shell=bash
# Shared by orc-start, orc-send and orc-stop: terminal names and cleanup. Source it.

# shellcheck disable=SC2034 # used by orc-stop
ORC_ROLES=(spec build reviewer ci finish)

# orc_n <key>: the key in lower case, every character outside a-z0-9- turned into -.
orc_n() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g'; }

# orc_name <role> <key>: the hc terminal name of that role's agent; fails on an unknown role.
orc_name() {
  local n
  n="$(orc_n "$2")"
  case "$1" in
    spec) echo "spec-$n" ;;
    build) echo "$n" ;;
    reviewer) echo "sol-$n" ;;
    ci) echo "ci-$n" ;;
    finish) echo "finish-$n" ;;
    *) return 1 ;;
  esac
}

# orc_remove <name>: kill and remove that terminal, if there is one.
orc_remove() {
  hc get "$1" >/dev/null 2>&1 || return 0
  hc kill "$1" >/dev/null 2>&1 || true
  hc rm "$1" >/dev/null
}
