# skills-fable

🇪🇸 [Versión en español](README.md)

Working-discipline skills for running Opus, Sonnet and Haiku in Claude Code with Fable-level efficiency — and protecting your weekly usage limit.

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
| `/opus-chief` | Opus (as chief) | Successor to `fable-chief` for when Fable is no longer available: same orchestrator role, adapted to Opus being both the decision-maker and the deepest reasoner (the escalation ladder tops out at it; `revisor` buys fresh eyes, not deeper reasoning) |
| `/handoff` | any | Standardized handoff when switching models or sessions: writes `.claude/handoff.md` with the goal, verified state, **what was tried and failed** (prevents rediscovering dead ends), next steps, and decisions already made. In the new session: "Read .claude/handoff.md and continue from there" |

**Post-Fable succession plan:** while Fable exists, Opus sessions load `fable-opus` (specialist role) and `opus-chief` is invoked manually with `/opus-chief`. When Fable is retired, change one line in `~/.claude/CLAUDE.md`: `Claude Opus → opus-chief`.

## Task routing (quick guide — Sonnet 5)

With **Sonnet 5** (Claude 5 family) routing gets simpler: near-Opus quality on coding and agentic work at $3/$15 per MTok vs Opus 4.8's $5/$25 (introductory $2/$10 pricing through 2026-08-31). Opus's niche shrank a lot.

Consumption note: Sonnet 5 uses a new tokenizer (~30% more tokens for the same text vs 4.6) and ships with adaptive thinking on by default — if you compare versions in `/usage`, that gap is expected and doesn't mean it's overworking.

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

Copies every skill to `~/.claude/skills/`, the agents to `~/.claude/agents/`, and appends the `CLAUDE.global.md` block to `~/.claude/CLAUDE.md` only if it's not already there (it never overwrites an existing block, so your own edits are safe).

On macOS/Linux there's no installer script yet — copy each `<skill>/SKILL.md` folder to `~/.claude/skills/`, `agents/*.md` to `~/.claude/agents/`, and append `CLAUDE.global.md` to `~/.claude/CLAUDE.md` by hand.

## Automatic per-model assignment (recommended)

Claude Code has no native skill↔model binding: every model sees every skill. The assignment is done with an instruction in `~/.claude/CLAUDE.md` (loaded into every session, on any model) ordering the active model to identify itself and invoke its skill:

```markdown
# fable discipline (per-model working rules)
IMPORTANT: On your FIRST response of each session — however small the request, even a one-line question — before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `fable-opus`
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

## Manual use (alternative)

1. Switch models: `/model sonnet` (or `haiku` / `opus`).
2. At session start, invoke the matching skill: `/fable-sonnet`.
3. Work normally. The skill stays loaded in context for the whole session.

**Useful checks:** `/model` shows the active model; `/usage` shows how much weekly limit remains.

## Alternative: always-on

If you'd rather not invoke anything, you can paste the shared rules (cheap search, minimal diff, verification, anti-thrash) into `~/.claude/CLAUDE.md` — they load in every session, on any model. Cost: those tokens are paid in every session even when not needed.

---

*Auxiliary docs (`TESTING.md`, comments in `install.ps1` / `CLAUDE.global.md`) are in Spanish; the skill and agent definitions themselves are in English.*
