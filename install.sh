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
#    archivo del usuario nunca se toca. Un bloque legado SIN marcadores (instalaciones
#    anteriores a agosto 2026, que dejaban a Opus en fable-opus) se migra solo: backup de
#    CLAUDE.md y reemplazo del tramo legado por el bloque versionado; lo que haya antes
#    y despues del tramo queda intacto.
migrate_legacy_block() {  # $1 = CLAUDE.md, $2 = archivo con el bloque nuevo; imprime la ruta del backup
    local bak="$1.bak-$(date +%Y%m%d-%H%M%S)"
    cp -f "$1" "$bak"
    awk -v blockfile="$2" '
        function emit_block(   line) { while ((getline line < blockfile) > 0) print line; close(blockfile) }
        NR==FNR {  # pasada 1: ubicar el tramo legado
            n=NR; L[NR]=$0
            if (!hdr && $0=="# fable discipline (per-model working rules)") hdr=NR
            if ($0=="# subagent routing (fixed-model delegation)") subhdr=NR
            next
        }
        FNR==1 {
            start=hdr  # el comentario legado "Contenido para agregar..." venia pegado arriba del header
            for (i=hdr-1; i>=1 && i>=hdr-7; i--) if (L[i] ~ /^<!-- Contenido para agregar/) { start=i; break }
            anchor=(subhdr>hdr) ? subhdr : hdr  # el tramo termina donde termina la ultima seccion nuestra
            end=n
            for (i=anchor+1; i<=n; i++) if (L[i] ~ /^# / || L[i] ~ /^<!-- fable-discipline/) { end=i-1; break }
            while (end>anchor && L[end] ~ /^[[:space:]]*$/) end--
        }
        FNR<start || FNR>end { print; next }  # pasada 2: copiar lo de afuera, reemplazar el tramo
        FNR==start { emit_block() }
    ' "$1" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
    echo "$bak"
}
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
elif grep -q '^# fable discipline (per-model working rules)' "$claude_md"; then
    bak="$(migrate_legacy_block "$claude_md" "$tmp_block")"
    echo "  bloque legado SIN marcadores migrado a $repo_ver (backup: $bak)"
    echo "  Si tenias notas propias dentro de las secciones viejas (# fable discipline / # git / # subagent routing), recuperalas del backup."
else
    printf '\n' >> "$claude_md"
    cat "$tmp_block" >> "$claude_md"
    echo "  bloque global anexado a CLAUDE.md ($repo_ver)"
fi

# 5. Version de Claude Code: un CLI viejo resuelve los alias opus/sonnet/haiku a modelos de la
#    generacion anterior en silencio (2.1.212: Opus 4.8, Sonnet 5, Haiku 4.5) y ni siquiera
#    acepta los IDs 5.5, asi que toda la calibracion de los skills aplica a modelos que no corren.
cc_min="2.1.280"
if command -v claude >/dev/null 2>&1; then
    cc_ver="$( (claude --version 2>/dev/null || true) | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    if [ -n "$cc_ver" ]; then
        IFS=. read -r a1 a2 a3 <<< "$cc_ver"; IFS=. read -r b1 b2 b3 <<< "$cc_min"
        older=0
        if [ "$a1" -lt "$b1" ] || { [ "$a1" -eq "$b1" ] && [ "$a2" -lt "$b2" ]; } \
           || { [ "$a1" -eq "$b1" ] && [ "$a2" -eq "$b2" ] && [ "$a3" -lt "$b3" ]; }; then older=1; fi
        if [ "$older" = 1 ]; then
            echo "  AVISO: Claude Code $cc_ver es anterior a $cc_min: los alias opus/sonnet/haiku apuntan a modelos viejos. Corre 'claude update'."
        else
            echo "  Claude Code $cc_ver (ok, >= $cc_min)"
        fi
    fi
fi

echo ""
echo "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
