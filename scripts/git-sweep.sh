#!/usr/bin/env bash
# git-sweep — the working-trees surface of an exteroception sweep.
#
# Scans every git repo under the given roots and reports ONLY deltas:
# dirty trees, stranded (unpushed) commits, behind-upstream, detached
# heads, missing upstreams, and LANDED commits (HEAD moved since the last
# sweep — work another session finished while this one slept; shows the
# new subjects). A clean, pushed, tracking, unchanged repo prints nothing.
#
# Last-seen HEADs live in ~/.claude/state/git-sweep-seen.tsv (override:
# GIT_SWEEP_STATE). Updating it is the sense's own memory, not a world
# mutation; the sweep remains read-only toward the repos. First sight of
# a repo records a baseline silently.
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
defaulted=0
[ ${#roots[@]} -eq 0 ] && { roots=(.); defaulted=1; }

state="${GIT_SWEEP_STATE:-$HOME/.claude/state/git-sweep-seen.tsv}"
mkdir -p "$(dirname "$state")" && touch "$state"
newstate="$(mktemp)"

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

    # LANDED: HEAD moved since the last sweep saw this repo
    landed_log=""
    head_sha="$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)"
    if [ -n "$head_sha" ]; then
      key="$(realpath "$repo")"
      prev="$(awk -v k="$key" '$1==k{print $2}' "$state" | tail -1)"
      if [ -n "$prev" ] && [ "$prev" != "$head_sha" ]; then
        n="$(git -C "$repo" rev-list --count "$prev..HEAD" 2>/dev/null || echo '?')"
        flags="$flags LANDED:$n"
        landed_log="$(git -C "$repo" log --format='    + %h %s (%cr)' "$prev..HEAD" 2>/dev/null | head -3)"
      fi
      printf '%s %s\n' "$key" "$head_sha" >> "$newstate"
    fi

    if [ -n "$flags" ]; then
      found=$((found + 1))
      age="$(git -C "$repo" log -1 --format=%cr 2>/dev/null || echo 'no commits')"
      printf '%-45s %-18s %s  (last commit %s)\n' "$repo" "[$branch]" "${flags# }" "$age"
      [ -n "$landed_log" ] && printf '%s\n' "$landed_log"
    fi
  done < <(find "$root" -maxdepth "$depth" -name .git \( -type d -o -type f \) 2>/dev/null \
             -not -path '*/node_modules/*' -not -path '*/.cache/*' -not -path '*/.nvm/*' | sort)
done

# Persist last-seen HEADs: keep entries for repos outside this scan's field,
# replace entries for the repos just scanned.
{ awk 'NR==FNR{seen[$1]=1;next} !($1 in seen)' "$newstate" "$state"; cat "$newstate"; } > "$state.tmp" \
  && mv "$state.tmp" "$state"
rm -f "$newstate"

# A sense must state its field: "0 deltas" from a narrow scan reads as a
# quiet world. Name the roots, and flag when they were defaulted, not chosen.
echo "-- git-sweep: $found repo(s) with deltas / $scanned scanned under: $(realpath -m "${roots[@]}" | paste -sd' ') --"
if [ "$defaulted" -eq 1 ]; then
  echo "-- WARNING: field defaulted to cwd. If your watched surface is wider (e.g. \$HOME), this sweep proves nothing about it: git-sweep.sh --depth 3 \$HOME --"
fi
