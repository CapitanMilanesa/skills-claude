# Test plan — validating the fleet on a real repo

Run each test in a **fresh chat** (auto-invocation depends on the `CLAUDE.md` loaded at session start). Per test, note: did it invoke the right skill? did it announce delegations naming the model? did reports respect their length caps? did it do more or less than asked?

> **Multi-project workspace:** if your workspace hosts several projects, **name the project in every prompt** so ambiguity doesn't pollute what the test measures.

## Step 0 — Setup (once, ~5 min)

1. Open the solution's root folder in your editor.
2. Clean git state (`git status`) or create a `test-claude` branch. If the project isn't under git, back up before Test 3 (the only one that edits).
3. In a `/model sonnet` chat, run **`/init`** to generate the project's `CLAUDE.md`. Review and keep it — it improves every later test and every future session.

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
  - ❌ Note if it explores itself with several of its own Grep/Read calls instead of delegating.

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
  - ✅ Invokes `fable-opus`, resumes WITHOUT re-exploring what the handoff already documents.

## Test 5 — Fable as chief (full orchestration)

Fresh chat on Fable. One multi-part task (e.g. map a flow across layers with references, spot missing validation, and propose — without implementing — the top 3 improvements).

- ✅ Invokes `fable-chief`; delegates exploration (ideally in parallel) with announcements; does NOT chain more than ~3 of its own searches; the final answer closes with which model did which part.

## Test 6 — /opus-chief (succession rehearsal)

Fresh chat → `/model opus` → `/opus-chief` → a task like Test 5's.

- ✅ Same chief behavior as Test 5, with the escalation ladder topping out at Opus.

## After

Bring observed deviations to a `skills-fable` session to tune the skill/agent wording with real data.

---

## What a first campaign tends to surface

Running the six tests end-to-end on a real repo usually converges fast (later tests pass on the first try once early fixes land). Deviations worth expecting:

- **Guardrails that fire too late.** A skill invoked on the first *big* request instead of the first response, or a guardrail that asks scoping questions before stopping. Fix: tighten the trigger wording in `CLAUDE.global.md` / the skill.
- **Delegations without a declared contract.** If the delegating model doesn't restate the agent's line cap, reports come back bloated. Fix is already in `CLAUDE.global.md` (Goal/Scope/Contract/Done template).
- **Tolerances worth accepting knowingly:** Haiku doesn't reliably count its own tool calls (a hard budget is guidance, not a mechanism — a `PostToolUse` hook is the real enforcement if you need it); the report line-cap yields to genuine inventory tasks (a 40-item list won't fit in 15 lines).
