#!/bin/bash
# PreToolUse(Bash): bloquea `git commit` si el diff a commitear contiene secretos.
# Fail-open ante cualquier error propio; el deny solo sale por match real.

set -u
INPUT=$(cat 2>/dev/null) || exit 0

if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  CMD=$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p' | head -c 4000)
fi
[ -z "$CMD" ] && exit 0

# Detección estructural de una invocación `git commit` (cubre `git -C dir commit`,
# `git -c k=v commit`, `cd x && git commit`; NO matchea `git log --grep "git commit"`).
printf '%s' "$CMD" | grep -Eq '(^|[^A-Za-z0-9_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Flags mirados FUERA de strings quoteados (que `-a` en el mensaje no dispare el modo worktree).
# `git add ... && git commit` en un solo comando corre este hook ANTES del add: escanear
# también worktree y untracked, porque ese contenido va a terminar en el commit.
CMD_NOQ=$(printf '%s' "$CMD" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
SCAN_WORKTREE=0
case "$CMD_NOQ" in
  *" -a"*|*"--all"*|*"git add"*|*" -A"*|*" ."*) SCAN_WORKTREE=1 ;;
esac
case "$CMD_NOQ" in *"git add"*) SCAN_UNTRACKED=1 ;; *) SCAN_UNTRACKED=0 ;; esac

# Alta confianza; DUMMY filtra credenciales de docker-compose/CI (hosts de servicio,
# passwords dummy, el JWT de ejemplo de jwt.io) para no bloquear trabajo legítimo.
PATTERNS='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|sk-ant-[A-Za-z0-9-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|[a-z][a-z0-9+.-]*://[^:/@[:space:]]+:[^@[:space:]$<%]{6,}@|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+'
DUMMY='://[^:/@[:space:]]+:[^@[:space:]]*@(localhost|127\.0\.0\.1|0\.0\.0\.0|host\.docker\.internal|db|postgres|postgresql|mysql|mariadb|redis|mongo|mongodb|rabbitmq|minio)([:/@[:space:]]|$)|://[^:/@[:space:]]+:(postgres|postgrespw|mysql|redis|mongo|password|passw0rd|secret|test|testing|example|changeme|root|admin|dev|devpass|local|guest)@|eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
GENERIC='(api[_-]?key|secret|token|passwd|password)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9_/+=-]{16,}["'"'"']'
EXCLUDE='process\.env|os\.environ|import\.meta\.env|getenv|example|placeholder|changeme|your[_-]|xxxx|<[a-z]|\$\{|\$[A-Z_]'

diff_stream() {
  git diff --cached -U0 2>/dev/null
  if [ "$SCAN_WORKTREE" = 1 ]; then
    git diff -U0 2>/dev/null
  fi
  if [ "$SCAN_UNTRACKED" = 1 ]; then
    git ls-files --others --exclude-standard 2>/dev/null | head -200 | while IFS= read -r uf; do
      [ -f "$uf" ] || continue
      [ "$(wc -c < "$uf" 2>/dev/null || echo 0)" -gt 1000000 ] && continue
      printf '+++ b/%s\n' "$uf"
      sed 's/^/+/' "$uf" 2>/dev/null
    done
  fi
  return 0
}

STREAM=$(diff_stream)
ADDED=$(printf '%s\n' "$STREAM" | grep -E '^\+' | grep -Ev '^\+\+\+')
[ -z "$ADDED" ] && exit 0

HITS=$(printf '%s\n' "$ADDED" | grep -E -e "$PATTERNS" | grep -Evi -e "$EXCLUDE" | grep -Ev -e "$DUMMY" | head -5)
if [ -z "$HITS" ]; then
  HITS=$(printf '%s\n' "$ADDED" | grep -Ei -e "$GENERIC" | grep -Evi -e "$EXCLUDE" | head -5)
fi
[ -z "$HITS" ] && exit 0

# Atribución de archivos en una sola pasada sobre el stream ya calculado (O(1) llamadas a git).
FILES=$(printf '%s\n' "$STREAM" | awk -v pat="$PATTERNS" -v dum="$DUMMY" '
  /^\+\+\+ b\//{f=substr($0,7); next}
  /^\+/ && $0 !~ /^\+\+\+/ { if ($0 ~ pat && $0 !~ dum) print f }
' 2>/dev/null | sort -u | head -10 | tr '\n' ' ')

REASON="Posible secreto en el diff a commitear (archivos: ${FILES:-no atribuidos — revisar el diff completo}). Regla del estudio: NUNCA commitear secrets. Revisá con 'git diff --cached' (y 'git diff' + untracked si estás por hacer git add), movelo a .env (gitignoreado) y pedile al usuario la variable. Si es un falso positivo claro, explicáselo al usuario antes de commitear."
if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
else
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Posible secreto en el diff a commitear. Revisar git diff --cached antes de commitear."}}\n'
fi
exit 0
