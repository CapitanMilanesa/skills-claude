# Team quick guide

🇪🇸 [Versión en español](USAGE.es.md)

A set of skills that makes Claude work efficiently on each model and protect the weekly usage limit. Once installed, it activates on its own — you barely touch it.

## 1. Install (once)

```bash
git clone https://github.com/CapitanMilanesa/skills-claude.git
cd skills-claude
# Windows:
powershell -ExecutionPolicy Bypass -File .\install.ps1
# macOS/Linux:
bash install.sh
```
Update later: `git pull` + rerun the script.

## 2. Golden rule — pick the model for the task

Switch with `/model`. The weekly limit burns by cost: **Haiku ≪ Sonnet ≪ Opus ≪ Fable**.

| Task | Model |
|---|---|
| Renames, boilerplate, docs, running an already-written plan | `/model haiku` |
| **Day-to-day**: features, bugs, refactors, design | `/model sonnet` ← default |
| Long autonomous runs / what Sonnet couldn't crack | `/model opus` |

Rule of thumb: **start on Sonnet.** Down to Haiku for the mechanical stuff, up to Opus only when needed.

## 3. You don't invoke anything

At session start Claude detects its model and **loads its discipline on its own**. Two normal things you'll see:
- A *skill* activating at the start (`fable-sonnet`, etc.) — expected.
- Lines like `→ Delegating search to explorador (Haiku)` — Claude handed part of the work to a cheaper model on its own. Good.

## 4. The 4 commands that matter

- **`/model <model>`** — switch model.
- **`/clear`** — when you finish a task, before starting another. *Saves a lot of quota* (old context is re-paid on every message).
- **`/handoff <model>`** — before switching model mid-problem: leaves a summary so the next session doesn't re-explore.
- **`/usage`** — how much weekly limit remains.

## 5. Quota hygiene (3 tips)

1. **`/clear` between different tasks** — the single most important one.
2. Run **`/init`** once per repo (generates a `CLAUDE.md` with the architecture; sessions then start without re-exploring).
3. Mechanical and repetitive → Haiku. Don't spend Opus renaming variables.

## Heads-up

Claude **commits but never pushes** — you push by hand. And if you ask it to touch auth/payments/migrations, it stops and asks before improvising.
