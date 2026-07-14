# Exteroception — a Claude Code skill

The **wake-sense organ** of the [agent-nervous-system](https://github.com/thdelmas/agent-nervous-system) suite — the sense of the world the agent acts in, taken at wake as a **diff against what memory says the world looked like**.

An agent's memory is write-time-stale: it records the world as it was when last written, and the world kept moving while the agent slept — a repo got pushed from another session or sits stranded with unpushed work, an awaited reply landed (or pointedly didn't), a deadline expired quietly, a service fell over, a forecast came due. A blind agent discovers these mid-task, at the worst moment, or never. Exteroception is the wake ritual that closes the gap: sweep the watched surfaces, diff actual state against remembered state, brief the deltas ranked by urgency.

It is the **paired sense** to [proprioception](https://github.com/thdelmas/proprioception): the same mechanism — a diff against a stored baseline — pointed in opposite directions (self-in-motion ↔ world-at-wake). And it is the sensory input of the [consciousness-loop](https://github.com/thdelmas/consciousness-loop)'s wake phase: deciding before sensing is guessing.

## What it is not

- **Not octopus** — [octopus](https://github.com/thdelmas/open-source-octopus-investigation) explores the far field (discover what you didn't know existed); exteroception sweeps the near field (diff what you already watch). Foraging vs checking the campsite.
- **Not rem-sleep** — [rem-sleep](https://github.com/thdelmas/rem-sleep) runs at sleep and updates the map; exteroception runs at wake and checks the territory. They bookend the loop.
- **Not proprioception** — that organ diffs the *self* (intended vs actual performance); this one diffs the *environment* (remembered vs actual world).
- **Not monitoring** — a monitor watches one signal continuously; exteroception sweeps all watched surfaces once, at wake, cheaply.

## Install

Works with **Claude Code**, **Codex**, and **Cursor**.

```bash
git clone https://github.com/thdelmas/exteroception.git
cd exteroception
```

### Claude Code

```bash
mkdir -p ~/.claude/skills/exteroception
cp -r SKILL.md scripts ~/.claude/skills/exteroception/
```

Invoke with `/exteroception`, or say *"what changed since last session?"* / *"wake sweep"* / *"orient me"*.

### Codex

```bash
mkdir -p ~/.agents/skills/exteroception
cp -r SKILL.md scripts ~/.agents/skills/exteroception/
```

### Cursor

```bash
mkdir -p ~/.cursor/commands
cp cursor/exteroception.md ~/.cursor/commands/
```

## The sweep cycle

1. **Enumerate the watched surfaces** — an explicit, small list: working trees, conversations, clocks, services, due forecasts.
2. **Capture actual state** — read-only, time-boxed, scripted where possible ([`scripts/git-sweep.sh`](./scripts/git-sweep.sh) covers the working-trees surface in one pass).
3. **Diff against the remembered baseline** — the delta, not the state, is the finding.
4. **Brief the deltas, ranked** — expired clocks, stranded work, replies, drift. The brief recommends attention; it does not act.
5. **Hand off** — durable surprises to rem-sleep, self-inflicted deltas to proprioception, unknowns to octopus, the act/defer decision to the loop.

```bash
./scripts/git-sweep.sh ~/work            # only repos with deltas print
./scripts/git-sweep.sh --fetch ~/work    # refresh remotes first (network)
```

See [`SKILL.md`](./SKILL.md) for the watched-surfaces doctrine and the full principles.

## License

MIT
