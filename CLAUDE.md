# workflows — repo central del estudio

Infraestructura compartida de `parradura-org`: CI reutilizable, runbook para agentes, y el
plugin `blackcats-delivery` (marketplace privado). **Los cambios acá afectan a todos los
repos que lo consumen** — listar consumidores impactados en cada PR.

## Estructura

- `.github/workflows/` — reusables (`node-ci`, `python-ci`, `release-please`, `deploy-vercel`,
  `deploy-railway`). Consumidores conocidos: iosfa (node-ci), relay (release-please).
- `AGENTS.md` — runbook que agentes externos fetchean por raw URL. **La URL y los nombres de
  sección son contrato**: la skill personal `/pr` y repos ajenos lo referencian. No renombrar.
- `blackcats-delivery/` — el plugin: `skills/` (intake, next, kickoff, retro, visual-qa,
  blackcats-design), `hooks/`, `templates/`, `playbooks/`.
- `.claude-plugin/marketplace.json` — marketplace `blackcats`.

## Reglas

- Este repo trabaja con PR directo a `main` (no tiene `dev`; release-please apunta a main).
- `.github/workflows/*.yml`: el hook global del entorno bloquea `Write` — editar con Bash
  heredoc (`cat > archivo <<'EOF'`).
- **Playbooks** (`blackcats-delivery/playbooks/`): los actualiza `/retro` con evidencia de un
  proyecto real; el Historial de cada playbook es append-only. No crear playbooks
  especulativos para tipos sin proyecto.
- **Skills del plugin**: referencian a las skills personales `/pr`, `/jira`, `/handoff` sin
  duplicar sus reglas — si cambia una convención compartida (formato HANDOFF v2, mapa
  repo→board, gotchas MCP Jira), el cambio va primero en la skill personal dueña.
- Versionar: bump de `version` en `plugin.json` + `marketplace.json` en cada cambio del plugin.

## Probar el plugin local

```bash
claude plugin validate .                       # valida marketplace + plugin
claude --plugin-dir ./blackcats-delivery       # sesión con el plugin cargado sin instalar
# dentro de la sesión: /blackcats-delivery:intake, /reload-plugins tras editar
```

Instalación en una máquina (una vez):
```bash
claude plugin marketplace add parradura-org/workflows
claude plugin install blackcats-delivery@blackcats
```
