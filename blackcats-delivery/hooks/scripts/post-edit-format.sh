#!/bin/bash
# PostToolUse(Edit|Write): formatea el archivo tocado con el formatter del repo.
# Estrictamente fail-open: sin formatter, sin config o con error → silencio y exit 0.

set -u
INPUT=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] || [ ! -f "$FILE" ] && exit 0

case "$FILE" in
  */node_modules/*|*/.git/*|*.min.js|*.min.css) exit 0 ;;
esac

# Solo archivos DENTRO del proyecto: nunca reformatear repos vecinos ni scratchpad
# (sus convenciones de estilo no son las de este proyecto).
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  case "$FILE" in "$CLAUDE_PROJECT_DIR"/*) ;; *) exit 0 ;; esac
  cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
else
  cd "$(dirname "$FILE")" 2>/dev/null || exit 0
fi

# Config buscada desde el dir del archivo hacia la raíz del proyecto (monorepos:
# el config puede vivir en packages/*, no en la raíz).
has_config_upward() { # $1 = glob-check function name
  d=$(dirname "$FILE")
  while :; do
    "$1" "$d" && return 0
    [ "$d" = "${CLAUDE_PROJECT_DIR:-/}" ] || [ "$d" = "/" ] && return 1
    d=$(dirname "$d")
  done
}
check_prettier() { ls "$1"/.prettierrc* "$1"/prettier.config.* >/dev/null 2>&1 || grep -qs '"prettier"' "$1/package.json" 2>/dev/null; }
check_ruff()     { [ -f "$1/ruff.toml" ] || grep -qs 'ruff' "$1/pyproject.toml" 2>/dev/null; }

case "$FILE" in
  *.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.json)
    if has_config_upward check_prettier; then
      npx --no-install prettier --write "$FILE" >/dev/null 2>&1
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1 && has_config_upward check_ruff; then
      ruff format "$FILE" >/dev/null 2>&1
    fi
    ;;
esac
exit 0
