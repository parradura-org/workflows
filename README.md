# workflows

Repo central de reusable workflows y guía de setup automatizado para mis proyectos.

## Para qué sirve

Centralizar CI/CD, auto-merge, code review automático y release management para todos mis proyectos (work, startup, dev, uni). En vez de repetir setup en cada repo, cada proyecto referencia los workflows de acá.

## Reusable workflows

| Workflow | Uso |
|---|---|
| `node-ci.yml` | Lint + typecheck + tests + build opcional para Node/TS |
| `release-please.yml` | Release management automático con conventional commits |
| `deploy-vercel.yml` | Deploy a Vercel (frontend) |
| `deploy-railway.yml` | Deploy a Railway (backend) |

## Cómo usar en un proyecto nuevo

Pasale al agente del proyecto la URL raw del [`AGENTS.md`](./AGENTS.md):

```
Implementá el workflow automatizado de PRs siguiendo la guía en
https://raw.githubusercontent.com/parradura-org/workflows/main/AGENTS.md
```

El agente fetchea, ejecuta paso a paso, y deja el repo configurado con CI, auto-merge, branch protection y release-please.

## Estructura

```
.
├── .github/workflows/   # Reusable workflows
├── AGENTS.md           # Guía paso a paso para agentes
├── README.md
└── LICENSE
```
