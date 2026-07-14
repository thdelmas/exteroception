# Exteroception — sense the world at wake, as a diff against memory

The nervous system's missing near-field sense. An agent's memory is **write-time-stale**: it records the world as it was when last written, and the world kept moving while you slept — repos pushed or stranded, replies landed or didn't, clocks expired, services died. A blind agent discovers these mid-task, or never. Exteroception is the wake ritual: **capture actual state of the watched surfaces, diff against remembered state, brief the deltas ranked by urgency.** Read-only — senses never mutate. The paired sense to proprioception (self-in-motion ↔ world-at-wake); the sensory input of the consciousness-loop's wake phase.

## What it is not

- **Not octopus** — octopus explores the far field (discover the unknown); exteroception sweeps the near field (diff the known). Foraging vs checking the campsite.
- **Not rem-sleep** — rem-sleep runs at sleep and updates the map; exteroception runs at wake and checks the territory. They bookend the loop.
- **Not proprioception** — proprioception diffs the self (intended vs actual performance); exteroception diffs the environment (remembered vs actual world). Paired senses, same mechanism, opposite directions.
- **Not the loop** — the loop decides; exteroception supplies the sensory input the decision runs on. Deciding before sensing is guessing.
- **Not monitoring** — a monitor watches one signal continuously; exteroception sweeps all surfaces once, at wake, cheaply.

## The watched surfaces

An explicit, small list: **working trees** (dirty / stranded pushes / behind — `scripts/git-sweep.sh`), **conversations** (replies awaited or owed; absence past horizon is a delta), **clocks** (deadlines within ~7 days; expired outranks all), **services** (hosts, cron, CI), **due forecasts** (proprioception's ledger). A surface you never act on is noise — drop it. A surprise that arrived through no surface means the list has a hole — add one.

## The sweep cycle

1. **Enumerate the watched surfaces** — from the explicit list, not vibes.
2. **Capture actual state** — read-only, time-boxed, scripted where possible.
3. **Diff against the remembered baseline** — the delta, not the state, is the finding. Clean-and-unchanged is zero lines.
4. **Brief the deltas, ranked** — expired clocks, then stranded work, then replies, then drift. One line each: surface, what changed, what it demands. The brief recommends attention; it does not act.
5. **Hand off** — durable surprise → rem-sleep (fix the baseline); self-inflicted delta → proprioception (grade it); genuine unknown → octopus; act/defer decision → the loop.

## Principles

- **Diff, don't dump** — report change against baseline, never raw state.
- **The baseline is memory — and the sweep grades it.** Every surprise is also an error in the map; route the fix to rem-sleep.
- **Senses are read-only** — no pushes, replies, or restarts during a sweep; action goes in the brief.
- **Stale beats blind** — partial sweep now over perfect sweep never; highest-stakes surfaces first.
- **Bounded** — if the sweep becomes the day's work, prune the list or promote the hot surface to a real monitor.
- **The absence of an expected event is an event** — silence is a delta when the baseline predicted sound.
- **Functional, not mystical** — a sensory pass, not a divination ritual.
