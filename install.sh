#!/usr/bin/env bash
# install.sh - instala/actualiza skills, agentes, hooks y el bloque global de CLAUDE.md.
# Idempotente: se puede correr las veces que haga falta (tambien para actualizar).
# Espejo de install.ps1 para macOS/Linux.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_dir="$HOME/.claude"

# 1. Skills -> ~/.claude/skills/
mkdir -p "$claude_dir/skills"
for skill_md in "$repo"/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    name="$(basename "$(dirname "$skill_md")")"
    mkdir -p "$claude_dir/skills/$name"
    cp -f "$skill_md" "$claude_dir/skills/$name/SKILL.md"
    echo "  skill   $name"
done

# 2. Agentes -> ~/.claude/agents/
if [ -d "$repo/agents" ]; then
    mkdir -p "$claude_dir/agents"
    for a in "$repo"/agents/*.md; do
        [ -f "$a" ] || continue
        cp -f "$a" "$claude_dir/agents/"
        echo "  agente  $(basename "${a%.md}")"
    done
fi

# 3. Hooks (scripts) -> ~/.claude/hooks/  (solo copia; NO toca settings.json)
if [ -d "$repo/hooks" ]; then
    mkdir -p "$claude_dir/hooks"
    for h in "$repo"/hooks/*.py; do
        [ -f "$h" ] || continue
        cp -f "$h" "$claude_dir/hooks/"
        echo "  hook    $(basename "$h") (activar a mano en settings.json - ver README; usar python3)"
    done
fi

# 4. Bloque global -> ~/.claude/CLAUDE.md (solo si no esta ya)
claude_md="$claude_dir/CLAUDE.md"
if [ ! -f "$claude_md" ]; then
    cp -f "$repo/CLAUDE.global.md" "$claude_md"
    echo "  CLAUDE.md creado con el bloque global"
elif ! grep -q "fable discipline" "$claude_md"; then
    printf '\n' >> "$claude_md"
    cat "$repo/CLAUDE.global.md" >> "$claude_md"
    echo "  bloque global anexado a CLAUDE.md"
else
    echo "  CLAUDE.md ya tiene el bloque global (no se pisa; si cambio en el repo, actualizalo a mano)"
fi

echo ""
echo "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
