#!/usr/bin/env python3
"""Delegation ledger — libro contable de delegaciones a subagentes.

Se dispara en el evento SubagentStop y escribe UNA línea JSONL por delegación en
~/.claude/delegation-log.jsonl con métricas limpias: qué agente corrió, cuántas
líneas devolvió su reporte, cuál era su cap y si lo violó.

Es observabilidad, no enforcement por bloqueo (rehacer un subagente para recortar
un reporte cuesta más cuota que leerlo largo una vez). Cuando un reporte se pasa
de su cap, emite un aviso visible (systemMessage) — solo en la violación, para que
sea señal y no ruido. Nunca bloquea, nunca falla el turno.

Los caps salen de los contratos de retorno de cada agente (ver los .md en agents/).

Resumir el ledger, p. ej.:
  python -c "import json,collections as c; \
    r=[json.loads(l) for l in open('<ruta>')]; \
    print(c.Counter(x['agent_type'] for x in r))"
"""
import sys
import os
import json
import datetime

# Caps de líneas por contrato de retorno (agents/*.md).
CAPS = {"explorador": 15, "ejecutor": 20, "revisor": 40}


def main() -> None:
    raw = ""
    try:
        raw = sys.stdin.read()
    except Exception:
        pass

    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}
    if not isinstance(payload, dict):
        payload = {}

    agent_type = payload.get("agent_type")
    message = payload.get("last_assistant_message") or ""
    report_lines = len(message.splitlines()) if message else 0
    cap = CAPS.get(agent_type)
    over_cap = bool(cap is not None and report_lines > cap)

    entry = {
        "ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "agent_type": agent_type,
        "agent_id": payload.get("agent_id"),
        "session_id": payload.get("session_id"),
        "report_lines": report_lines,
        "report_chars": len(message),
        "cap": cap,
        "over_cap": over_cap,
    }

    try:
        log = os.path.join(os.path.expanduser("~"), ".claude", "delegation-log.jsonl")
        with open(log, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        pass  # el logging nunca debe romper la sesión

    # Aviso visible SOLO cuando se viola el cap (señal, no ruido). Nunca bloquea.
    if over_cap:
        try:
            msg = (
                f"[ledger] {agent_type} devolvió {report_lines} líneas "
                f"(contrato: ≤{cap}). Revisar la redacción del agente o la delegación."
            )
            print(json.dumps({"systemMessage": msg, "suppressOutput": True}))
        except Exception:
            pass

    sys.exit(0)


main()
