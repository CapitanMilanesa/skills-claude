---
name: handoff
description: Generate a standardized handoff package before switching models (/model) or starting a fresh session, so the next model continues with zero re-exploration. Trigger with /handoff [target-model]. Also invoke it when the user accepts an escalation/de-escalation recommendation and is about to switch.
---

# Handoff — traspaso entre modelos y sesiones

When invoked, produce a handoff package so the next session — possibly a different model, with NO access to this conversation — can continue without re-exploring or rediscovering dead ends. Do BOTH:

1. Write the package to `.claude/handoff.md` in the project root (create the directory if needed; overwrite any previous handoff).
2. Reply to the user with the 3-step instruction at the bottom.

## Package format (exact sections, in this order)

```
# Handoff — <fecha> — de <modelo actual> a <modelo destino o "próxima sesión">

## Objetivo
What the user is ultimately trying to achieve, in their own terms. One short paragraph.

## Estado
- DONE (verified): each item with its evidence ref (command run + result, test passed, file:line).
- IN PROGRESS: exactly where it stands.
- NOT STARTED: what remains untouched.

## Qué se probó y falló
One entry per failed attempt: hypothesis → what was done → exact error or evidence.
This section is the whole point — it prevents the next model from rediscovering dead ends.
If nothing failed, write "Nada".

## Archivos relevantes
path:line refs, one line each on WHY it matters. No file contents.

## Próximos pasos
Ordered, concrete, dependency-aware. Mark the recommended first action with →.

## Restricciones y decisiones ya tomadas
Decisions the user already made (the next model must NOT re-litigate them), scope
boundaries, constraints, and anything the user explicitly said no to.
```

## Rules

- **Self-contained**: assume the reader knows nothing about this conversation.
- **Facts with evidence, not impressions**: refs and outputs, not "I think it's probably".
- **Compact**: target ≤60 lines. References over quotes; never paste file contents.
- If this session had subagent reports (explorador/ejecutor/revisor), fold their *conclusions* in — don't reference the reports themselves, the next session can't see them.

## Reply to the user (after writing the file)

Exactly these steps, filling in the target:

1. `/model <destino>` (si corresponde cambiar de modelo)
2. `/clear` (o abrir chat nuevo)
3. Primer mensaje: `Leé .claude/handoff.md y continuá desde ahí.`
