# skills-fable

🇬🇧 [English version](README.en.md)

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
| `/fable-chief` | Fable | Hacer trabajo de peón con razonamiento premium; orquesta la flota de subagentes con contratos de retorno estrictos y escalado con evidencia (adaptado del charter de [pranshugupta54](https://gist.github.com/pranshugupta54/f38869565e17c72c6b07767b371c2c65)) |
| `/opus-chief` | Opus (como jefe) | Sucesor de `fable-chief` para cuando Fable no esté disponible: mismo rol de orquestador, adaptado a que Opus es a la vez decisor y razonador más profundo (la escalera de escalado termina en él; `revisor` vale por ojos frescos, no por razonamiento superior) |
| `/handoff` | cualquiera | Traspaso estandarizado al cambiar de modelo o sesión: escribe `.claude/handoff.md` con objetivo, estado verificado, **qué se probó y falló** (evita redescubrir callejones), próximos pasos y decisiones ya tomadas. En la sesión nueva: "Leé .claude/handoff.md y continuá" |

**Plan de sucesión post-Fable:** mientras Fable exista, las sesiones de Opus cargan `fable-opus` (rol especialista) y `opus-chief` se invoca a mano con `/opus-chief`. Cuando Fable deje de estar disponible, cambiar una línea en `~/.claude/CLAUDE.md`: `Claude Opus → opus-chief`.

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

Un comando (idempotente — sirve también para actualizar):

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Copia todos los skills a `~/.claude/skills/`, los agentes a `~/.claude/agents/`, y anexa el bloque de `CLAUDE.global.md` a `~/.claude/CLAUDE.md` solo si no está (si ya existe no lo pisa, para no romper ediciones propias).

## Asignación automática por modelo (recomendado)

Claude Code no tiene vinculación nativa skill↔modelo: todos los modelos ven todos los skills. La asignación se hace con una instrucción en `~/.claude/CLAUDE.md` (se carga en toda sesión, con cualquier modelo) que le ordena al modelo activo identificarse e invocar su skill:

```markdown
# fable discipline (per-model working rules)
IMPORTANT: On your FIRST response of each session — however small the request, even a one-line question — before doing anything else, check which model you are powered by and invoke the matching skill with the Skill tool, exactly once per session:
- Claude Haiku → `fable-haiku`
- Claude Sonnet → `fable-sonnet`
- Claude Opus → `fable-opus`
- Claude Fable → `fable-chief`
Then follow that skill's rules for the rest of the session. If the matching skill is not in the available-skills list, skip silently.
```

Funciona porque cada modelo sabe cuál es (está en su system prompt). Con esto, `/model sonnet` + cualquier pedido alcanza: el modelo carga `fable-sonnet` solo.

## Subagentes con modelo fijado (ruteo automático real)

Los skills solo pueden *sugerir* un `/model` — el cambio lo ejecutás vos. La única forma de ruteo multi-modelo automático son los **subagentes con modelo fijado** (carpeta `agents/`, instalados en `~/.claude/agents/`):

| Agente | Modelo | Para qué |
|---|---|---|
| `explorador` | Haiku | Búsquedas amplias de código ("dónde está X", "cómo funciona Y"). Solo lectura; devuelve conclusiones con `path:line`, nunca dumps. |
| `ejecutor` | Sonnet | Ejecutar un plan ya escrito (archivos + cambios exactos + comandos de verificación), paso a paso con verificación. Reporte ≤20 líneas; tests reportan solo fallos. |
| `revisor` | Opus | Debugging profundo, revisión sensible a seguridad, auditar trabajo riesgoso de agentes más baratos. Caro — usar solo cuando Sonnet no alcanza. Reporte ≤40 líneas, conclusión primero. |

El modelo principal los invoca solo cuando corresponde (sus `description` disparan la delegación) y, por regla del `CLAUDE.md` global, **anuncia cada delegación en una línea antes de lanzarla** — p. ej. `→ Delegando búsqueda a explorador (Haiku)` — y al final reporta qué modelo hizo qué. Así una sesión en Fable gasta Fable solo en pensar: la exploración corre en Haiku y la ejecución en Sonnet, sin comandos manuales.

Instalación: copiar `agents/*.md` a `~/.claude/agents/`.

## Uso manual (alternativa)

1. Cambiá de modelo: `/model sonnet` (o `haiku` / `opus`).
2. Al inicio de la sesión invocá el skill correspondiente: `/fable-sonnet`.
3. Trabajá normal. El skill queda cargado en contexto toda la sesión.

**Chequeos útiles:** `/model` muestra el modelo activo; `/usage` muestra cuánto límite semanal queda.

## Alternativa: siempre activo

Si preferís no invocar nada, podés pegar las reglas comunes (búsqueda barata, diff mínimo, verificación, anti-thrash) en `~/.claude/CLAUDE.md` — se cargan en toda sesión, con cualquier modelo. Costo: esos tokens se pagan en cada sesión aunque no hagan falta.
