# skills-fable

🇪🇸 [Versión en español](README.es.md) · 👥 [Team quick guide](USAGE.md)

Working-discipline skills for running Opus, Sonnet and Haiku in Claude Code with Fable-level efficiency — and protecting your weekly usage limit.

> New to this and just want to use it? Read the **[team quick guide](USAGE.md)** — one page. The rest of this README is the how-and-why.

## The idea

Weekly usage is consumed weighted by model cost: **Haiku ≪ Sonnet ≪ Opus ≪ Fable**. The cheapest way to work is not just "use the small model", but:

1. **Route each task to the cheapest model that solves it well** (failing for 40 turns on Haiku costs more than one clean Sonnet run).
2. **Enforce Fable-grade process discipline** on whichever model runs: search before reading, read ranges instead of whole files, parallel tool calls, minimal diffs, verify before declaring "done", and stop instead of looping.

Each skill is self-contained and calibrated to its model's typical failure modes:

| Skill | Model | Mainly corrects |
|---|---|---|
| `/fable-haiku` | Haiku | Invents APIs, gets stuck in loops, takes on tasks above its weight class |
| `/fable-sonnet` | Sonnet | Declares victory without verifying, over-explores / over-edits |
| `/fable-opus` | Opus | Over-engineering, exploration without a timebox, not handing mechanical work back to cheaper models |
| `/fable-chief` | Fable | Doing grunt work with premium reasoning; orchestrates the subagent fleet with strict return contracts and evidence-carrying escalation (adapted from [pranshugupta54's charter](https://gist.github.com/pranshugupta54/f38869565e17c72c6b07767b371c2c65)) |
| `/opus-chief` | Opus (as chief) | The default chief for Opus sessions: same orchestrator role as `fable-chief`, adapted to Opus being both the decision-maker and the deepest reasoner in the fleet (the in-session escalation ladder tops out at it; `revisor` buys fresh eyes, not deeper reasoning) |
| `/handoff` | any | Standardized handoff when switching models or sessions: writes `.claude/handoff.md` with the goal, verified state, **what was tried and failed** (prevents rediscovering dead ends), next steps, and decisions already made. In the new session: "Read .claude/handoff.md and continue from there" |

**Default scheme:** Opus sessions load `opus-chief` (Opus directs the fleet); `fable-opus` stays available via `/fable-opus` for plain specialist sessions without orchestration. Fable is the explicit premium alternative — switch with `/model` and `fable-chief` takes over.

## Task routing (quick guide — Sonnet 5)

With **Sonnet 5** (Claude 5 family) routing gets simpler: near-Opus quality on coding and agentic work at $3/$15 per MTok. Opus's niche shrank a lot — and **Opus 5.5** ($4/$20, down from Opus 5's $5/$25, and fewer tokens per solved task) narrows the cost gap back somewhat, so the Opus row below is less of a luxury than it was.

Consumption note: Sonnet 5 uses a new tokenizer (~30% more tokens for the same text vs 4.6) and ships with adaptive thinking on by default — if you compare versions in `/usage`, that gap is expected and doesn't mean it's overworking.

Opus 5.5 note: at `medium` effort it matches or beats Opus 5 at `high` with about half the tokens, and at `xhigh`/`max` it thinks longer per turn than Opus 5 did. Don't carry an effort setting tuned for Opus 5 into Opus 5.5 sessions — start at `medium`.

| Task | Model |
|---|---|
| Renames, boilerplate, repetitive edits, docs, tests that mirror existing tests, executing an already-written plan | **Haiku** (`/model haiku`) |
| Almost everything else: features, bugs (with or without repro), refactors, design, concurrency — what used to go to Opus | **Sonnet 5** (`/model sonnet`) |
| Very long autonomous runs (overnight, massive unsupervised refactors) | **Opus** (`/model opus`) |
| Only what survived two well-specified attempts on Sonnet, or maximum-complexity critical work | **Fable** |

The pattern that saves the most: **the expensive model writes the plan → Sonnet/Haiku execute it** — and today, for most plans, "the expensive model" can also be Sonnet 5. The skills include instructions to propose that escalation/de-escalation on their own.

## Installation

One command (idempotent — also how you update):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Copies every skill to `~/.claude/skills/`, the agents to `~/.claude/agents/`, and keeps the `CLAUDE.global.md` block inside `~/.claude/CLAUDE.md` up to date: the block lives between versioned `<!-- fable-discipline vN -->` markers, so the installer replaces it whenever the repo bumps the version — and never touches anything you keep outside the markers. (A legacy block without markers is reported, not overwritten: delete it once, re-run, and from then on it updates itself.)

On macOS/Linux: `bash install.sh` (mirror of the PowerShell installer).

## Automatic per-model assignment (recommended)

Claude Code has no native skill↔model binding: every model sees every skill. The assignment is done with an instruction in `~/.claude/CLAUDE.md` (loaded into every session, on any model) ordering the active model to identify itself and invoke its skill:

```markdown
# fable discipline (per-model working rules)
IMPORTANT: On your FIRST response of each session — however small the request, even a one-line question — before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `opus-chief`
- Claude Fable → `fable-chief`
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.
```

It works because every model knows which one it is (it's in its system prompt). With this in place, `/model sonnet` plus any request is enough: the model loads `fable-sonnet` on its own.

## Fixed-model subagents (real automatic routing)

Skills can only *suggest* a `/model` switch — you execute it. The only genuinely automatic multi-model routing is **subagents with a pinned model** (`agents/` folder, installed to `~/.claude/agents/`):

| Agent | Model | Purpose |
|---|---|---|
| `explorador` (scout) | Haiku | Broad code searches ("where is X", "how does Y work"). Read-only; returns conclusions as `path:line` refs, never file dumps. |
| `ejecutor` (executor) | Sonnet | Executes an already-written plan (files + exact changes + verification commands), step by step with verification. Report ≤20 lines; tests report failures only. |
| `revisor` (reviewer) | Opus | Deep debugging, security-sensitive review, auditing risky work from cheaper agents. Expensive — only when Sonnet-level reasoning isn't enough. Report ≤40 lines, conclusion first. |

The main model invokes them on its own when appropriate (their `description` fields trigger the delegation) and, per the global `CLAUDE.md` rule, **announces every delegation in one line before spawning** — e.g. `→ Delegating search to explorador (Haiku)` — and reports at the end which model did which part. That way a Fable session spends Fable only on thinking: exploration runs on Haiku and execution on Sonnet, with no manual commands.

Installation: copy `agents/*.md` to `~/.claude/agents/`.

## Observability hook (optional)

A delegation ledger: logs one JSONL line per subagent run to `~/.claude/delegation-log.jsonl` with clean metrics — which agent ran, how many lines its report had, its contract cap, and whether it went over. When a report exceeds its cap it also prints a one-line warning (only on the violation — signal, not noise). It's **observability only** — never blocks, never fails a turn. (Hard "enforce the cap by re-running the agent" was considered and dropped: re-running a subagent to trim a report costs far more quota than reading the long report once. The caps live in the agent prompts; this hook makes violations *visible* and *countable*.)

`install.ps1` / `install.sh` copy the script to `~/.claude/hooks/`, but do **not** touch your `settings.json` (auto-editing someone's settings is riskier than it's worth). To activate, add this to `~/.claude/settings.json` under `hooks` (use `python3` on macOS/Linux):

```json
"SubagentStop": [
  { "hooks": [ { "type": "command", "command": "python \"$HOME/.claude/hooks/log-delegation.py\"", "shell": "bash", "timeout": 10 } ] }
]
```

Changes to `settings.json` are picked up on the next session (or after opening `/hooks` once).

## Manual use (alternative)

1. Switch models: `/model sonnet` (or `haiku` / `opus`).
2. At session start, invoke the matching skill: `/fable-sonnet`.
3. Work normally. The skill stays loaded in context for the whole session.

**Useful checks:** `/model` shows the active model; `/usage` shows how much weekly limit remains.

## Alternative: always-on

If you'd rather not invoke anything, you can paste the shared rules (cheap search, minimal diff, verification, anti-thrash) into `~/.claude/CLAUDE.md` — they load in every session, on any model. Cost: those tokens are paid in every session even when not needed.

---

*Auxiliary docs (comments in `install.ps1` / `CLAUDE.global.md`) are in Spanish; the skill and agent definitions themselves are in English.*

## License

[MIT](LICENSE) — use it however you like.
