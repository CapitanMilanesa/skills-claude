# install.ps1 - instala/actualiza los skills, agentes y bloque global de CLAUDE.md
# Idempotente: se puede correr las veces que haga falta (tambien para actualizar).
$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot
$claudeDir = Join-Path $HOME ".claude"

# 1. Skills -> ~/.claude/skills/
$skillsDir = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force $skillsDir | Out-Null
$skills = Get-ChildItem $repo -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }
foreach ($s in $skills) {
    $target = Join-Path $skillsDir $s.Name
    New-Item -ItemType Directory -Force $target | Out-Null
    Copy-Item -Force (Join-Path $s.FullName "SKILL.md") (Join-Path $target "SKILL.md")
    Write-Host ("  skill   " + $s.Name)
}

# 2. Agentes -> ~/.claude/agents/
$agentsDir = Join-Path $claudeDir "agents"
New-Item -ItemType Directory -Force $agentsDir | Out-Null
Get-ChildItem (Join-Path $repo "agents") -Filter *.md | ForEach-Object {
    Copy-Item -Force $_.FullName $agentsDir
    Write-Host ("  agente  " + $_.BaseName)
}

# 3. Hooks (scripts) -> ~/.claude/hooks/  (solo copia los scripts; NO toca settings.json)
$hooksSrc = Join-Path $repo "hooks"
if (Test-Path $hooksSrc) {
    $hooksDir = Join-Path $claudeDir "hooks"
    New-Item -ItemType Directory -Force $hooksDir | Out-Null
    Get-ChildItem $hooksSrc -Filter *.py | ForEach-Object {
        Copy-Item -Force $_.FullName $hooksDir
        Write-Host ("  hook    " + $_.Name + " (activar a mano en settings.json - ver README)")
    }
}

# 4. Bloque global -> ~/.claude/CLAUDE.md (versionado por marcadores <!-- fable-discipline vN -->)
#    Reemplaza SOLO lo que esta entre marcadores cuando la version cambia; el resto del
#    archivo del usuario nunca se toca. Un bloque legado SIN marcadores (instalaciones
#    anteriores a agosto 2026, que dejaban a Opus en fable-opus) se migra solo: backup de
#    CLAUDE.md y reemplazo del tramo legado por el bloque versionado; lo que haya antes
#    y despues del tramo queda intacto.
#    Lectura/escritura via .NET: UTF-8 con o sin BOM (Get-Content -Raw asume ANSI si no hay BOM
#    y rompe los acentos al reescribir).
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Migrate-LegacyBlock($path, $block) {  # devuelve la ruta del backup
    $bak = "$path.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -Force $path $bak
    $lines = [System.IO.File]::ReadAllLines($path)
    $hdr = -1; $subHdr = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($hdr -lt 0 -and $lines[$i] -eq '# fable discipline (per-model working rules)') { $hdr = $i }
        if ($lines[$i] -eq '# subagent routing (fixed-model delegation)') { $subHdr = $i }
    }
    # El comentario legado "Contenido para agregar..." venia pegado arriba del header.
    $start = $hdr
    for ($i = $hdr - 1; $i -ge 0 -and $i -ge $hdr - 7; $i--) {
        if ($lines[$i] -like '<!-- Contenido para agregar*') { $start = $i; break }
    }
    # El tramo termina donde termina la ultima seccion nuestra (siguiente header nivel 1 o fin de archivo).
    $anchor = $hdr; if ($subHdr -gt $hdr) { $anchor = $subHdr }
    $end = $lines.Count - 1
    for ($i = $anchor + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^# ' -or $lines[$i] -match '^<!-- fable-discipline') { $end = $i - 1; break }
    }
    while ($end -gt $anchor -and $lines[$end] -match '^\s*$') { $end-- }
    $before = @(); if ($start -gt 0) { $before = $lines[0..($start - 1)] }
    $after = @(); if ($end -lt $lines.Count - 1) { $after = $lines[($end + 1)..($lines.Count - 1)] }
    $out = @($before) + @($block -split "`r?`n") + @($after)
    [System.IO.File]::WriteAllText($path, (($out -join [Environment]::NewLine) + [Environment]::NewLine), $utf8NoBom)
    return $bak
}
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
$globalRaw = [System.IO.File]::ReadAllText((Join-Path $repo "CLAUDE.global.md"))
$blockRe = '(?s)<!-- fable-discipline v[^ ]+ -->.*?<!-- /fable-discipline -->'
$mRepo = [regex]::Match($globalRaw, $blockRe)
if (-not $mRepo.Success) { throw "CLAUDE.global.md no tiene los marcadores fable-discipline" }
$block = $mRepo.Value
$repoVer = [regex]::Match($block, 'fable-discipline (v[^ ]+)').Groups[1].Value

if (-not (Test-Path $claudeMd)) {
    [System.IO.File]::WriteAllText($claudeMd, $block + [Environment]::NewLine, $utf8NoBom)
    Write-Host "  CLAUDE.md creado con el bloque global ($repoVer)"
} else {
    $current = [System.IO.File]::ReadAllText($claudeMd)
    $mInst = [regex]::Match($current, $blockRe)
    if ($mInst.Success) {
        $instVer = [regex]::Match($mInst.Value, 'fable-discipline (v[^ ]+)').Groups[1].Value
        if ($instVer -eq $repoVer) {
            Write-Host "  bloque global al dia ($repoVer)"
        } else {
            $updated = $current.Substring(0, $mInst.Index) + $block + $current.Substring($mInst.Index + $mInst.Length)
            [System.IO.File]::WriteAllText($claudeMd, $updated, $utf8NoBom)
            Write-Host "  bloque global actualizado $instVer -> $repoVer (el resto de CLAUDE.md queda intacto)"
        }
    } elseif ($current -match '(?m)^# fable discipline \(per-model working rules\)') {
        $bak = Migrate-LegacyBlock $claudeMd $block
        Write-Host "  bloque legado SIN marcadores migrado a $repoVer (backup: $bak)"
        Write-Host "  Si tenias notas propias dentro de las secciones viejas (# fable discipline / # git / # subagent routing), recuperalas del backup."
    } else {
        [System.IO.File]::AppendAllText($claudeMd, [Environment]::NewLine + $block + [Environment]::NewLine, $utf8NoBom)
        Write-Host "  bloque global anexado a CLAUDE.md ($repoVer)"
    }
}

Write-Host ""
Write-Host "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
