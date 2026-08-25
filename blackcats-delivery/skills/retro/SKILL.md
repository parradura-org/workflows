---
name: retro
description: Usar al cerrar un proyecto, milestone o bloque grande de trabajo — "cerremos esta etapa", post-launch, fin de auditoría — o cuando el trabajo reveló algo que el playbook del tipo de proyecto no cubría.
user-invocable: true
---

# Retro: la experiencia vuelve al sistema

Los playbooks valen porque acumulan proyectos reales — el flujo se optimiza trabajando, como
un dev que ya hizo diez de estos. Sin retro, cada proyecto enseña y el sistema no aprende.
La retro tiene tres salidas, las tres al repo correspondiente: playbook, CLAUDE.md, deuda
documentada.

## Flujo

1. **Reconstruir qué pasó de verdad**: HANDOFF (Historial completo del bloque), git log del
   rango, board. No de memoria — la memoria de sesión embellece.
2. **Contrastar contra el playbook** (`${CLAUDE_PLUGIN_ROOT}/playbooks/<tipo>.md`):
   - ¿Qué fase faltó, sobró o se hizo en otro orden — y funcionó? → cambio de fases.
   - ¿Qué gate dejó pasar un problema que después dolió? → gate nuevo o más estricto.
   - ¿Qué gotcha transferible apareció? → sección de gotchas.
   - ¿Qué se hizo distinto por buena razón y el playbook lo prohibiría? → relajar el playbook.
   - Proyecto de tipo sin playbook → escribir el v1 real desde
     `${CLAUDE_PLUGIN_ROOT}/templates/playbook.md`, partiendo del v0 local del proyecto
     (`docs/playbook-<tipo>-v0.md`, si `/kickoff` lo creó) y de lo que este proyecto enseñó.
3. **Actualizar el playbook vía PR** al repo `parradura-org/workflows` (shepherding con la
   skill `pr`; base `main` — ese repo no tiene `dev`): editar fases/gates/gotchas + una línea
   en el Historial del playbook (`fecha · vN · qué cambió · proyecto que lo enseñó`). Cambios
   de una línea igual van por PR: el playbook es infraestructura compartida. El PR sigue el
   CLAUDE.md de ese repo — incluye bump de `version` en
   `blackcats-delivery/.claude-plugin/plugin.json` y `.claude-plugin/marketplace.json`,
   porque los playbooks son parte del plugin.
4. **Refinar el CLAUDE.md del proyecto** (loop de mejora continua): gotchas específicos del
   repo descubiertos y no anotados, comandos que cambiaron, decisiones con fecha. Mantenerlo
   corto: conocimiento profundo va a docs/skills, no al CLAUDE.md.
5. **Cerrar la trazabilidad**: decisiones tomadas en chat sin ADR → escribirlas ahora;
   pendientes que quedaron en la nada → tickets (`/intake`); board sincronizado (`/jira`);
   HANDOFF con el cierre (`/handoff` si termina la sesión).

## Reglas duras

- **Regla de cierre del sistema**: si algo se decidió o aprendió en el chat y no quedó en un
  repo (playbook, CLAUDE.md, ADR, spec, ticket), la retro no terminó. Que no exista nada que
  el humano sepa y el agente de la próxima sesión no.
- Al playbook solo entra lo **transferible entre proyectos del tipo**. Lo específico del repo
  va a su CLAUDE.md. Ante la duda: CLAUDE.md.
- El Historial del playbook es append-only; nunca reescribir entradas anteriores.
- Una retro sin ningún cambio propuesto es sospechosa: si de verdad no hay nada, decir
  explícitamente qué se revisó y por qué no hay cambios.
