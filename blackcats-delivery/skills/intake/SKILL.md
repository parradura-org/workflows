---
name: intake
description: Usar cuando llega un pedido de feature, cambio o bug — "me pidieron X", "el cliente quiere", "habría que agregar", "encontré un bug" — INCLUSO si se va a implementar ya mismo, siempre que no exista spec ni ticket que lo respalde. También para capturar hallazgos en medio de otro trabajo.
user-invocable: true
---

# Intake: todo pedido entra por spec, nunca por prompt

Un pedido que se resuelve "de una" en una sesión suelta es trabajo invisible: sin spec no hay
criterio de done, sin ticket no existe para el board, y la próxima sesión no sabe qué pasó.
El intake tiene dos modos según cuándo se va a trabajar el pedido — pero **siempre produce un
artefacto registrado**.

## Modo 1 — Captura liviana

Para hallazgos en medio de otro trabajo (bug visto al pasar, mejora, deuda) o pedidos que NO
se van a trabajar ahora: **solo el ticket**, por la captura de la skill `jira` — contexto
(archivo/módulo), repro o evidencia, label `agent-captured`; buscar duplicados por JQL antes
de crear. Sin spec y sin preguntas al usuario: la spec se escribe cuando `/next` tome el
ticket. Capturar y volver al trabajo en curso, en el momento (no "al final").

Sin board: una línea en la sección de pendientes del START HERE del HANDOFF (qué + dónde +
evidencia).

## Modo 2 — Intake completo (el pedido está por trabajarse)

1. **Entender el pedido.** Si falta información para una spec autocontenida, preguntar con
   AskUserQuestion — **todas las preguntas juntas, una sola vez** (regla global del usuario).
   Preguntar solo lo que la spec necesita y el código no puede responder.
2. **Escribir la spec** desde `${CLAUDE_PLUGIN_ROOT}/templates/SPEC.md` en
   `docs/specs/YYYY-MM-DD-<slug>.md` del proyecto. Autocontenida = nombra archivos e
   interfaces, declara fuera de scope, y **termina con la verificación end-to-end
   machine-checkable**. Una spec sin ese paso final no está terminada.
3. **Crear el ticket** (board según el mapa canónico de la skill `jira`) con el path de la
   spec en la descripción. Sin board: la spec en `docs/specs/` ES la cola; registrarla en el
   START HERE del HANDOFF.
4. **Reportar**: path de la spec + ticket + estado (`lista` para `/next`). Si el usuario
   quiere que se implemente ya: seguir en esta misma sesión, **contra la spec recién
   escrita**, no contra el pedido verbal.

## Bypass para lo trivial

Lista **cerrada**: typo, string de copy, un valor de estilo. Nada más — que un cambio
"parezca igual de chico" no lo mete en la lista.

El checklist corre SIEMPRE antes de invocar el bypass — no sentir dudas no es evidencia de
trivialidad; es el síntoma típico de estar por saltearse la spec. Enumerá: (a) archivos que
vas a tocar, (b) decisiones que vas a tomar. Bypass solo con **1 archivo, cero decisiones
(nada que el usuario podría querer distinto), cero comportamiento nuevo**. Cualquier feature
cabe en una oración — la oración describe el PEDIDO, no el diff; el test es archivos y
decisiones, no palabras.

Rastro obligatorio: commit convencional + una línea en el ticket que cubre ese código. Si no
existe tal ticket, el bypass no aplica — crear el ticket ES intake.

## Reglas duras

- La spec se escribe ANTES de tocar código, siempre que no aplique el bypass.
- La urgencia no elige bypass — elige implementar en esta misma sesión, contra la spec. Una
  spec de este tamaño cuesta ~10 minutos; si de verdad urge, esos 10 minutos entran.
- Fuera de scope vacío = spec incompleta. Siempre hay algo que alguien podría asumir que entra.
- Decisiones que tomó el usuario van con fecha: "X NO va (decisión del usuario YYYY-MM-DD)".
- Interpretaciones razonables tomadas por ambigüedad menor quedan ANOTADAS en la spec como
  supuestos (regla global: seguir y dejarlo anotado, no frenar).

## Racionalizaciones prohibidas

| Excusa | Realidad |
|---|---|
| "Cabe en una oración, es chico" | Todo cabe en una oración. El test es archivos y decisiones, no palabras. |
| "El usuario dijo que no es difícil" | El usuario no vio el diff. La dificultad percibida no es el test. |
| "Lo hago ya, así que intake no aplica" | Intake aplica antes de CUALQUIER trabajo sin spec, incluido el que arranca ahora mismo. |
| "Escribo la spec después de implementar" | Una spec post-hoc documenta, no especifica. El orden es la mitad del valor. |
| "Spec + ticket es la ceremonia que el usuario quiere evitar" | La directiva global evita pedir confirmación, no producir artefactos. |
| "No hay board, así que no hay ticket" | Sin board la cola es `docs/specs/` + HANDOFF. El pedido queda registrado igual. |
