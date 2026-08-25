#!/bin/bash
# SessionStart: si el proyecto tiene HANDOFF.md, inyecta el START HERE como contexto.
# Hace determinístico el "al arrancar sesión, leé el handoff primero". Fail-open.

set -u
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0

HANDOFF=""
for c in HANDOFF.md docs/HANDOFF.md; do
  [ -f "$c" ] && HANDOFF="$c" && break
done
[ -z "$HANDOFF" ] && exit 0

# START HERE completo (hasta el próximo '---' o '## ') + últimas 3 líneas del Historial
# (formato handoff v2: la más nueva ARRIBA → head toma las más recientes).
SECTION=$(awk '/^## .*START HERE/{f=1} f{ if (n++ && ($0 ~ /^---/ || $0 ~ /^## /)) exit; print }' "$HANDOFF" | head -80)
SECTION_TOTAL=$(awk '/^## .*START HERE/{f=1} f{ if (n++ && ($0 ~ /^---/ || $0 ~ /^## /)) exit; print }' "$HANDOFF" | wc -l | tr -d ' ')
[ "$SECTION_TOTAL" -gt 80 ] && SECTION="$SECTION
[...sección truncada — leer $HANDOFF completo]"
HIST=$(awk '/^## .*Historial/{f=1; next} f{ if ($0 ~ /^## /) exit; if ($0 ~ /^- /) print }' "$HANDOFF" | head -3)
[ -z "$SECTION" ] && exit 0

CONTEXT="[$HANDOFF — inyectado por hook del plugin blackcats-delivery. Es una foto del cierre anterior, no estado vivo: verificar antes de asumir. No hace falta releer el archivo salvo que necesites 'Estado anterior'.]

$SECTION"
[ -n "$HIST" ] && CONTEXT="$CONTEXT

Últimas sesiones:
$HIST"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg c "$CONTEXT" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$CONTEXT" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.argv[1]}}))
PY
fi
exit 0
