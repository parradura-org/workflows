# workflows

Repo central de reusable workflows y guía de setup automatizado para mis proyectos.

## Para qué sirve

Centralizar CI/CD, **PR shepherding agéntico**, auto-merge y release management para todos mis proyectos (work, startup, dev, uni). El agente que abre el PR es responsable de leer los reviews de Codex/Copilot, aplicar los fixes que correspondan y mergear — solo escala al humano cuando hay decisión que tomar. En vez de repetir setup en cada repo, cada proyecto referencia los workflows de acá.

## Reusable workflows

| Workflow | Uso |
|---|---|
| `node-ci.yml` | Lint + typecheck + tests + build opcional para Node/TS |
| `python-ci.yml` | Ruff + pytest con services de Postgres/Redis |
| `release-please.yml` | Release management automático con conventional commits |
| `deploy-vercel.yml` | Deploy a Vercel (frontend) |
| `deploy-railway.yml` | Deploy a Railway (backend) |

## Plugin `blackcats-delivery`

El sistema de delivery del estudio, empaquetado como plugin de Claude Code con marketplace
privado en este repo. Principio: **un motor, N playbooks** — el proceso es único (intake →
spec → ticket → ejecución → verificación → deploy) y el tipo de proyecto es un playbook
markdown que el motor consume, no una rama del sistema.

| Pieza | Qué hace |
|---|---|
| `skills/intake` | Pedido → SPEC autocontenida → ticket. Nada entra por prompt suelto. |
| `skills/next` | La sesión toma el primer ticket elegible del board. El board decide, no la sesión. |
| `skills/kickoff` | Proyecto nuevo → PROJECT.md + épicas + scaffold, guiado por el playbook del tipo. |
| `skills/retro` | Cierre de bloque → lo aprendido vuelve al playbook y al CLAUDE.md, por PR. |
| `skills/visual-qa` | Loop screenshot con Playwright, tope 5 rondas, evidencia obligatoria. |
| `skills/blackcats-design` | Piso de calidad visual: anti-defaults de IA + design system obligatorio. |
| `hooks/` | Gates determinísticos: secret-scan pre-commit, format post-edit, handoff al arrancar sesión. |
| `playbooks/` | `landing.md` y `backend-app.md`, extraídos de proyectos reales. Los actualiza `/retro`. |
| `templates/` | SPEC, PROJECT, ADR, playbook. |

Instalación en una máquina:

```bash
claude plugin marketplace add parradura-org/workflows
claude plugin install blackcats-delivery@blackcats
```

> El plugin asume que las skills personales `/pr`, `/jira` y `/handoff` existen en la máquina
> (son dueñas del mapa repo→board, el formato HANDOFF v2 y el shepherding). Sin ellas, los
> pasos que delegan degradan a manual.
>
> Nota sobre el hook de formato: formatea sincrónicamente el archivo recién editado; si un
> Edit posterior del agente no matchea, es porque prettier/ruff reescribió el archivo — se
> resuelve releyendo, no deshabilitando el tracking.

## Cómo usar en un proyecto nuevo

### Setup inicial (una vez por repo)

Pasale al agente del proyecto la URL raw del [`AGENTS.md`](./AGENTS.md):

```
Implementá el workflow automatizado de PRs siguiendo la guía en
https://raw.githubusercontent.com/parradura-org/workflows/main/AGENTS.md
```

El agente fetchea, ejecuta paso a paso, y deja el repo configurado con CI, auto-merge, branch protection y release-please.

### Día a día (cada PR)

Para fire-and-forget — el agente abre el PR y lo shepherdea hasta merge:

```
/loop "hacé <descripción del cambio> y shepherdeá el PR hasta merge"
```

`/loop` activa dynamic mode, las wakeups del agente persisten incluso si cerrás la sesión. El agente lee los reviews de Codex/Copilot, fixea lo que sea obvio, y solo te pinguea si hay algo que requiera tu decisión (security, breaking change, ambigüedad arquitectural).

## Estructura

```
.
├── .github/workflows/    # Reusable workflows
├── .claude-plugin/       # marketplace.json (marketplace privado "blackcats")
├── blackcats-delivery/   # Plugin: skills, hooks, templates, playbooks
├── AGENTS.md             # Guía paso a paso para agentes
├── CLAUDE.md             # Memoria del repo para sesiones que lo editan
├── README.md
└── LICENSE
```
