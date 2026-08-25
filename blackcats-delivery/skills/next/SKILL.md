---
name: next
description: Usar cuando una sesión va a arrancar trabajo en un proyecto y hay que decidir qué sigue — "seguí con lo que venga", "agarrá el próximo ticket", "qué hago ahora acá", o al retomar un proyecto después del handoff.
user-invocable: true
---

# Next: el board decide, no la sesión

El problema que esta skill elimina: cada sesión decidía ad-hoc qué hacer y resolvía los
tickets como le parecía. Acá la prioridad vive en el board (o en la cola de specs), y la
sesión **ejecuta lo que la cola diga**. Elegir trabajo es un privilegio del humano que
prioriza, no del agente que ejecuta. Elegir y ejecutar es de ESTA skill; `jira` solo
sincroniza el board y captura tickets — ante el trigger "¿qué sigo?", la que manda es esta.

## Flujo

1. **Leer contexto**: HANDOFF.md (START HERE + últimas líneas del Historial) + CLAUDE.md del
   proyecto. Si hay algo a medias en el START HERE, **terminarlo tiene prioridad sobre
   empezar algo nuevo**.
2. **Leer la cola — una sola vez**:
   - Con board (mapa repo→board y gotchas de MCP en la skill `jira`: `fields` acotados,
     `responseContentFormat: "markdown"`, `maxResults ≤ 50`):
     `project = <KEY> AND statusCategory != Done ORDER BY Rank ASC` — el Rank ES el orden en
     que el humano arrastró las tarjetas; los boards son team-managed y el campo `priority`
     suele estar sin tocar, así que ordenar por priority mentiría. Filtrar las que esperan
     testing DEL usuario (regla de `jira`: no tocarlas).
   - Sin board: specs con estado `lista` en `docs/specs/`, la más vieja primero.
   - **El orden es el resultado de esa consulta, corrida una vez.** No re-consultar con otro
     orden, no usar convenciones de tipo ("los bugs van primero"), no aplicar urgencia
     percibida.
3. **Tomar EL PRIMER ticket elegible** (elegible = tiene spec, o pasa el checklist del bypass
   de `intake` LEYENDO el código primero — nunca por estimación previa; y no está bloqueado
   en el usuario). Moverlo a In Progress con comentario.
4. **Sin spec y no trivial** → escribir la spec ahora (modo 2 de `intake`, con la única tanda
   de preguntas si hace falta) antes de tocar código. No improvisar contra el título del
   ticket.
5. **Ejecutar spec-first**: Explore → Plan → Implement contra la spec. El gate de salida es
   **la verificación end-to-end que la propia spec definió** — no "parece que anda". Cambios
   visuales → `/visual-qa` antes del PR.
6. **PR** con la skill `pr` (shepherding hasta merge, post-merge Jira y branch base los
   define `pr`).
7. **Cerrar**: si la sesión sigue, volver al paso 2. Si termina, `/handoff`.

## Reglas duras

- **Nunca elegir un ticket que no sea el primero elegible.** Si el orden del board parece
  incorrecto, reportarlo — y **reportar no autoriza a alterarlo**: hasta que el usuario
  responda, se ejecuta el primero tal como está. "No frenar el trabajo" se cumple ejecutando
  el primero, no el preferido.
- **Un ticket a la vez (WIP = 1).** No se vuelve al paso 2 hasta que el actual esté Done
  (verificación e2e + PR mergeado) o quede esperando EXCLUSIVAMENTE al usuario, reportado. El
  tiempo muerto de CI/reviews se usa en el shepherding de ESE PR, no en arrancar el siguiente.
- **El scope del PR es la spec del ticket en curso.** Código que resuelva OTRO ticket no
  entra en este PR, ni aunque su tarjeta no se mueva: tocar su código ES elegirlo. Aplica
  igual a tickets existentes que a hallazgos nuevos. Lo único permitido: un comentario en ese
  ticket con lo que sabés (hipótesis de fix incluida).
- Un hallazgo en el camino NO se resuelve "ya que estoy": captura liviana de `intake` (ticket
  `agent-captured`, sin spec) y se sigue con el ticket actual.
- **"Bloqueado en el usuario"** = el ticket tiene una pregunta abierta REGISTRADA (comentario
  o label) esperando respuesta. Un ticket con spec aprobada no se auto-declara bloqueado: la
  spec ya es la decisión del usuario. **"Bloquea literalmente"** = no podés completar el paso
  en curso y tenés el error concreto de ESTA sesión para pegar en el ticket — riesgo
  hipotético no es bloqueo; aun con bloqueo real, se arregla SOLO lo mínimo para desbloquear
  y el fix completo va en su propio ticket.
- No existe excepción de urgencia auto-declarada. Emergencia aparente (pérdida de datos,
  seguridad) → escalar al usuario con el caso armado y ESPERAR su respuesta.
- Un ticket no está Done hasta que su verificación e2e pasó Y el PR mergeó. In Progress no es
  un logro.
- Sin cola (board vacío, sin specs): reportarlo y preguntar — no inventar trabajo.

## Racionalizaciones prohibidas

La tabla es ilustrativa, no taxativa: que tu excusa no figure no la vuelve válida —
**cualquier razonamiento cuyo resultado sea "entonces agarro otro ticket" está prohibido por
construcción.**

| Excusa | Realidad |
|---|---|
| "Este otro ticket es más rápido/interesante" | El orden lo puso quien prioriza. El board decide. |
| "Arreglo esto que vi al pasar, son 2 líneas" | Captura liviana + seguir. El scope del ticket es el scope. |
| "Ese ticket ya existía, no lo estoy 'eligiendo'; solo meto el fix en este PR" | Tocar su código ES elegirlo. Comentario en el ticket, nada más. |
| "El primero está 'bloqueado' porque el usuario debería confirmar" | Bloqueado = pregunta registrada esperando respuesta. Spec aprobada = ya decidió. |
| "Le avisé del orden raro, así que sigo con el que me parece" | Reportar ≠ autorización. Se ejecuta el primero hasta que responda. |
| "Mientras el PR espera CI, adelanto el próximo" | WIP = 1. El tiempo muerto es del shepherding de ese PR. |
| "No tiene spec pero el título es claro" | El título es una intención; la spec es un contrato. |
| "El board está desactualizado, uso mi criterio" | Se reporta (o se sincroniza con `jira`), no se ignora. |
