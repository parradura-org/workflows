---
name: visual-qa
description: Usar cuando una tarea de UI se considera terminada y todavía no se vio en el navegador, antes de un PR con cambios visuales, o cuando el usuario reporta que algo "se ve mal" o "sigue igual".
user-invocable: true
---

# Visual QA: el loop se cierra con evidencia, no con optimismo

Regla global del usuario que esta skill hace ejecutable: **un fix de UI no está terminado
hasta verlo funcionando en el navegador.** El mecanismo es el loop de screenshot-review, con
tope duro porque el refinamiento visual tiene rendimientos decrecientes.

**Qué cuenta como cambio visual**: todo diff que toque CSS, tokens de diseño, clases, markup
de componentes, fuentes, assets o animaciones — incluso un solo token. "No es visual" se
demuestra con capturas antes/después idénticas; nunca se declara.

## El loop

1. **Referencia primero.** ¿Contra qué se compara? Diseño (mock, Claude Design, screenshot
   del cliente), design system del proyecto, o el brief de la spec. Sin referencia explícita:
   design system + playbook del tipo — decir cuál se usó.
2. **Levantar la app** (comando del CLAUDE.md del proyecto) y **capturar con Playwright** en
   los viewports del estudio: **320, 390, 768, 1024, 1366, 1440**. Tarea acotada (= un solo
   componente, sin position/transform/media queries nuevas) puede usar 390/768/1440; ante la
   duda, los 6. El PR siempre lleva los 6, sin excepción.
3. **Comparar y listar diferencias concretas** — medibles, no impresiones: "el gap es 24px y
   el DS pide 32", "overflow horizontal a 320". **Esta captura inicial + su lista es la
   ronda 1.** No existe "ronda 0 de diagnóstico".
4. **Corregir y volver a capturar.** Cada ciclo corregir→capturar suma una ronda. Una ronda
   se abre al **tocar código con intención visual**, no al capturar: editar sin re-capturar
   no evita la ronda — es una ronda sin cerrar, doblemente prohibida.
5. **Tope: 5 rondas — incondicional.** Aplica aunque estés seguro de la causa y aunque las
   diferencias parezcan bugs mecánicos y no decisiones de diseño. "Estoy seguro de que esta
   es la última" en la ronda 5 es la misma frase que dijiste en la 4. Al tope: **manos fuera
   del código** hasta la respuesta del usuario; la hipótesis de fix va ESCRITA en la
   escalación ("creo que es X en tal archivo; con tu OK lo aplico y capturo") — aplicarla,
   con o sin captura, ES la ronda 6.

## Cierre de diferencias

Una diferencia listada solo se cierra de dos formas: (a) una captura o medición que la
muestre resuelta, o (b) un OK explícito del usuario. Reclasificarla como "tolerancia",
"artefacto de la herramienta" o "no capturable" no la cierra: sigue contando como restante
en la escalación. Estados dinámicos (hover, flicker, transiciones) se verifican con
evaluate/video/trace de Playwright — que no salgan en un screenshot estático los deja
ABIERTOS, no cerrados.

## Además de la comparación (siempre)

- **Consola limpia**: cero errors/pageerrors acumulados durante la navegación.
- **Estados**: hover, focus visible, disabled; dark/light si el proyecto tiene ambos temas.
- **Medir, no mirar** (lección sura): ángulos, alineaciones y cajas con valores
  (evaluate/bounding boxes), no a ojo — dos bugs pasaron capturas porque "se veían bien".
- Scroll-driven animations salen `opacity:0` en capturas full-page: capturar con scroll
  avanzado o deshabilitar animaciones para la captura estructural.

## Reglas duras

- Sin captura no hay "listo". Reportar una tarea visual sin haberla visto es reportar una
  hipótesis.
- Las capturas del estado final acompañan al PR/reporte. **No abren ronda nueva SOLO si no
  hubo cambios de código desde la última captura** — si hubo cualquier cambio, esas capturas
  son la ronda siguiente y cuentan contra el tope.
- Overflow horizontal en cualquier viewport = blocker, no detalle.
- Escalar en el tope NO contradice la directiva global de autonomía: diferencias visuales que
  no convergen en 5 rondas son exactamente la "decisión de producto/UX visible al usuario
  final" donde las directivas globales piden preguntar. Una escalación con capturas +
  hipótesis lista para aprobar es UN mensaje, no un ping molesto.
- Si el usuario dice "sigue igual": no reintentar variaciones del mismo fix — reproducir en
  el navegador, diagnosticar causa raíz, recién entonces tocar código (regla global).

## Racionalizaciones prohibidas

| Excusa | Realidad |
|---|---|
| "El código es correcto, se va a ver bien" | El navegador es el juez, no el código. Capturar. |
| "Es solo un token, no es visual" | Todo diff que toca estilos entra al loop. Demostralo con captura idéntica, no lo declares. |
| "Ya lo vi en desktop, mobile debe estar bien" | Lo skeweado/absoluto rompe en 320/768, no en 1440. |
| "Aplico el fix sin capturar, así no abro la ronda 6" | La ronda se abre al tocar código. Editar sin capturar = ronda sin cerrar. |
| "Esto es un bug mecánico, el tope es para decisiones de diseño" | El tope es incondicional. La causa aparente no lo exime. |
| "El flicker no sale en screenshot, lo descarto" | Se verifica con trace/video. No capturable = abierto. |
| "Una ronda más y lo saco" (ronda 6) | El tope existe porque esto ya pasó. Escalar con evidencia. |
| "No hay diseño de referencia, no puedo comparar" | DS + playbook son la referencia. Decir cuál se usó. |
