---
name: exteroception
description: "The wake-sense organ — the agent's sense of the world it acts in, taken at wake as a diff against what memory says the world looked like. Every session starts blind: memory is write-time-stale and the world moved while you slept — repos pushed or stranded, replies landed or didn't, clocks expired, services died. Exteroception sweeps the watched surfaces (working trees, inboxes, deadlines, services, due forecasts), diffs actual state against remembered state, and briefs the deltas ranked by urgency — so the session starts oriented instead of discovering the world mid-task. Read-only: senses never mutate. The paired sense to proprioception (self-in-motion ↔ world-at-wake) and the sensory input of the consciousness-loop's wake phase. Functional, not mystical. TRIGGERS: 'exteroception', 'wake sweep', 'morning sweep', 'what changed', 'what changed since last session', 'world diff', 'sweep the world', 'orient me', 'session-start briefing', 'what moved', 'what did I miss while I was gone'."
---

# Exteroception — sense the world at wake, as a diff against memory

The nervous system has senses pointed at the self in motion ([proprioception](https://github.com/thdelmas/proprioception)), at its own memory ([rem-sleep](https://github.com/thdelmas/rem-sleep)), at its boundary ([immune-check](https://github.com/thdelmas/immune-check)), and at the far unknown ([octopus](https://github.com/thdelmas/open-source-octopus-investigation)). It is missing the one every animal wakes with: the sense of the **near field** — the environment the agent actually operates in, as it is *right now*.

Without it, every session starts blind. An agent's memory is **write-time-stale**: it records the world as it was when last written, and the world kept moving — a repo got pushed from another session or is sitting stranded with unpushed work, a reply you were waiting on landed (or pointedly didn't), a deadline expired quietly, a service fell over, a forecast came due. A blind agent discovers these mid-task, at the worst possible moment, or never. Exteroception is the wake ritual that closes the gap: **capture the actual state of the watched surfaces, diff it against the remembered state, and brief the deltas** — so orientation happens at wake, on purpose, instead of by ambush.

## What it is not

- **Not octopus.** Octopus explores the **far field** — discover what you didn't know existed, following curiosity outward through the social graph. Exteroception sweeps the **near field** — diff the surfaces you already watch. Foraging vs checking the campsite. If a sweep turns up a genuine unknown worth exploring, that's a handoff to octopus, not a longer sweep.
- **Not rem-sleep.** Rem-sleep runs at **sleep** and points at memory: consolidate what was experienced into the baseline. Exteroception runs at **wake** and points at the world: diff reality against that baseline. They bookend the loop — sleep writes the baseline, wake reads against it. One updates the map; the other checks the territory.
- **Not proprioception.** Proprioception senses the **self** — intended vs actual performance. Exteroception senses the **environment** — remembered vs actual world. Same mechanism, a diff against a stored baseline, pointed in opposite directions: the paired senses. They also hand off: a stranded push found by the sweep is an environmental fact *and* an execution error to grade.
- **Not the loop.** The [consciousness-loop](https://github.com/thdelmas/consciousness-loop) decides what deserves attention this tick; exteroception supplies the sensory input that decision runs on. The loop's wake phase schedules the sweep first — deciding before sensing is guessing.
- **Not monitoring.** A monitor watches one signal continuously and fires on threshold. Exteroception sweeps **all** watched surfaces **once, at wake, cheaply**. Monitors are for the things too urgent to wait for a wake; exteroception is for everything else.

## The watched surfaces

Keep an explicit, small list of what you actually depend on. Typical surfaces:

- **Working trees** — every repo you touch: dirty files, unpushed commits (stranded work), behind-upstream, detached heads. `scripts/git-sweep.sh` captures this in one pass.
- **Conversations** — inboxes and threads where you're awaiting a reply or owe one. The *absence* of an expected reply past its horizon is a delta too.
- **Clocks** — deadlines, renewal dates, decision points within the horizon (e.g. 7 days). An expired clock outranks everything else in the brief.
- **Services** — hosts, daemons, cron jobs, CI that must be alive for your work to mean anything.
- **Due forecasts** — proprioception's forecast ledger: anything past its resolve-by date gets surfaced for resolution.

A surface you never act on is noise — drop it. A surprise that arrived through *no* surface means the list has a hole — add one.

## The sweep cycle

### 1. Enumerate the watched surfaces

From the explicit list, not from vibes. The list itself is part of memory; sweep what it names.

### 2. Capture actual state

Read-only, time-boxed, scripted where possible. A sense that takes as long as the work it orients is not a sense.

### 3. Diff against the remembered baseline

The baseline is what memory claims: the index, last session's notes, the recorded clocks and expectations. The delta — not the state — is the finding. "Repo X: clean, pushed, unchanged" is zero lines; "repo X: 2 commits stranded since last session" is the signal.

### 4. Brief the deltas, ranked

Expired clocks first, then stranded work, then landed/missing replies, then staleness and drift. One line per delta: surface, what changed, what it likely demands. The brief is an input to the loop's decide step — it recommends attention, it does not act.

### 5. Hand off

- A **durable surprise** (the world differs from memory in a way that will matter again) → rem-sleep, to fix the baseline.
- A **self-inflicted delta** (the stranded push was your own landing failure) → proprioception, to grade and correct.
- A **genuine unknown** worth exploring → octopus.
- The **act/defer decision** on everything briefed → the loop. Sensing ends where deciding begins.

## Principles

- **Diff, don't dump.** Report change against baseline, not raw state. A sweep that prints everything orients nobody.
- **The baseline is memory — and the sweep grades it.** Every surprise is simultaneously news about the world and an error in the map. Route the map-fix to rem-sleep; a baseline nobody corrects makes every future sweep noisier.
- **Senses are read-only.** A sweep never mutates — no pushes, no replies, no restarts. Anything that needs action goes in the brief. The moment sensing starts acting, you can no longer trust what it reports.
- **Stale beats blind.** A partial sweep now beats a perfect sweep never. Time-box it; sweep the highest-stakes surfaces first so truncation costs least.
- **Bounded.** The sweep serves the wake. If it becomes the day's work, the surface list is too big — prune it, or promote the hot surface to a real monitor.
- **The absence of an expected event is an event.** No reply past the horizon, a cron that didn't fire, a repo untouched that should have moved — silence is a delta when the baseline predicted sound.
- **Functional, not mystical.** State capture and diffing with discipline — a sensory pass, not a divination ritual.
