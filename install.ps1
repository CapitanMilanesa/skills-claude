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
#    archivo del usuario nunca se toca. Un bloque viejo sin marcadores se avisa, no se pisa.
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
$globalRaw = Get-Content (Join-Path $repo "CLAUDE.global.md") -Raw
$blockRe = '(?s)<!-- fable-discipline v[^ ]+ -->.*?<!-- /fable-discipline -->'
$mRepo = [regex]::Match($globalRaw, $blockRe)
if (-not $mRepo.Success) { throw "CLAUDE.global.md no tiene los marcadores fable-discipline" }
$block = $mRepo.Value
$repoVer = [regex]::Match($block, 'fable-discipline (v[^ ]+)').Groups[1].Value

if (-not (Test-Path $claudeMd)) {
    Set-Content -Path $claudeMd -Value $block -Encoding utf8
    Write-Host "  CLAUDE.md creado con el bloque global ($repoVer)"
} else {
    $current = Get-Content $claudeMd -Raw
    $mInst = [regex]::Match($current, $blockRe)
    if ($mInst.Success) {
        $instVer = [regex]::Match($mInst.Value, 'fable-discipline (v[^ ]+)').Groups[1].Value
        if ($instVer -eq $repoVer) {
            Write-Host "  bloque global al dia ($repoVer)"
        } else {
            $updated = $current.Substring(0, $mInst.Index) + $block + $current.Substring($mInst.Index + $mInst.Length)
            Set-Content -Path $claudeMd -Value $updated -Encoding utf8
            Write-Host "  bloque global actualizado $instVer -> $repoVer (el resto de CLAUDE.md queda intacto)"
        }
    } elseif ($current -match "fable discipline") {
        Write-Host "  AVISO: CLAUDE.md tiene un bloque fable-discipline viejo SIN marcadores."
        Write-Host "         Borralo a mano y re-corre este script; de ahi en adelante se actualiza solo."
    } else {
        Add-Content -Path $claudeMd -Value "`n$block" -Encoding utf8
        Write-Host "  bloque global anexado a CLAUDE.md ($repoVer)"
    }
}

Write-Host ""
Write-Host "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
