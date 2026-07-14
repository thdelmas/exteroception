#!/usr/bin/env bash
# git-sweep — the working-trees surface of an exteroception sweep.
#
# Scans every git repo under the given roots and reports ONLY deltas:
# dirty trees, stranded (unpushed) commits, behind-upstream, detached
# heads, missing upstreams. A clean, pushed, tracking repo prints nothing.
#
# Read-only. No fetch by default (fast, offline-safe): ahead/behind is
# measured against the last-fetched remote refs. Pass --fetch to refresh
# remotes first (network, slower).
#
# Usage: git-sweep.sh [--fetch] [--depth N] [ROOT...]   (default root: .)
set -uo pipefail

fetch=0
depth=4
roots=()
while [ $# -gt 0 ]; do
  case "$1" in
    --fetch) fetch=1 ;;
    --depth) shift; depth="$1" ;;
    -h|--help) grep '^#' "$0" | cut -c3-; exit 0 ;;
    *) roots+=("$1") ;;
  esac
  shift
done
[ ${#roots[@]} -eq 0 ] && roots=(.)

found=0
scanned=0
for root in "${roots[@]}"; do
  while IFS= read -r gitdir; do
    repo="$(dirname "$gitdir")"
    scanned=$((scanned + 1))
    [ "$fetch" -eq 1 ] && git -C "$repo" fetch --quiet --all 2>/dev/null

    flags=""
    branch="$(git -C "$repo" symbolic-ref --short -q HEAD || true)"
    if [ -z "$branch" ]; then
      branch="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo '?')"
      flags="$flags DETACHED"
    fi

    dirty="$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    [ "$dirty" -gt 0 ] && flags="$flags DIRTY:$dirty"

    upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
    if [ -n "$upstream" ]; then
      counts="$(git -C "$repo" rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || echo '')"
      if [ -n "$counts" ]; then
        ahead="${counts%%	*}"; behind="${counts##*	}"
        [ "$ahead" -gt 0 ] && flags="$flags STRANDED:$ahead"
        [ "$behind" -gt 0 ] && flags="$flags BEHIND:$behind"
      fi
    elif [ -n "$(git -C "$repo" remote 2>/dev/null)" ]; then
      flags="$flags NO-UPSTREAM"
    else
      # exists only on this disk — the most stranded a repo can be
      flags="$flags NO-REMOTE"
    fi

    if [ -n "$flags" ]; then
      found=$((found + 1))
      age="$(git -C "$repo" log -1 --format=%cr 2>/dev/null || echo 'no commits')"
      printf '%-45s %-18s %s  (last commit %s)\n' "$repo" "[$branch]" "${flags# }" "$age"
    fi
  done < <(find "$root" -maxdepth "$depth" -name .git \( -type d -o -type f \) 2>/dev/null \
             -not -path '*/node_modules/*' -not -path '*/.cache/*' -not -path '*/.nvm/*' | sort)
done

echo "-- git-sweep: $found repo(s) with deltas / $scanned scanned --"
