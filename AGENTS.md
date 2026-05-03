# Setup de Workflow Automatizado de PRs

Guía para que un agente implemente en cualquier repositorio el flujo de:
**PR → CI → review (Codex/Copilot/subagente) → fix automático → merge a `dev` → release PR a `main`**.

**El agente que abre el PR es responsable de shepherdearlo hasta el merge**: lee los reviews, aplica fixes obvios, y solo escala al usuario si el problema requiere decisión humana. Vos no tenés que aprobar ni mergear manualmente.

> **Para el agente:** seguí esta guía paso a paso. No saltees pasos. Después de cada paso, verificá que se ejecutó correctamente antes de avanzar. Si algo falla, parate y reportá al usuario antes de continuar.

---

## 0. Variables a configurar

Antes de empezar, definí estas variables. Si alguna no está clara, **preguntale al usuario**:

| Variable | Default sugerido | Descripción |
|---|---|---|
| `WORKFLOWS_REPO` | `parradura-org/workflows` | Repo central con reusable workflows |
| `WORKFLOWS_REF` | `main` | Branch o tag del repo central a usar |
| `BASE_BRANCH` | `dev` | Branch de desarrollo (target de PRs) |
| `PROD_BRANCH` | `main` | Branch de producción |
| `MERGE_METHOD` | `squash` | `squash`, `merge` o `rebase` |

(No se usa `BOT_REVIEWER` ni CODEOWNERS — ningún bot reviewer puede submitear `APPROVED`, así que el gating se delega al watch loop del agente.)

---

## 1. Verificar prerequisitos

```bash
gh auth status || { echo "ERROR: gh CLI no autenticado"; exit 1; }
git rev-parse --is-inside-work-tree || { echo "ERROR: no es un repo git"; exit 1; }
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "repos/$REPO" --jq '.permissions.admin' | grep -q true \
  || { echo "ERROR: necesitás permisos de admin en $REPO"; exit 1; }
echo "✓ Prerequisitos OK en $REPO"
```

---

## 2. Detectar contexto del proyecto

```bash
if [ -f "pnpm-lock.yaml" ]; then PM="pnpm"
elif [ -f "yarn.lock" ]; then PM="yarn"
elif [ -f "bun.lockb" ]; then PM="bun"
else PM="npm"
fi

if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
  PROJECT_TYPE="nextjs"; RUN_BUILD="true"
elif [ -f "turbo.json" ] || [ -f "pnpm-workspace.yaml" ]; then
  PROJECT_TYPE="monorepo"; RUN_BUILD="true"
elif [ -f "package.json" ]; then
  PROJECT_TYPE="node"; RUN_BUILD="false"
else
  PROJECT_TYPE="generic"; RUN_BUILD="false"
fi

[ -f "tsconfig.json" ] && HAS_TS="true" || HAS_TS="false"

NODE_VERSION=$(cat .nvmrc 2>/dev/null | tr -d 'v' \
  || jq -r '.engines.node // "20"' package.json 2>/dev/null \
  || echo "20")

echo "Detectado: $PROJECT_TYPE / $PM / Node $NODE_VERSION / TS=$HAS_TS / build=$RUN_BUILD"
```

---

## 3. Crear archivos de configuración

### 3.1 `.github/workflows/ci.yml`

```yaml
name: CI
on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev, main]

jobs:
  ci:
    uses: parradura-org/workflows/.github/workflows/node-ci.yml@main
    with:
      node-version: '20'
      package-manager: 'npm'
      run-lint: true
      run-typecheck: true
      run-tests: true
      run-build: false
```

> Ajustá `node-version`, `package-manager`, `run-build` y los demás flags según lo detectado en el paso 2.

### 3.2 `.github/workflows/release-please.yml`

```yaml
name: Release Please
on:
  push:
    branches: [dev]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    uses: parradura-org/workflows/.github/workflows/release-please.yml@main
    with:
      target-branch: main
      release-type: node
```

### 3.3 `release-please-config.json`

```json
{
  "packages": {
    ".": {
      "release-type": "node",
      "include-component-in-tag": false,
      "changelog-sections": [
        { "type": "feat", "section": "Features" },
        { "type": "fix", "section": "Bug Fixes" },
        { "type": "perf", "section": "Performance" },
        { "type": "refactor", "section": "Refactors" }
      ]
    }
  }
}
```

### 3.4 `.release-please-manifest.json`

```json
{ ".": "0.1.0" }
```

> Si el proyecto ya tiene una versión en `package.json`, usá esa.

### 3.5 `scripts/setup-branch-protection.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

echo "Aplicando branch protection en $REPO..."

for branch in dev main; do
  if ! gh api "repos/$REPO/branches/$branch" >/dev/null 2>&1; then
    echo "Branch '$branch' no existe, creándola desde HEAD..."
    DEFAULT=$(gh api "repos/$REPO" --jq .default_branch)
    SHA=$(gh api "repos/$REPO/git/refs/heads/$DEFAULT" --jq .object.sha)
    gh api -X POST "repos/$REPO/git/refs" \
      -f ref="refs/heads/$branch" -f sha="$SHA"
  fi

  gh api -X PUT "repos/$REPO/branches/$branch/protection" \
    -f required_status_checks='{"strict":true,"contexts":["ci"]}' \
    -F enforce_admins=false \
    -f required_pull_request_reviews=null \
    -f restrictions=null \
    -F allow_force_pushes=false \
    -F allow_deletions=false \
    >/dev/null

  echo "✓ Protección aplicada en $branch (CI requerido, sin approval gate)"
done

gh api -X PATCH "repos/$REPO" \
  -F allow_auto_merge=true \
  -F delete_branch_on_merge=true \
  -F allow_squash_merge=true \
  >/dev/null

echo "✓ Auto-merge + delete-on-merge habilitados en $REPO"
```

Después: `chmod +x scripts/setup-branch-protection.sh`

> **Nota:** No se requiere approval count porque el agente shepherdea el PR y aplica fixes basado en el feedback de Codex/Copilot. El único gate formal es CI verde.

---

## 4. Asegurar scripts de package.json

```json
{
  "scripts": {
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run"
  }
}
```

> Adaptá los comandos según las herramientas del proyecto. Si algún script no aplica, omitilo y desactivá el flag correspondiente en `ci.yml`.

---

## 5. Configurar branches

```bash
git fetch origin
if ! git show-ref --verify --quiet refs/remotes/origin/dev; then
  git checkout -b dev
  git push -u origin dev
fi
gh repo edit --default-branch dev
```

---

## 6. Aplicar branch protection

```bash
./scripts/setup-branch-protection.sh
```

---

## 7. Commit de la configuración

```bash
git checkout dev
git add .github/ scripts/ release-please-config.json .release-please-manifest.json
[ -f package.json ] && git add package.json
git commit -m "chore: setup automated PR workflow with auto-merge and release-please"
git push origin dev
```

---

## 8. Verificación end-to-end

Probá el flujo completo con un PR de prueba. **Vos NO tenés que aprobar nada** — el agente shepherdea solo.

```bash
git checkout -b test/workflow-setup
echo "# Test" >> .workflow-test.md
git add .workflow-test.md
git commit -m "test: verify workflow setup"
git push -u origin test/workflow-setup

gh pr create --base dev --title "test: workflow setup" --body "Test del flujo automatizado"
```

A partir de acá el agente entra en watch loop (sección 9). Esperado:

1. CI corre y pasa
2. Codex y/o Copilot postean review como state `COMMENTED`
3. Agente lee el feedback:
   - Si LGTM neto → `gh pr merge --squash` → done
   - Si hay findings simples → fixea, commitea, push, espera re-review
   - Si hay algo arquitectural/security/etc → escala al usuario via `gh pr comment`
4. Branch borrada automáticamente al merge
5. En `dev`, release-please abre/actualiza un PR hacia `main`

Limpieza si quedó el archivo de prueba:

```bash
git checkout dev && git pull
rm -f .workflow-test.md
git commit -am "chore: cleanup test file" && git push
```

---

## 9. Watch loop del agente (post-PR)

**Esta es la parte más importante de la guía.** Después de crear el PR, el agente NO termina su tarea — entra en un loop que vigila el PR hasta que esté mergeado o haya razón clara para escalar.

### Cómo invocar (para el usuario)

Para que el agente pueda auto-pacearse con `ScheduleWakeup` y que las wakeups persistan incluso si cerrás la sesión, dispará la tarea con `/loop`:

```
/loop "hacé <descripción del cambio> y shepherdeá el PR hasta merge"
```

`/loop` activa dynamic mode. Las wakeups disparadas con `ScheduleWakeup` siguen firing aunque cierres la terminal — fire-and-forget real.

Si invocás sin `/loop`, el agente igual va a hacer el watch loop pero usando `Bash sleep` en la sesión activa (no podés cerrar la terminal hasta que termine).

### Algoritmo (para el agente)

Después de `gh pr create`, repetir hasta done o escalation:

```
loop:
  state = inspect PR  (gh pr view, gh pr checks, gh api .../reviews)

  ┌─ CI rojo
  │    → gh run view --log-failed → leer logs
  │    → fix root cause + commit + push
  │    → ScheduleWakeup 180s
  │
  ├─ ≥1 bot reviewer posteó (Codex, Copilot, ambos)
  │    → leer cada review body + reactions
  │    → categorizar findings:
  │         • obvio (typo, lint, formatting, bug chico, edge case faltante)
  │             → fixear + commit + push + ScheduleWakeup 240s
  │         • arquitectural / riesgoso / ambiguo / security / breaking
  │             → ESCALATE
  │         • falso positivo claro
  │             → ignorar (justificar en commit msg si hay otro fix)
  │    → si LGTM neto (no findings concretos accionables):
  │         → gh pr merge --squash → done, reportar al usuario
  │
  ├─ 0 bots posteraron en >10 min (rate limit probable de Codex/Copilot)
  │    → dispatch subagente:
  │         Agent(subagent_type="feature-dev:code-reviewer",
  │               prompt="Review este PR: <diff + contexto>. Reportá findings críticos
  │                       solo si son blockers (security, bugs claros, breaking).")
  │    → tratar findings del subagente igual que un bot review (rama anterior)
  │
  ├─ 0 movimiento en >30 min totales sin merge
  │    → ESCALATE
  │
  └─ default
       → ScheduleWakeup 180s
```

### Detección de "LGTM" en bot reviews

Codex y Copilot **siempre** submitean state `COMMENTED` (nunca `APPROVED`). Para detectar approval implícito:

| Bot | Señal de LGTM | Señal de issues |
|---|---|---|
| **Codex** | reaction 👍 en su review, o body sin findings concretos | reaction 👀 mientras revisa, body con observaciones específicas (P0/P1) |
| **Copilot** | body breve sin "issues", "concerns", ni inline comments | inline suggestions, lista de problemas en el body |

Si la señal es ambigua (body neutro, ninguna reacción, comentarios genéricos), tratá como LGTM si **no hay findings concretos accionables**.

Para inspeccionar reactions:
```bash
gh api repos/$REPO/pulls/$PR/reviews/$REVIEW_ID/reactions
```

### Cuándo escalar al usuario (ESCALATE)

**Default = autonomía**. Si el agente puede solucionar el problema y no es decisión humana, lo soluciona. Solo escalá en estos casos:

| Trigger | Por qué |
|---|---|
| Review menciona seguridad, auth, credenciales, injection, RCE, secrets | Decisión de seguridad |
| Review marca breaking change a API pública o behavior contract | Decisión de producto |
| Review cuestiona el approach (no el código) — "por qué hiciste X así" | Decisión de diseño |
| 3 ciclos de fix y bots siguen marcando issues distintos | Probable malentendido de fondo |
| CI rojo por causa fuera del código (infra, secrets faltantes, deps externas) | Fuera del control del agente |
| Subagente reviewer marca críticos Y bots tampoco vinieron | Sin red de seguridad |

**Cómo escalar:** dejá un comentario claro en el PR explicando qué pasó y qué necesita decidir el usuario:

```bash
gh pr comment $PR --body "🚨 Escalation: <descripción del bloqueo>

**Razón:** <por qué requiere decisión humana>
**Lo que ya intenté:** <fixes aplicados, ciclos>
**Decisión que necesito:** <qué tenés que decidir vos>

PR queda pendiente."
```

Después salí del loop y reportá al usuario en el chat.

### Reglas duras

- **Nunca** mergear con CI rojo (auto-merge bloquea esto, pero por si acaso).
- **Nunca** cerrar el PR sin merge sin pedir confirmación al usuario.
- **Nunca** force-push a la branch del PR (rompe la trazabilidad de reviews).
- **Nunca** auto-aprobar el PR formalmente (no se necesita, branch protection no lo pide).
- **Nunca** ignorar findings de seguridad — siempre escalar aunque "parezcan menores".

### Cadencia de ScheduleWakeup

| Estado | Delay sugerido | Por qué |
|---|---|---|
| Esperando primer review (T<10 min) | 180s | Cache caliente, bots suelen responder en este rango |
| Después de fix push (esperando re-review) | 240s | Dar tiempo a CI + bots a re-evaluar |
| Sin movimiento >10 min | dispatch subagente, no wakeup | El subagente es más rápido que esperar más |
| Idle prolongado (>15 min total) | 1200s | Cache miss aceptable, no hay nada que justifique chequeo frecuente |

---

## 10. Reportar al usuario

Cuando el PR está mergeado (o escalado), el agente reporta:

- PR número + URL + estado final (`merged` / `escalated`)
- Tipo de proyecto detectado
- Default branch ahora es `dev`
- Si hubo fix cycles: cuántos y qué se cambió
- Si hubo escalation: link al comment del PR explicando qué decidir
- Próximo paso: para deploy a prod, mergear el PR de release-please que aparece en `main`

---

## Apéndice A: Convención de commits

Release-please usa [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` → minor bump
- `fix:` → patch bump
- `feat!:` o `BREAKING CHANGE:` → major bump
- `chore:`, `docs:`, `refactor:`, `test:`, `perf:`, `ci:` → no bumpean

## Apéndice B: Comandos del día a día

```bash
# Crear PR con shepherding automático (recomendado)
/loop "hacé <cambio> y shepherdeá el PR hasta merge"

# Manual (si querés controlar vos):
gh pr create --base dev --fill && gh pr merge --auto --squash

# Ver el PR de release pendiente
gh pr list --base main --label "autorelease: pending"

# Mergear el release a prod
gh pr merge <number> --squash

# Releases recientes
gh release list
```

## Apéndice C: Troubleshooting

| Síntoma | Causa | Fix |
|---|---|---|
| Auto-merge no se activa | `allow_auto_merge` off | Re-correr `setup-branch-protection.sh` |
| CI no aparece como required | Job se llama distinto a `ci` | Verificar nombre en `node-ci.yml` |
| Codex no posteó nada | Rate limit de Codex (típico con Plus) | El watch loop dispara subagente fallback solo |
| Copilot review desactivado | Settings → Code review limits OFF | Activarlo en repo settings |
| Release-please no crea PR | Permisos o no hay commits convencionales | Settings → Actions → Read and write permissions |
| Watch loop se cuelga sin avance | Probable bug del agente, no escalation | Cancelar manualmente con `gh pr comment` y resetear |
