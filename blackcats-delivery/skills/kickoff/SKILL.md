---
name: kickoff
description: Usar cuando arranca un proyecto nuevo o un repo vacío — "nos llegó un ecommerce", "arranquemos el sitio de X", "proyecto nuevo para el cliente Y" — antes de escribir cualquier código o diseño.
user-invocable: true
---

# Kickoff: el proyecto nace con sistema

Un proyecto que arranca "a codear" hereda decisiones que nadie tomó. El kickoff produce los
artefactos fundacionales y deja el proyecto enchufado al sistema del estudio: playbook, board,
CI, memoria.

## Flujo

1. **Clasificar el tipo** y cargar su playbook desde `${CLAUDE_PLUGIN_ROOT}/playbooks/`
   (`landing.md`, `backend-app.md`, ...). El playbook define las fases, artefactos y gates —
   esta skill no los repite.
   - **Tipo sin playbook** (ecommerce, mobile, ...): usar el playbook del tipo más cercano +
     `${CLAUDE_PLUGIN_ROOT}/templates/playbook.md` para crear el v0 del tipo nuevo **en el
     repo del proyecto nuevo** (`docs/playbook-<tipo>-v0.md`), referenciado desde PROJECT.md
     como hipótesis. El v0 NUNCA se sube al repo de workflows — la primera versión real
     (`v1`) la escribe `/retro` al cerrar este proyecto, partiendo de ese v0 local. **No
     inventar un playbook especulativo detallado.**
2. **Entrevista de scope** con AskUserQuestion — todas las preguntas juntas: objetivo en una
   frase, criterio de éxito medible, fuera de scope v1, restricciones (presupuesto, fecha,
   stack impuesto, cliente edita contenido o no). Lo que el código no puede responder y la
   spec necesita, se pregunta acá — una sola vez.
3. **PROJECT.md** desde `${CLAUDE_PLUGIN_ROOT}/templates/PROJECT.md`, completo, incluida la
   lista "Pendiente del cliente" (assets, credenciales, contenido — pedirlos HOY: es lo que
   más bloquea después). Decisiones fundacionales con consecuencias → ADR
   (`${CLAUDE_PLUGIN_ROOT}/templates/ADR.md`) en `docs/adr/`.
4. **Board**: crear/identificar el proyecto Jira, **agregar la fila al mapa repo→board de la
   skill `jira`** (es el mapa canónico) **y a la tabla "Repos activos conocidos" de la skill
   `panorama`** (repo + path del clone; si el clone vive fuera de las raíces que panorama
   globea, anotarlo ahí — si no, panorama lo omite en silencio). Crear las épicas = fases del
   playbook + épicas propias del scope. Cliente sin board: la cola es `docs/specs/` — dejarlo
   escrito en PROJECT.md.
5. **Scaffold del repo**: git + remote en la org correcta, branch flow (`dev` default, `main`
   prod — runbook `AGENTS.md` de `parradura-org/workflows` para CI reutilizable, protección y
   release-please), CLAUDE.md inicial (corto: qué es, comandos, reglas duras del proyecto —
   crece con gotchas reales, no con relleno), HANDOFF.md v2 (formato de la skill `handoff`),
   `docs/specs/` y `docs/adr/` vacíos.
6. **Reportar**: tipo + playbook usado, PROJECT.md, board con épicas, repo scaffoldeado, y la
   primera fase del playbook lista para arrancar con `/next`.

## Reglas duras

- No se escribe código de producto en el kickoff. El kickoff termina donde empieza la fase 0
  del playbook.
- El criterio de éxito es medible o no es criterio ("que quede lindo" no; "Lighthouse ≥95 y
  flujo de compra e2e verde" sí).
- Scope sin "fuera de scope" explícito = kickoff incompleto.
- El playbook se LEE, no se recita: si una fase no aplica a este proyecto, anotarlo en
  PROJECT.md con el porqué (y `/retro` decidirá si el playbook cambia).
