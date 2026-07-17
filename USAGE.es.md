# Guía rápida del equipo

🇬🇧 [English version](USAGE.md)

Sistema de skills que hace que Claude trabaje eficiente en cada modelo y cuide el límite semanal de uso. Una vez instalado, **se activa solo**: no hay que hacer casi nada.

## 1. Instalar (una vez)

```bash
git clone https://github.com/CapitanMilanesa/skills-claude.git
cd skills-claude
# Windows:
powershell -ExecutionPolicy Bypass -File .\install.ps1
# macOS/Linux:
bash install.sh
```
Para actualizar después: `git pull` + volver a correr el script.

## 2. Regla de oro — elegí el modelo según la tarea

Cambiás de modelo con `/model`. El límite semanal se gasta por costo: **Haiku ≪ Sonnet ≪ Opus ≪ Fable**.

| Tarea | Modelo |
|---|---|
| Renames, boilerplate, docs, ejecutar un plan ya escrito | `/model haiku` |
| **El día a día**: features, bugs, refactors, diseño | `/model sonnet` ← default |
| Corridas autónomas largas / lo que Sonnet no pudo | `/model opus` |

Regla simple: **empezá en Sonnet.** Bajá a Haiku para lo mecánico, subí a Opus solo si hace falta.

## 3. No tenés que invocar nada

Al arrancar la sesión, Claude detecta su modelo y **carga solo** su disciplina de trabajo. Vas a ver dos cosas normales:
- Un *skill* que se activa al inicio (`fable-sonnet`, etc.) — es esperado.
- Líneas tipo `→ Delegando búsqueda a explorador (Haiku)` — Claude derivó parte del trabajo a un modelo más barato solo. Bien ahí.

## 4. Los 4 comandos que importan

- **`/model <modelo>`** — cambiar de modelo.
- **`/clear`** — al terminar una tarea, antes de empezar otra. *Ahorra mucha cuota* (el contexto viejo se re-paga en cada mensaje).
- **`/handoff <modelo>`** — antes de cambiar de modelo a mitad de un problema: deja un resumen para no re-explorar.
- **`/usage`** — cuánto límite semanal queda.

## 5. Higiene de cuota (3 tips)

1. **`/clear` entre tareas distintas** — lo más importante.
2. Corré **`/init`** una vez por repo (genera un `CLAUDE.md` con la arquitectura; después las sesiones arrancan sin re-explorar).
3. Lo mecánico y repetitivo → Haiku. No gastes Opus en renombrar variables.

## Ojo

Claude **commitea pero no pushea** — los push los hacés vos a mano. Y si le pedís algo que toca auth/pagos/migraciones, frena y pregunta antes de improvisar.
