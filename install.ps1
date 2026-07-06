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

# 3. Bloque global -> ~/.claude/CLAUDE.md (solo si no esta ya)
$claudeMd = Join-Path $claudeDir "CLAUDE.md"
$block = Get-Content (Join-Path $repo "CLAUDE.global.md") -Raw
if (-not (Test-Path $claudeMd)) {
    Set-Content -Path $claudeMd -Value $block -Encoding utf8
    Write-Host "  CLAUDE.md creado con el bloque global"
} elseif ((Get-Content $claudeMd -Raw) -notmatch "fable discipline") {
    Add-Content -Path $claudeMd -Value "`n$block" -Encoding utf8
    Write-Host "  bloque global anexado a CLAUDE.md"
} else {
    Write-Host "  CLAUDE.md ya tiene el bloque global (no se pisa; si cambio en el repo, actualizalo a mano)"
}

Write-Host ""
Write-Host "Listo. Los cambios aplican en sesiones nuevas (o /clear en las abiertas)."
