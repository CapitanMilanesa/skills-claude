<!-- Contenido para agregar a ~/.claude/CLAUDE.md (instrucciones globales de Claude Code).
     Es la pieza que activa la auto-invocación de los skills por modelo y el anuncio
     de delegaciones a subagentes. Sin esto, skills y agentes funcionan igual pero
     hay que invocarlos a mano. -->

# fable discipline (per-model working rules)
IMPORTANT: On your FIRST response of each session — however small the request, even a one-line question — before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `fable-opus` — UNLESS the user invoked `/opus-chief` or asks Opus to orchestrate/act as chief, in which case follow `opus-chief` instead. (Nota: cuando Fable deje de estar disponible, cambiar esta línea a `Claude Opus → opus-chief`.)
- Claude Fable → `fable-chief`
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.

# git
NEVER run `git push` or any command that publishes to a remote (push, push --force, `gh pr create/merge`, `gh release`, etc.). Pushes are done exclusively by the user, by hand. Committing locally is fine when asked; after committing, tell the user it's ready to push and stop there.

# subagent routing (fixed-model delegation)
Custom subagents exist for quota-efficient delegation, available on every model (including Fable):
- `explorador` (runs on Haiku): broad code searches / "where is X, how does Y work" questions. Prefer it over exploring in the main context.
- `ejecutor` (runs on Sonnet): executing an already-written, self-contained plan (files + exact changes + verification commands).
- `revisor` (runs on Opus): deep debugging, security-sensitive review, auditing risky work. Expensive — use sparingly, only when Sonnet-level reasoning is not enough.
IMPORTANT: every time you delegate to one of these, announce it to the user in one short line BEFORE spawning, naming the target model — e.g. "→ Delegando búsqueda a `explorador` (Haiku)". In your final report, note which model did which part. If these agents are not in the available-agents list, skip silently.
