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
# OVERDUE (added 2026-09-14): a clock that passed is not gone until someone
# disposed of it. The dashboard surfaces (the merged clock doc and the
# open-loops dashboard, if present) are re-read for rows whose date is in
# the past, inside --overdue N days, and whose line carries no disposition
# marker (done/closed/sent/dropped/parked/void/lapsed/adopted/resolved...).
# Those print as OVERDUE T-n until a session cancels, parks or re-queues
# them. Origin: a lab recheck lapsed three windows in a row and the sweep
# never said so, because "past = provenance" also swallowed "past = missed".
#
# UNDATED: a row in the clock doc's tables that carries no date token at
# all ("book in-window", "when back") can never be pulled by date. Listed
# so it gets one.
#
# Read-only. Touches no state, mutates no doc.
#
# Usage: clock-sweep.sh [--horizon N] [--overdue N] [--clocks FILE] [--all] [ROOT...]
#   --horizon N   days ahead to report (default 30)
#   --overdue N   days back to re-surface undisposed past rows (default 60; 0 = off)
#   --clocks FILE merged clock doc to diff against (default: newest
#                 life/clocks-*.md under the first root)
#   --all         also print dates already surfaced in the clock doc
set -uo pipefail
# Snippets are cut by character, never by byte: a byte-cut can split a
# multibyte char and the invalid sequence makes a row vanish downstream.
if locale -a 2>/dev/null | grep -qiE '^C\.utf-?8$'; then export LC_ALL=C.UTF-8; else export LC_ALL=en_US.UTF-8 2>/dev/null || true; fi

horizon=30
overdue=60
clocks=""
show_all=0
roots=()
while [ $# -gt 0 ]; do
  case "$1" in
    --horizon) shift; horizon="$1" ;;
    --overdue) shift; overdue="$1" ;;
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
  snippet="$(sed -n "${ln}p" "$f" 2>/dev/null | sed 's/^[[:space:]|>*-]*//' | cut -c1-110 | iconv -c -f UTF-8 -t UTF-8)"
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
# ---- OVERDUE / UNDATED: the dashboard surfaces, re-read for the past ----
disposed_rx='✅|~~|CLOSED|DONE|SENT|DROP|PARKED|VOID|lapsed|adopted|resolved|SUPERSEDED|FILED|FIRED|PAID|moot|CLEARED|cancel|ANSWERED|ISSUED|CONFIRMED|happened|retired|dead|delivered|shipped|closed log'
surfaces=()
[ -n "$clocks" ] && [ -r "$clocks" ] && surfaces+=("$clocks")
ol="$(find "${roots[0]}" -maxdepth 3 -name 'open-loops.md' 2>/dev/null | head -1)"
[ -n "$ol" ] && [ -r "$ol" ] && surfaces+=("$ol")
if [ "$overdue" -gt 0 ] && [ ${#surfaces[@]} -gt 0 ]; then
  back_s=$(( today_s - overdue * 86400 ))
  midnight_s="$(date -d "$(date +%Y-%m-%d)" +%s)"
  od="$(mktemp)"
  for f in "${surfaces[@]}"; do
    # only committed rows count: table rows and list items, above any
    # closed log; prose and headings in these docs are narrative.
    stop="$(grep -nE '^## Closed log' "$f" | head -1 | cut -d: -f1)"
    [ -z "$stop" ] && stop=999999
    grep -nE "$rx" "$f" 2>/dev/null | while IFS=: read -r ln rest; do
      [ "$ln" -ge "$stop" ] && continue
      line="$(sed -n "${ln}p" "$f")"
      echo "$line" | grep -qE '^[[:space:]]*(\||- |[0-9]+\. )' || continue
      echo "$line" | grep -qE '^[[:space:]]*\|[[:space:]]*(-|:|Date|Item|When|#)' && continue
      # a row with a disposition marker is done with; a row that also
      # carries a FUTURE date has been re-queued and shows up above.
      echo "$line" | grep -qiE "$disposed_rx" && continue
      best=""
      for tok in $(echo "$line" | grep -oE "$rx"); do
        case "$tok" in
          [0-9][0-9][0-9][0-9]-*) iso="$tok" ;;
          *[-/][0-9][0-9][0-9][0-9])
            d="${tok%%[-/]*}"; r2="${tok#*[-/]}"; m="${r2%%[-/]*}"; y="${r2##*[-/]}"
            iso="$(printf '%04d-%02d-%02d' "$((10#$y))" "$((10#$m))" "$((10#$d))")" ;;
          *) d="${tok%%[-/]*}"; m="${tok##*[-/]}"
             iso="$(printf '%04d-%02d-%02d' "$today_y" "$((10#$m))" "$((10#$d))")" ;;
        esac
        s2="$(date -d "$iso" +%s 2>/dev/null)" || continue
        [ "$s2" -ge "$midnight_s" ] && { best="FUTURE"; break; }
        [ "$s2" -lt "$back_s" ] && continue
        # keep the LATEST past date on the row: that is the last window it had
        if [ -z "$best" ] || [ "$iso" \> "$best" ]; then best="$iso"; fi
      done
      [ -z "$best" ] || [ "$best" = "FUTURE" ] && continue
      snippet="$(echo "$line" | sed 's/^[[:space:]|>*-]*//' | cut -c1-110 | iconv -c -f UTF-8 -t UTF-8)"
      printf '%s\t%s\t%s\t%s\n' "$best" "${f##*/}" "$ln" "$snippet"
    done
  done | sort -u > "$od"
  n_od=$(wc -l < "$od" | tr -d ' ')
  if [ "$n_od" -gt 0 ]; then
    printf '\nOVERDUE, undisposed (past %sd; cancel, park or re-queue each):\n' "$overdue"
    while IFS=$'\t' read -r iso base ln snippet || [ -n "${iso:-}" ]; do
      days=$(( ( today_s - $(date -d "$iso" +%s) ) / 86400 ))
      printf '  T-%-3s %s  %-22s %s\n' "$days" "$iso" "$base:$ln" "$snippet"
    done < "$od"
  fi
  rm -f "$od"
fi
# UNDATED: clock-doc table rows with no date token at all.
n_ud=0
if [ -n "$clocks" ] && [ -r "$clocks" ]; then
  ud="$(grep -nE '^\|' "$clocks" | grep -vE '^[0-9]+:\|[[:space:]]*(-|:|Date|Item|When|#)' | grep -vE "$rx" | grep -viE "$disposed_rx" || true)"
  if [ -n "$ud" ]; then
    n_ud=$(printf '%s\n' "$ud" | wc -l | tr -d ' ')
    printf '\nUNDATED clock rows (no date token; the puller cannot see these):\n'
    printf '%s\n' "$ud" | while IFS=: read -r ln rest; do
      printf '  %-22s %s\n' "${clocks##*/}:$ln" "$(echo "$rest" | sed 's/^[[:space:]|>*-]*//' | cut -c1-110 | iconv -c -f UTF-8 -t UTF-8)"
    done
  fi
fi

echo "-- clock-sweep: $unsurfaced unsurfaced / $(wc -l < "$due" | tr -d ' ') due within ${horizon}d / ${n_od:-0} overdue (${overdue}d back) / $n_ud undated / $scanned docs scanned --"
if [ -n "$clocks" ]; then
  echo "-- diffed against: $clocks --"
else
  echo "-- WARNING: no merged clock doc found; every due date reads as unsurfaced. Pass --clocks. --"
fi
if [ "$defaulted" -eq 1 ]; then
  echo "-- NOTE: root defaulted to the KB docs tree. Other dated surfaces (~/autonomo, project repos) are outside this field: clock-sweep.sh \$HOME/Miam/miam-knowledge-base/docs \$HOME/autonomo --"
fi
rm -f "$matches" "$due"
