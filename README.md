# workflows

Repo central de reusable workflows y guía de setup automatizado para mis proyectos.

## Para qué sirve

Centralizar CI/CD, **PR shepherding agéntico**, auto-merge y release management para todos mis proyectos (work, startup, dev, uni). El agente que abre el PR es responsable de leer los reviews de Codex/Copilot, aplicar los fixes que correspondan y mergear — solo escala al humano cuando hay decisión que tomar. En vez de repetir setup en cada repo, cada proyecto referencia los workflows de acá.

## Reusable workflows

| Workflow | Uso |
|---|---|
| `node-ci.yml` | Lint + typecheck + tests + build opcional para Node/TS |
| `release-please.yml` | Release management automático con conventional commits |
| `deploy-vercel.yml` | Deploy a Vercel (frontend) |
| `deploy-railway.yml` | Deploy a Railway (backend) |

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
├── .github/workflows/   # Reusable workflows
├── AGENTS.md           # Guía paso a paso para agentes
├── README.md
└── LICENSE
```
