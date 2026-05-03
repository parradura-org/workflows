# Setup de Workflow Automatizado de PRs

Guía para que un agente implemente en cualquier repositorio el flujo de:
**PR → CI → code review automático → auto-merge a `dev` → release PR a `main`**.

> **Para el agente:** seguí esta guía paso a paso. No saltees pasos. Después de cada paso, verificá que se ejecutó correctamente antes de avanzar. Si algo falla, parate y reportá al usuario antes de continuar.

---

## 0. Variables a configurar

Antes de empezar, definí estas variables. Si alguna no está clara, **preguntale al usuario**:

| Variable | Default sugerido | Descripción |
|---|---|---|
| `WORKFLOWS_REPO` | `parradura-org/workflows` | Repo central con reusable workflows |
| `WORKFLOWS_REF` | `main` | Branch o tag del repo central a usar |
| `BOT_REVIEWER` | `@codex-bot` | Username del bot que revisa PRs |
| `BASE_BRANCH` | `dev` | Branch de desarrollo (target de PRs) |
| `PROD_BRANCH` | `main` | Branch de producción |
| `MERGE_METHOD` | `squash` | `squash`, `merge` o `rebase` |

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

### 3.3 `.github/CODEOWNERS`

```
* @codex-bot
```

> Reemplazá `@codex-bot` con el bot reviewer real. Si todavía no tenés bot configurado, poné tu propio username temporalmente.

### 3.4 `release-please-config.json`

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

### 3.5 `.release-please-manifest.json`

```json
{ ".": "0.1.0" }
```

> Si el proyecto ya tiene una versión en `package.json`, usá esa.

### 3.6 `scripts/setup-branch-protection.sh`

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
    -f required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
    -f restrictions=null \
    -F allow_force_pushes=false \
    -F allow_deletions=false \
    >/dev/null

  echo "✓ Protección aplicada en $branch"
done

gh api -X PATCH "repos/$REPO" \
  -F allow_auto_merge=true \
  -F delete_branch_on_merge=true \
  -F allow_squash_merge=true \
  >/dev/null

echo "✓ Auto-merge habilitado en $REPO"
```

Después: `chmod +x scripts/setup-branch-protection.sh`

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

```bash
git checkout -b test/workflow-setup
echo "# Test" >> .workflow-test.md
git add .workflow-test.md
git commit -m "test: verify workflow setup"
git push -u origin test/workflow-setup

gh pr create --base dev --title "test: workflow setup" --body "Test del flujo automatizado"
gh pr merge --auto --squash
```

**Esperado:**
1. CI corre (status check `ci`)
2. Bot reviewer se asigna automáticamente vía CODEOWNERS
3. Cuando el bot aprueba y CI pasa, GitHub mergea solo
4. Branch se borra automáticamente
5. En `dev`, release-please abre/actualiza un PR hacia `main`

Limpieza:

```bash
git checkout dev && git pull
rm -f .workflow-test.md
git commit -am "chore: cleanup test file" && git push
```

---

## 9. Reportar al usuario

- Repo configurado
- Tipo de proyecto detectado
- Default branch ahora es `dev`
- Branch protection aplicada en `dev` y `main`
- Próximo paso: PRs nuevos con `gh pr create --base dev --fill && gh pr merge --auto --squash`
- Para deploy a prod: mergear el PR de release-please que aparece en `main`

---

## Apéndice A: Convención de commits

Release-please usa [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` → minor bump
- `fix:` → patch bump
- `feat!:` o `BREAKING CHANGE:` → major bump
- `chore:`, `docs:`, `refactor:`, `test:`, `perf:`, `ci:` → no bumpean

## Apéndice B: Comandos del día a día

```bash
gh pr create --base dev --fill && gh pr merge --auto --squash
gh pr list --base main --label "autorelease: pending"
gh pr merge <number> --squash
gh release list
```

## Apéndice C: Troubleshooting

| Síntoma | Causa | Fix |
|---|---|---|
| Auto-merge no se activa | `allow_auto_merge` off | Re-correr `setup-branch-protection.sh` |
| CI no aparece como required | Job se llama distinto a `ci` | Verificar nombre en `node-ci.yml` |
| Bot no revisa | CODEOWNERS mal o bot sin acceso | Revisar `.github/CODEOWNERS` y collaborators |
| Release-please no crea PR | Permisos o no hay commits convencionales | Settings → Actions → Read and write permissions |
