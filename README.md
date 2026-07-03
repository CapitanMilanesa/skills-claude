# skills-fable

Skills de disciplina de trabajo para usar Opus, Sonnet y Haiku en Claude Code con la eficiencia de Fable, y así cuidar el límite semanal de uso.

## La idea

El límite semanal se consume ponderado por el costo del modelo: **Haiku ≪ Sonnet ≪ Opus ≪ Fable**. La forma más barata de trabajar no es solo "usar el modelo chico", sino:

1. **Rutear cada tarea al modelo más barato que la resuelve bien** (fallar 40 turnos en Haiku sale más caro que resolverla de una en Sonnet).
2. **Imponer la disciplina de proceso de Fable** en el modelo que sea: buscar antes de leer, leer solo rangos, llamadas paralelas, diffs mínimos, verificar antes de declarar "listo", y cortar en vez de insistir en loop.

Cada skill es autocontenido y está calibrado a los modos de falla típicos de su modelo:

| Skill | Modelo | Corrige principalmente |
|---|---|---|
| `/fable-haiku` | Haiku | Inventa APIs, se traba en loops, encara tareas que le quedan grandes |
| `/fable-sonnet` | Sonnet | Declara victoria sin verificar, explora/edita de más |
| `/fable-opus` | Opus | Sobre-ingeniería, exploración sin timebox, no devuelve el trabajo mecánico a modelos baratos |

## Ruteo de tareas (guía rápida — Sonnet 5)

Con **Sonnet 5** (familia Claude 5) el ruteo se simplifica: alcanza calidad casi-Opus en código y trabajo agéntico a $3/$15 por MTok vs $5/$25 de Opus 4.8 (precio introductorio $2/$10 hasta el 31/08/2026). El nicho de Opus se achicó mucho.

Nota de consumo: Sonnet 5 usa un tokenizador nuevo (~30% más tokens por el mismo texto que 4.6) y trae thinking adaptativo activado por defecto — si comparás consumos entre versiones en `/usage`, esa diferencia es esperable y no significa que esté trabajando de más.

| Tarea | Modelo |
|---|---|
| Renames, boilerplate, ediciones repetitivas, docs, tests que copian tests existentes, ejecutar un plan ya escrito | **Haiku** (`/model haiku`) |
| Casi todo lo demás: features, bugs (con o sin repro), refactors, diseño, concurrencia — lo que antes iba a Opus | **Sonnet 5** (`/model sonnet`) |
| Corridas autónomas muy largas (overnight, refactors masivos sin supervisión) | **Opus** (`/model opus`) |
| Solo lo que sobrevivió dos intentos bien especificados en Sonnet, o trabajo crítico de máxima complejidad | **Fable** |

Patrón que más ahorra: **el modelo caro escribe el plan → Sonnet/Haiku lo ejecutan** — y hoy, para la mayoría de los planes, "el modelo caro" también puede ser Sonnet 5. Los tres skills incluyen instrucciones para proponer ese escalado/des-escalado solos.

## Instalación

Tres piezas — skills, subagentes y el bloque de configuración global:

```powershell
# 1. Skills → ~/.claude/skills/
Copy-Item -Recurse -Force .\fable-haiku, .\fable-sonnet, .\fable-opus "$HOME\.claude\skills\"

# 2. Subagentes con modelo fijado → ~/.claude/agents/
New-Item -ItemType Directory -Force "$HOME\.claude\agents" | Out-Null
Copy-Item -Force .\agents\*.md "$HOME\.claude\agents\"

# 3. Bloque global (auto-invocación + anuncio de delegaciones):
#    agregar el contenido de CLAUDE.global.md al final de ~/.claude/CLAUDE.md
Get-Content .\CLAUDE.global.md | Add-Content "$HOME\.claude\CLAUDE.md"
```

## Asignación automática por modelo (recomendado)

Claude Code no tiene vinculación nativa skill↔modelo: todos los modelos ven todos los skills. La asignación se hace con una instrucción en `~/.claude/CLAUDE.md` (se carga en toda sesión, con cualquier modelo) que le ordena al modelo activo identificarse e invocar su skill:

```markdown
# fable discipline (per-model working rules)
IMPORTANT: On the FIRST substantive task of each session, before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `fable-opus`
- Claude Fable → do NOT invoke any fable-* skill; work normally.
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.
```

Funciona porque cada modelo sabe cuál es (está en su system prompt). Con esto, `/model sonnet` + cualquier pedido alcanza: el modelo carga `fable-sonnet` solo.

## Subagentes con modelo fijado (ruteo automático real)

Los skills solo pueden *sugerir* un `/model` — el cambio lo ejecutás vos. La única forma de ruteo multi-modelo automático son los **subagentes con modelo fijado** (carpeta `agents/`, instalados en `~/.claude/agents/`):

| Agente | Modelo | Para qué |
|---|---|---|
| `explorador` | Haiku | Búsquedas amplias de código ("dónde está X", "cómo funciona Y"). Solo lectura; devuelve conclusiones con `path:line`, nunca dumps. |
| `ejecutor` | Sonnet | Ejecutar un plan ya escrito (archivos + cambios exactos + comandos de verificación), paso a paso con verificación. |

El modelo principal los invoca solo cuando corresponde (sus `description` disparan la delegación) y, por regla del `CLAUDE.md` global, **anuncia cada delegación en una línea antes de lanzarla** — p. ej. `→ Delegando búsqueda a explorador (Haiku)` — y al final reporta qué modelo hizo qué. Así una sesión en Fable gasta Fable solo en pensar: la exploración corre en Haiku y la ejecución en Sonnet, sin comandos manuales.

Instalación: copiar `agents/*.md` a `~/.claude/agents/`.

## Uso manual (alternativa)

1. Cambiá de modelo: `/model sonnet` (o `haiku` / `opus`).
2. Al inicio de la sesión invocá el skill correspondiente: `/fable-sonnet`.
3. Trabajá normal. El skill queda cargado en contexto toda la sesión.

**Chequeos útiles:** `/model` muestra el modelo activo; `/usage` muestra cuánto límite semanal queda.

## Alternativa: siempre activo

Si preferís no invocar nada, podés pegar las reglas comunes (búsqueda barata, diff mínimo, verificación, anti-thrash) en `~/.claude/CLAUDE.md` — se cargan en toda sesión, con cualquier modelo. Costo: esos tokens se pagan en cada sesión aunque no hagan falta.
