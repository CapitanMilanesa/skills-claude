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

# 4. Bloque global -> ~/.claude/CLAUDE.md (versionado por marcadores <!-- fable-discipline vN -->)
#    Reemplaza SOLO lo que esta entre marcadores cuando la version cambia; el resto del
#    archivo del usuario nunca se toca. Un bloque viejo sin marcadores se avisa, no se pisa.
claude_md="$claude_dir/CLAUDE.md"
tmp_block="$(mktemp)"
trap 'rm -f "$tmp_block"' EXIT
sed -n '/<!-- fable-discipline v/,/<!-- \/fable-discipline -->/p' "$repo/CLAUDE.global.md" > "$tmp_block"
[ -s "$tmp_block" ] || { echo "ERROR: CLAUDE.global.md no tiene los marcadores fable-discipline"; exit 1; }
repo_ver="$(sed -n 's/.*<!-- fable-discipline \(v[^ ]*\) -->.*/\1/p' "$tmp_block" | head -1)"

if [ ! -f "$claude_md" ]; then
    cp -f "$tmp_block" "$claude_md"
    echo "  CLAUDE.md creado con el bloque global ($repo_ver)"
elif grep -q '<!-- fable-discipline v' "$claude_md" && grep -q '<!-- /fable-discipline -->' "$claude_md"; then
    inst_ver="$(sed -n 's/.*<!-- fable-discipline \(v[^ ]*\) -->.*/\1/p' "$claude_md" | head -1)"
    if [ "$inst_ver" = "$repo_ver" ]; then
        echo "  bloque global al dia ($repo_ver)"
    else
        awk -v blockfile="$tmp_block" '
            /<!-- fable-discipline v/ && !done { while ((getline line < blockfile) > 0) print line; close(blockfile); skip=1; done=1; next }
            skip && /<!-- \/fable-discipline -->/ { skip=0; next }
            !skip { print }
        ' "$claude_md" > "$claude_md.tmp" && mv "$claude_md.tmp" "$claude_md"
        echo "  bloque global actualizado $inst_ver -> $repo_ver (el resto de CLAUDE.md queda intacto)"
    fi
elif grep -q "fable discipline" "$claude_md"; then
    echo "  AVISO: CLAUDE.md tiene un bloque fable-discipline viejo SIN marcadores."
    echo "         Borralo a mano y re-corre este script; de ahi en adelante se actualiza solo."
else
    printf '\n' >> "$claude_md"
    cat "$tmp_block" >> "$claude_md"
    echo "  bloque global anexado a CLAUDE.md ($repo_ver)"
fi

echo ""
echo "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
