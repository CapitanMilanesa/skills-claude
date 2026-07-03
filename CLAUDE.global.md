<!-- Contenido para agregar a ~/.claude/CLAUDE.md (instrucciones globales de Claude Code).
     Es la pieza que activa la auto-invocación de los skills por modelo y el anuncio
     de delegaciones a subagentes. Sin esto, skills y agentes funcionan igual pero
     hay que invocarlos a mano. -->

# fable discipline (per-model working rules)
IMPORTANT: On the FIRST substantive task of each session, before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `fable-opus`
- Claude Fable → do NOT invoke any fable-* skill; work normally.
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.

# subagent routing (fixed-model delegation)
Two custom subagents exist for quota-efficient delegation, available on every model (including Fable):
- `explorador` (runs on Haiku): broad code searches / "where is X, how does Y work" questions. Prefer it over exploring in the main context.
- `ejecutor` (runs on Sonnet): executing an already-written, self-contained plan (files + exact changes + verification commands).
IMPORTANT: every time you delegate to one of these, announce it to the user in one short line BEFORE spawning, naming the target model — e.g. "→ Delegando búsqueda a `explorador` (Haiku)". In your final report, note which model did which part. If these agents are not in the available-agents list, skip silently.
