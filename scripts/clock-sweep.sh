#!/usr/bin/env bash
# clock-sweep — the calendar surface of an exteroception sweep.
#
# Every dated obligation in a knowledge base lives in its OWNING doc: a
# money doc holds the filing deadline, a decision doc holds the decision
# date, a forecast ledger holds its resolve-by. A dashboard only carries
# what some session happened to push onto it. That push is manual, so the
# dashboard is complete only by luck — and its fresh date launders the
# items it never received. This sweep is the missing pull: it reads the
# owning docs directly and reports what is coming due.
#
# Reports only FUTURE dates inside the horizon. A date already past is
# provenance ("verified 04-08", "read 05-08-2026"), not a clock — which is
# also what makes an unpadded, year-less "15-09" safely resolvable: read it
# as this year, and if that already happened it was a stamp, not a deadline.
#
# UNSURFACED marks a due date that appears in an owning doc but nowhere in
# the merged clock doc (--clocks). That is the leak, named: an obligation
# whose only record is a file nobody opens at wake.
#
# Read-only. Touches no state, mutates no doc.
#
# Usage: clock-sweep.sh [--horizon N] [--clocks FILE] [--all] [ROOT...]
#   --horizon N   days ahead to report (default 30)
#   --clocks FILE merged clock doc to diff against (default: newest
#                 life/clocks-*.md under the first root)
#   --all         also print dates already surfaced in the clock doc
set -uo pipefail

horizon=30
clocks=""
show_all=0
roots=()
while [ $# -gt 0 ]; do
  case "$1" in
    --horizon) shift; horizon="$1" ;;
    --clocks)  shift; clocks="$1" ;;
    --all)     show_all=1 ;;
    -h|--help) grep '^#' "$0" | cut -c3-; exit 0 ;;
    *) roots+=("$1") ;;
  esac
  shift
done
defaulted=0
[ ${#roots[@]} -eq 0 ] && { roots=("$HOME/Miam/miam-knowledge-base/docs"); defaulted=1; }

today_s=$(date +%s)
today_y=$(date +%Y)
limit_s=$(( today_s + horizon * 86400 ))

# Default clock doc: newest life/clocks-*.md in the first root.
if [ -z "$clocks" ]; then
  clocks="$(find "${roots[0]}" -maxdepth 3 -name 'clocks-*.md' 2>/dev/null | sort | tail -1)"
fi
clocks_body=""
[ -n "$clocks" ] && [ -r "$clocks" ] && clocks_body="$(cat "$clocks")"

# Date tokens, in the shapes these docs actually use:
#   2026-09-30 · 04-08-2026 · 30-09 · 22/08
rx='[0-9]{4}-[0-9]{2}-[0-9]{2}|([0-9]{1,2})[-/](0[1-9]|1[0-2])([-/][0-9]{4})?'

matches="$(mktemp)"
scanned=0
for root in "${roots[@]}"; do
  while IFS= read -r f; do
    scanned=$((scanned + 1))
    # The merged clock doc is the VIEW, never a source — scanning it would
    # make every item look surfaced by construction.
    [ -n "$clocks" ] && [ "$(realpath -m "$f")" = "$(realpath -m "$clocks")" ] && continue
    grep -noE "$rx" "$f" 2>/dev/null | while IFS=: read -r ln tok; do
      printf '%s\t%s\t%s\n' "$tok" "$f" "$ln"
    done
  done < <(find "$root" -type f -name '*.md' -not -path '*/node_modules/*' 2>/dev/null | sort)
done >> "$matches"

due="$(mktemp)"
while IFS=$'\t' read -r tok f ln; do
  case "$tok" in
    [0-9][0-9][0-9][0-9]-*) iso="$tok" ;;
    *[-/][0-9][0-9][0-9][0-9])
      d="${tok%%[-/]*}"; rest="${tok#*[-/]}"; m="${rest%%[-/]*}"; y="${rest##*[-/]}"
      iso="$(printf '%04d-%02d-%02d' "$((10#$y))" "$((10#$m))" "$((10#$d))")" ;;
    *)
      d="${tok%%[-/]*}"; m="${tok##*[-/]}"
      iso="$(printf '%04d-%02d-%02d' "$today_y" "$((10#$m))" "$((10#$d))")" ;;
  esac
  s="$(date -d "$iso" +%s 2>/dev/null)" || continue
  [ -z "$s" ] && continue
  # Past = provenance stamp, not a clock. Beyond the horizon = not yet ours.
  [ "$s" -lt "$today_s" ] && continue
  [ "$s" -gt "$limit_s" ] && continue
  snippet="$(sed -n "${ln}p" "$f" 2>/dev/null | sed 's/^[[:space:]|>*-]*//' | cut -c1-110)"
  # Surfaced = this DAY appears in the clock doc, in any separator or
  # padding the docs actually use. Matching the raw token would call
  # "~31/08" unsurfaced while the clock doc plainly carries "31-08".
  dd="${iso:8:2}"; mm="${iso:5:2}"; ud="$((10#$dd))"
  surfaced=0
  for form in "$dd-$mm" "$dd/$mm" "$ud-$mm" "$ud/$mm" "$iso"; do
    case "$clocks_body" in *"$form"*) surfaced=1; break ;; esac
  done
  printf '%s\t%d\t%s\t%s\t%s\n' "$iso" "$surfaced" "${f##*/}" "$ln" "$snippet"
done < "$matches" | sort -u > "$due"

printed=0
unsurfaced=0
last=""
while IFS=$'\t' read -r iso surf base ln snippet; do
  [ "$surf" -eq 0 ] && unsurfaced=$((unsurfaced + 1))
  [ "$surf" -eq 1 ] && [ "$show_all" -eq 0 ] && continue
  if [ "$iso" != "$last" ]; then
    days=$(( ( $(date -d "$iso" +%s) - today_s ) / 86400 ))
    printf '\n%s  (T+%s)\n' "$iso" "$days"
    last="$iso"
  fi
  mark="  "; [ "$surf" -eq 0 ] && mark="!!"
  printf '  %s %-34s %s\n' "$mark" "$base:$ln" "$snippet"
  printed=$((printed + 1))
done < "$due"

echo
echo "-- clock-sweep: $unsurfaced unsurfaced / $(wc -l < "$due" | tr -d ' ') due within ${horizon}d / $scanned docs scanned --"
if [ -n "$clocks" ]; then
  echo "-- diffed against: $clocks --"
else
  echo "-- WARNING: no merged clock doc found; every due date reads as unsurfaced. Pass --clocks. --"
fi
if [ "$defaulted" -eq 1 ]; then
  echo "-- NOTE: root defaulted to the KB docs tree. Other dated surfaces (~/autonomo, project repos) are outside this field: clock-sweep.sh \$HOME/Miam/miam-knowledge-base/docs \$HOME/autonomo --"
fi
rm -f "$matches" "$due"
