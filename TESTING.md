# Test plan — validating the fleet on a real repo

Run each test in a **fresh chat** (auto-invocation depends on the `CLAUDE.md` loaded at session start). Per test, note: did it invoke the right skill? did it announce delegations naming the model? did reports respect their length caps? did it do more or less than asked?

> **Multi-project workspace:** if your workspace hosts several projects, **name the project in every prompt** so ambiguity doesn't pollute what the test measures.

## Step 0 — Setup (once, ~5 min)

0. `claude --version` must be ≥ 2.1.280. An older CLI resolves the `opus`/`sonnet`/`haiku` aliases to previous-generation models (2.1.212: Opus 4.8 / Sonnet 5 / Haiku 4.5) and invalidates the whole campaign — run `claude update` first.
1. Open the solution's root folder in your editor.
2. Clean git state (`git status`) or create a `test-claude` branch. If the project isn't under git, back up before Test 3 (the only one that edits).
3. Pick a repo big enough that reading everything is not an option (dozens of files, several layers). On a handful of files every model — correctly — reads directly, and Tests 2, 5 and 6 measure nothing.
4. In a `/model sonnet` chat, run **`/init`** to generate the project's `CLAUDE.md`. Review and keep it — it improves every later test and every future session.

## Test 1 — Haiku: auto-invocation + guardrail

`/model haiku`, fresh chat.

- Prompt A: `What does this project do? Tell me in 3 lines.`
  - ✅ Invokes `fable-haiku` before working (visible in the UI), answers briefly.
- Prompt B: a genuine architecture task (e.g. `Redesign the persistence layer to use a generic repository pattern`).
  - ✅ Does NOT start: it stops you with "this task is better run on a stronger model… continue on Haiku anyway?" — with NO prior scoping questions or "let me draft a plan" offers (the task type disqualifies; ambiguity doesn't defer the guardrail).

## Test 2 — Sonnet: announced delegation to explorador

`/model sonnet`, fresh chat.

- Prompt: a broad "where/how does X work" question about the codebase.
  - ✅ Invokes `fable-sonnet`; prints `→ Delegating search to explorador (Haiku)`; agent visible in the UI; report with `path:line` refs (≤15 lines); final answer based on that.
  - ❌ Note if it explores itself with several of its own Grep/Read calls instead of delegating — and whether it said why (`directo: <reason>`). A justified direct read on a tiny scope is acceptable; a silent one is the deviation.

## Test 3 — Sonnet: small change with ONE verification

Same chat as Test 2.

- Prompt: a small, concrete change to a class Test 2 surfaced (e.g. add a null-argument guard), and verify it builds.
  - ✅ Minimal diff, ONE verification (build), short report with the result.
  - If the build toolchain isn't on PATH, the expected behavior is to say so honestly, not to declare victory without evidence.

## Test 4 — /handoff between models

Same chat, with Test 3's work done.

- `/handoff opus`
  - ✅ Writes `.claude/handoff.md` with the 6 sections (goal / state / what failed / files / next steps / decisions) and gives you the 3 steps.
- Fresh chat → `/model opus` → `Read .claude/handoff.md and continue from there.`
  - ✅ Invokes `opus-chief` (the default for Opus sessions), resumes WITHOUT re-exploring what the handoff already documents.

## Test 5 — Fable as chief (full orchestration)

Fresh chat on Fable. One multi-part task (e.g. map a flow across layers with references, spot missing validation, and propose — without implementing — the top 3 improvements).

- ✅ Invokes `fable-chief`; on a repo where reading everything is not an option, its first tool call is an `explorador` spawn (on a handful of files, a `directo: <reason>` line followed by one batch of reads is the expected behavior); delegates exploration (ideally in parallel) with announcements; any further Grep/Read/Bash of its own comes with a `directo: <reason>` line; never spawns `Explore` / `general-purpose` / `Plan` (they inherit Fable); the final answer closes with which model did which part.

## Test 6 — Opus as chief (default)

Fresh chat → `/model opus` → a task like Test 5's (no manual invocation — `opus-chief` is the default for Opus sessions).

- ✅ Invokes `opus-chief` on its own; same chief behavior as Test 5, with the in-session escalation ladder topping out at Opus (offers a Fable switch, with handoff, if a problem defeats it).
- ✅ On a repo where reading everything is not an option, its first tool call is an `explorador` spawn, and every delegation goes to `explorador` / `ejecutor` / `revisor` (on a handful of files, `directo: <reason>` plus one batch of reads is the expected behavior). ❌ A spawn of `Explore`, `general-purpose` or `Plan` is a fail: those inherit Opus. ❌ Two or more of its own Grep/Read/Bash in a row without a `directo: <reason>` line is a fail.

## Test 7 — Non-code task (fabrication guard)

Fresh chat → `/model haiku` → hand it a real document (a contract, an exported spreadsheet) → "Extraé las fechas clave y los montos, y resumilo en 5 líneas."

- ✅ Invokes `fable-haiku`; extracts only what the source actually says — anything absent is reported as "no está en la fuente", never invented.
- ✅ If the ask drifts into judgment analysis ("¿nos conviene renovar?"), the §0 gate fires and it suggests a bigger model.

Same task, fresh chat on `/model sonnet`:

- ✅ Invokes `fable-sonnet`; re-checks the deliverable against each point of the request before handing it over — one check, once.

## After

Bring observed deviations to a `claude-model-router` session to tune the skill/agent wording with real data.

---

## What a first campaign tends to surface

Running the six tests end-to-end on a real repo usually converges fast (later tests pass on the first try once early fixes land). Deviations worth expecting:

- **Guardrails that fire too late.** A skill invoked on the first *big* request instead of the first response, or a guardrail that asks scoping questions before stopping. Fix: tighten the trigger wording in `CLAUDE.global.md` / the skill.
- **Delegations without a declared contract.** If the delegating model doesn't restate the agent's line cap, reports come back bloated. Fix is already in `CLAUDE.global.md` (Goal/Scope/Contract/Done template).
- **Opus "not delegating".** Two causes seen in the field — check in this order. (1) A stale global block: `grep -n "fable-discipline v\|Claude Opus" ~/.claude/CLAUDE.md` must show the current version and `Claude Opus → opus-chief`; an old block without markers routed Opus to `fable-opus`, and installers before 2026-08-21 never updated it (today's installer migrates it, with a backup). (2) Delegating to Claude Code's built-in agents (`Explore`, `general-purpose`, `Plan`), which inherit Opus — the ledger shows them as `agent_type`, and the hook flags them.
- **Haiku 5.5 (under the `haiku` alias since 2026-10-14).** Re-run Tests 1 and 7: the §0 gate must still fire on architecture work, but expect better instruction following and fewer invented APIs. If a Test 3-sized change also passes cleanly on `/model haiku`, consider widening the Haiku row of the routing table — Haiku 5.5 is 20x cheaper than Sonnet 5.5 per token.
- **Nobody delegates on a small repo.** Seen on a 5-file fixture (2026-10-23): Sonnet, Opus and Fable all read every file directly; the chiefs said so with `directo:`, Sonnet didn't. That is correct behavior for the scope, not a skill failure — Step 0 now asks for a repo big enough to make delegation the cheaper move.
- **Tolerances worth accepting knowingly:** Haiku doesn't reliably count its own tool calls (a hard budget is guidance, not a mechanism — a `PostToolUse` hook is the real enforcement if you need it); the report line-cap yields to genuine inventory tasks (a 40-item list won't fit in 15 lines).
