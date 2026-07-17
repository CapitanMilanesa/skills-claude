#!/usr/bin/env python3
"""Delegation ledger — libro contable de delegaciones a subagentes.

Se dispara en el evento SubagentStop y escribe UNA línea JSONL por delegación en
~/.claude/delegation-log.jsonl. Es solo observabilidad: nunca bloquea, nunca falla
el turno, nunca imprime ruido. Registra el payload completo del evento (sin asumir
la forma exacta) para no perder nada; la extracción de campos se refina cuando se
vean payloads reales.

Analizar después, p. ej.:
  python -c "import json;[print(json.loads(l)['ts']) for l in open('<ruta>')]"
"""
import sys
import os
import json
import datetime


def main() -> None:
    raw = ""
    try:
        raw = sys.stdin.read()
    except Exception:
        pass

    try:
        payload = json.loads(raw) if raw.strip() else None
    except Exception:
        payload = {"unparsed_stdin": raw[:2000]}

    entry = {
        "ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "event": "SubagentStop",
        "payload": payload,
    }

    try:
        log = os.path.join(os.path.expanduser("~"), ".claude", "delegation-log.jsonl")
        with open(log, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception:
        pass  # el logging nunca debe romper la sesión

    sys.exit(0)


main()
