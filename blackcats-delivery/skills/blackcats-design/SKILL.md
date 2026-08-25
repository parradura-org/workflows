---
name: blackcats-design
description: Usar al crear o reformar cualquier UI o pieza visual en un proyecto del estudio — páginas, secciones, componentes, emails, piezas de marketing — antes de escribir el primer estilo.
---

# Diseño Blackcats: nunca el default de la distribución

Sin dirección, los modelos convergen en el centro estadístico de su entrenamiento: diseño
genérico que se reconoce a un vistazo como "hecho con IA". Esta skill existe para que ningún
proyecto del estudio salga de ahí. No define una identidad de marca — **cada proyecto tiene
la suya, en su design system** — define el piso de calidad y el proceso.

## El design system manda (requisito estructural)

- Todo proyecto tiene design system propio: tokens (color con capa semántica, tipografía,
  spacing, effects con whitelists, motion) + componentes con contrato + reglas de marca. El
  molde de referencia del estudio es el DS de sura-gaming (estructura descrita en
  `${CLAUDE_PLUGIN_ROOT}/playbooks/landing.md`, fase 1).
- **Si el proyecto no tiene DS, crearlo ES la primera tarea visual** — antes de la primera
  sección. Diseñar sin sistema es generar deuda con intereses.
- Con DS presente: el DS gana. Esta skill no lo overridea jamás; llena los huecos que el DS
  no cubre.

## Prohibido: los looks default de IA

Si el resultado matchea alguno de estos, es el centro de la distribución — rehacer la
dirección, no retocarla:

- Cream/beige tibio + serif display + acento terracota "editorial calmo".
- Near-black + un solo acento ácido (verde/violeta) + grotesca "tech".
- Gradiente violeta→azul en hero sobre blanco, cards `rounded-lg` con sombra suave.
- Inter/Roboto/Open Sans como única voz tipográfica; emoji como bullets; todo centrado.
- Hairlines de broadsheet + columnas densas "revista" sin razón de contenido.

(La excepción de siempre: si el usuario o el DS piden explícitamente uno de estos, sus
palabras ganan.)

## Dirección positiva (las cuatro palancas)

1. **Tipografía con carácter**: pareja display+body elegida para ESTE proyecto (nunca la
   misma pareja que el proyecto anterior), escala con `clamp()`, jerarquía que se sostiene
   sin colores. La tipografía es la personalidad de la página.
2. **Color con postura**: un mundo cromático propio del sujeto + presupuesto de acento
   explícito y contable (patrón sura: "una cláusula verde por headline, nunca la primera").
   Neutros elegidos (con sesgo de matiz), no heredados.
3. **El momento**: cada página premium tiene UN gesto memorable — un corte, una textura, una
   interacción — ejecutado con precisión (en sura: el corte a 14°). Un momento fuerte y todo
   lo demás quieto le gana a diez efectos.
4. **Motion con presupuesto**: pocas animaciones, de alto impacto, CSS-first,
   `prefers-reduced-motion` a cero vía tokens. La pasada de PODA es parte del proceso (12→3
   momentos animados en sura).

## Proceso en dos pasadas

1. **Plan antes de codear**: sujeto y audiencia en una frase → paleta nombrada (4-6 valores)
   → pareja tipográfica → concepto de layout → el "momento". Revisar el plan: ¿alguna parte
   es lo que cualquier modelo haría para cualquier página parecida? Esa parte se rediseña
   antes de escribir código.
2. **Critique después de buildear**: con el resultado en el navegador (`/visual-qa`),
   preguntarse por sección: ¿esto lo defendería un diseñador senior cobrando caro, o es
   relleno competente? Lo que defaulteó, se rehace.

## Reglas duras

- Valores hand-tuned lockeados en el DS ("do not clean these up") se respetan: no son deuda,
  son diseño.
- Wordmark siempre asset. Íconos locales. Nada de CDN de terceros para assets de marca.
- Copy es material de diseño: verb-first en CTAs, sin emoji decorativo, sin promesas que el
  sistema no cumple.
