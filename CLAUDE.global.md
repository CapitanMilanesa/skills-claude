<!-- Contenido que el instalador mantiene dentro de ~/.claude/CLAUDE.md (instrucciones
     globales de Claude Code). El instalador maneja SOLO lo que está entre los marcadores
     fable-discipline: crea el bloque si no está, y lo reemplaza completo cuando la versión
     del marcador de apertura cambia — todo lo que el usuario tenga FUERA de los marcadores
     queda intacto. Al editar el contenido del bloque, subí la versión (v2 -> v3) para que
     el próximo install la propague. Sin esto, skills y agentes funcionan igual pero hay
     que invocarlos a mano. -->

<!-- fable-discipline v2 -->
# fable discipline (per-model working rules)
IMPORTANT: On your FIRST response of each session — however small the request, even a one-line question — before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `opus-chief` (Opus directs the fleet by default) — UNLESS the user invoked `/fable-opus` or asks for the plain specialist discipline (work directly, no orchestration), in which case follow `fable-opus` instead.
- Claude Fable → `fable-chief` (Fable es la alternativa premium explícita: se cambia a mano con `/model` cuando el problema lo amerita)
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.

# git
NEVER run `git push` or any command that publishes to a remote (push, push --force, `gh pr create/merge`, `gh release`, etc.). Pushes are done exclusively by the user, by hand. Committing locally is fine when asked; after committing, tell the user it's ready to push and stop there.

# subagent routing (fixed-model delegation)
Custom subagents exist for quota-efficient delegation, available on every model (including Fable):
- `explorador` (runs on Haiku): broad searches over code, documents, or data / "where is X, how does Y work" questions. Prefer it over exploring in the main context.
- `ejecutor` (runs on Sonnet): executing an already-written, self-contained plan (files + exact changes + verification commands).
- `revisor` (runs on Opus): deep debugging, security-sensitive review, auditing risky work (code or high-stakes documents/analyses). Expensive — use sparingly, only when Sonnet-level reasoning is not enough.
IMPORTANT: every time you delegate to one of these, announce it to the user in one short line BEFORE spawning, naming the target model — e.g. "→ Delegando búsqueda a `explorador` (Haiku)". In your final report, note which model did which part. If these agents are not in the available-agents list, skip silently.
Delegation rules (all models): (1) structure every delegation prompt as exactly Goal (one sentence) / Scope (in bounds and OUT of bounds) / Contract (the agent's return format — RESTATE its line cap explicitly: explorador ≤15, ejecutor ≤20, revisor ≤40, tests failures-only) / Done means. (2) After spawning an agent, WAIT for its report — never run your own overlapping searches or reads in parallel with work you just delegated; that pays twice.
<!-- /fable-discipline -->
