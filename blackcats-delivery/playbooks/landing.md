# Playbook — landing / sitio estático premium

> v1 · Basado en dos proyectos reales: **sura-gaming** (Next.js 16 + Tailwind 4, cliente, ago-2026)
> y **blackcats-portfolio** (Vite + React, propio, jul-2026). Actualizado: 2026-08-25.
> Lo actualiza `/retro` — nunca editar a mano sin proyecto que lo respalde.

## Cuándo aplica

Sitio cuyo valor es **presentación y conversión**: landing, sitio institucional, portfolio,
marketing site multipágina. Contenido mayormente estático (aunque tenga CMS), sin lógica de
negocio server-side propia. Si hay usuarios logueados, panel o datos transaccionales → es
`backend-app` con una landing adentro, no esto.

## Fases

### 0. Material fuente
- **Objetivo**: juntar TODO lo que existe de marca antes de diseñar nada.
- **Artefacto**: `brand/` (solo lectura: brandbook, logos SVG, tipografías licenciadas, key
  visuals, referencias del cliente — hasta la foto de WhatsApp de un mock sirve) + en
  `PROJECT.md` la lista **"Pendiente del cliente"** con lo que falta.
- **Gate**: cada pieza de diseño futura es rastreable a una fuente de esta carpeta. Regla de
  sura: *"nothing invented from memory"* — lo que no tiene fuente, se pide; no se inventa.

### 1. Dirección de arte + design system
- **Objetivo**: el sistema visual completo ANTES de la primera sección codeada.
- **Artefacto**: `design-system/` con la estructura probada en sura-gaming:
  - `README.md`: fuentes del sistema (tabla origen→qué se tomó), fundamentos de contenido
    (voz, mecánicas de copy verificables: casing, CTAs verb-first, presupuesto de acento tipo
    "una cláusula verde por headline, nunca la primera"), fundamentos visuales (color, tipo,
    spacing con ritmo de sección, whitelist de sombras/radios/blur, motion), iconografía
    (íconos copiados localmente, nunca CDN), y la lista "Missing / to request from the client".
  - `tokens/*.css`: colores base por familia + **capa semántica** (surfaces/text/lines/action/
    status) — los temas overridean SOLO los semánticos; tipografía con escala display en
    `clamp()`; spacing en grilla de 4px; effects con whitelists; motion con
    `prefers-reduced-motion` que pone TODO en 0.
  - `components/`: implementación de referencia + contrato de props (`.d.ts`) + reglas de uso
    por componente ("one primary per view", "never retype the wordmark").
  - Spec de implementación puente diseño→código con **criterios de aceptación como checklist**.
- **Gate**: el DS cubre todas las superficies del sitio; el checklist de aceptación de la spec
  existe; la lista "Missing" está en PROJECT.md.

### 2. Scaffold + enforcement mecánico
- **Objetivo**: que violar el design system sea un error de lint, no una opinión de review.
- **Artefacto**: repo scaffoldeado (CI reutilizable de `parradura-org/workflows`), CLAUDE.md
  que fija "el design system manda" ANTES del primer componente, y **linter de adherencia**
  (stylelint u oxlint): cero hex crudos, cero px mágicos, font-families fuera de las
  declaradas, radius/sombras fuera de la whitelist → falla el lint. Patrón blackcats:
  "This is intentional — don't work around it."
- **Gate**: `lint` falla ante un hex hardcodeado en `src/`. Probarlo a propósito.

### 3. Build por secciones + pasadas de craft
- **Objetivo**: construir en el orden que no genera retrabajo y darle el nivel "premium".
- **Orden probado**: tokens → assets → componentes → página → responsive. **"No arranques por
  la página."**
- El premium sale de pasadas de craft DESPUÉS del build base: el "momento" visual de la página
  (en sura: el corte a 14°), textura, contadores, micro-motion — y una pasada de PODA guiada
  por el presupuesto de motion del DS (en sura: ambient = solo glow drift + marquee; entradas
  = fades cortos) + mecanismo de pausa en la página para todo movimiento >5s (WCAG 2.2.2 —
  hallazgo A2 de sura). Pocas animaciones ejecutadas bien le ganan a muchas.
- **Gate**: home completa desde el DS + `/visual-qa` verde en 320/390/768/1024/1366/1440.

### 4. Contenido real y editable
- **Objetivo**: copy fuera de los componentes y honesto.
- **Artefacto**: contenido como datos (JSON versionado + validación en build con error legible
  — patrón Zod de blackcats: "A CMS save must never break the deployed site silently"). Si el
  cliente edita: CMS (Keystatic/Pages CMS) con contrato schema↔CMS **testeado con el loop real
  editar→commit→deploy** + guía de edición para no-técnicos.
- Qué copy es real y qué es placeholder queda marcado **por escrito**.
- **Gate**: build falla con contenido inválido; el loop CMS completo probado una vez.

### 5. Auditoría multi-agente
- **Objetivo**: encontrar todo lo que un review casual no ve.
- **Método probado en sura** (33 agentes): un auditor por **sección** × un auditor por
  **dimensión** (a11y, SEO, performance, responsive, conversión/copy, estructura) →
  consolidación con IDs por hallazgo (A/C/S/P/U/R/E/N/X) → **verificación adversarial de los
  hallazgos graves** → crítico de completitud. Salida: plan por fases (0=bugs/riesgos,
  1=conversión, 2=estructura, 3=SEO, 4=a11y+perf) + sección **"Lo que está bien — preservar,
  no mejorar"** (protege lo logrado de mejoras destructivas).
- **Gate**: `AUDITORIA.md` con hallazgos numerados y plan aceptado.

### 6. Ejecución del plan
- **Regla**: un commit por hallazgo (o grupo coherente), **con los IDs en el mensaje y la
  medición que respalda el fix**. "Verificar el resultado, no el mecanismo": medir el ángulo,
  no mirarlo — dos bugs de sura pasaron capturas porque "se veía bien".
- **Gate**: todos los hallazgos del plan cerrados o descartados con razón escrita.

### 7. Verificación adversarial independiente
- **Objetivo**: verificar los CLAIMS de la ejecución, no confiar en ellos.
- **Método**: verificadores independientes sobre el rango de commits + navegador en los 6
  viewports del estudio (los de `/visual-qa`). En sura este paso encontró **15 claims
  parciales/rotos y 33 problemas nuevos** sobre 91 OK — la punch-list se resuelve ANTES de
  pushear.
- **Gate**: punch-list vacía.

### 8. Launch
- **Gate final** (todo verificable, nada de "se ve bien"):
  - Lighthouse ≥95 en las 4 categorías × TODAS las rutas, build de prod, Chrome real.
  - axe 0 violaciones por ruta (tras esperar animaciones de entrada — dan falsos positivos de
    contraste mid-fade); teclado completo; reduced-motion real (tokens a 0 + video sin montar).
  - SEO por ruta EN EL HTML SERVIDO: title/description/og/canonical (en SPA: prerender
    post-build **con fallo ruidoso** si un replace no matchea); 404 con status real; sitemap/
    robots/hreflang consistentes; apex vs www = el canonical declarado.
  - Forms honestos: el success no promete lo que el sistema no hace; honeypot en todos;
    form presente en el HTML prerenderizado; rate-limit/abuse guard en las server actions.
  - **El evento de conversión primaria queda registrado** (analytics o log del server action),
    verificado con un submit de prueba en el ambiente deployado — el funnel no puede fallar
    en silencio (hallazgo #1 de la auditoría de sura: "no hay una sola línea de telemetría
    para enterarse de nada de esto").
  - Seguridad: la ruta de admin del CMS NO responde 200 anónima en prod (curl al deploy —
    /keystatic quedó público una vez); security headers presentes (frame-ancestors, nosniff,
    referrer-policy).
  - Deploy: push a main = prod ⇒ **gate de validación visual del dueño antes del push**.
    Pendientes de launch trackeados en HANDOFF/board.

## Checklist de done del proyecto

- [ ] Cero hex/px crudos en `src/` — enforcement mecánico activo y probado.
- [ ] Presupuesto de acento y whitelists (sombras/radios/blur) respetados.
- [ ] Wordmark siempre asset; íconos locales.
- [ ] Sin overflow horizontal 320→1440; el "momento" visual colapsa con dignidad en mobile.
- [ ] Lighthouse ≥95 ×4 categorías × todas las rutas; LCP identificado y precargado.
- [ ] axe 0 por ruta; focus trap real en modales; `aria-disabled` + guard en submits (no
      `disabled`, que expulsa el foco del tab order).
- [ ] Cache immutable para assets renombrables — y EXCLUIDOS los directorios de upload del CMS.
- [ ] Contenido validado en build; contrato CMS↔schema testeado con el loop real.
- [ ] Admin del CMS con auth verificada en prod + security headers; conversión primaria con
      telemetría verificada por submit de prueba.
- [ ] E2E que acumula console errors/pageerrors y exige cero.
- [ ] Gotchas nuevos → CLAUDE.md del proyecto; decisiones con fecha y condición de reversa.

## Gotchas conocidos (transferibles)

- Scroll-driven animations salen `opacity:0` en capturas de página completa — screenshot con
  scroll avanzado o regla `@media print`.
- `useSearchParams` + `Suspense fallback={null}` puede hacer que el form de conversión primaria
  NO exista en el HTML prerenderizado.
- Metadata de Next resuelve POR SEGMENTO y no cascadea: cada ruta anidada verifica su propio
  og:image.
- Lighthouse de perf solo con Chrome real; el headless-shell de Playwright no da scores.
- Lo skeweado/clip-path se verifica a 320 y 768, no solo a 1440 (skew mide contra alto,
  translate % contra ancho).
- Print: fondos por selector + textos por token — ya se imprimió un CTA invisible una vez.
- Vercel Deployment Protection/SSO bloquea al cliente: verificar acceso externo (incógnito /
  bypass link) ANTES de pedir feedback — sura perdió el loop de review por esto.

## Historial

- 2026-08-25 · v1 · creado por extracción de sura-gaming (proceso DS→build→auditoría→verificación adversarial) y blackcats-portfolio (enforcement stylelint, content-as-data, prerender SEO, gate Lighthouse) · fuente: recon de repos reales
