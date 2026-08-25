# Playbook — app con backend

> v1 · Basado en tres proyectos reales: **relay** (spec-first greenfield, monorepo TS),
> **iosfa** (contract-first, api+front) y **unlam-tools/cuatri** (scaffold→hardening→launch).
> Actualizado: 2026-08-25. Lo actualiza `/retro` — nunca editar a mano sin proyecto que lo respalde.

## Cuándo aplica

Producto con lógica de negocio server-side: usuarios, datos transaccionales, API propia,
panel. Stack por defecto del estudio: front Next.js/Vercel o Vite+React, API en Railway,
Postgres (+Redis si hay colas/sesiones). Si es solo presentación → `landing`. Si el corazón
es catálogo+checkout → futuro playbook `ecommerce` (hoy: este + fases propias de pagos).

## Fases

### 0. Scope + viabilidad
- **Objetivo**: decidir QUÉ se construye y si vale la pena, por escrito.
- **Artefacto**: `PROJECT.md` (objetivo en una frase, criterio de éxito medible, fuera de
  scope v1, **presupuesto de infra explícito** — patrón cuatri: "infra ≤ USD 10/mes" como
  restricción dura con checkpoint fechado) + si hay duda de viabilidad, análisis con
  evidencia y verificación adversarial (cuatri: el análisis decidió "lanzar free" y quedó
  documentado).
- **Gate**: el usuario validó scope y criterio de éxito. **Lección central de cuatri: feature
  creep sin cerrar el MVP = no se lanza nunca.** El MVP se cierra antes de agregar nada.

### 1. Spec de producto
- **Objetivo**: que la implementación sea ejecución, no interpretación.
- **Formato según tamaño**:
  - Feature sobre base existente → SPEC del template (una por feature, vía `/intake`): contexto,
    decisiones confirmadas, deltas de modelo de datos, endpoints con auth gates, verificación e2e.
  - Greenfield grande → patrón relay-spec: docs numerados `NN-tema.md` en orden de dependencia
    (overview → data model → engine → api → ui → testing → infra) con detalle
    implementation-ready (paths exactos, schemas literales, firmas tipadas por router) +
    `TASKBOARD.md` con fases, gates explícitos por fase y tareas de una línea con dueño.
- **Advertencia (lección relay)**: la spec grande es un **artefacto de generación, no
  documentación viva** — el estado vivo va a HANDOFF.md + board. Cuando driftea, se marca
  "desactualizado — no usar como fuente de comandos", no se mantiene en paralelo.
- **Gate**: decisiones de producto confirmadas por el usuario ANTES de codear.

### 2. Modelo de datos
- **Artefacto**: schema en la fuente de verdad del ORM (Prisma schema / modelos+mappers) con
  el **porqué de cada decisión no obvia** anotado; migraciones commiteadas.
- **Reglas probadas**: migraciones aplicadas y VERIFICADAS (deploy en startup o CI); seeds
  idempotentes, **dry-run por default** (`--execute` para aplicar) con **hard-block contra el
  host de prod**; refs como strings/UUIDs documentado si el store es Mongo.
- **Gate**: migraciones corren desde cero en un ambiente limpio.

### 3. Contratos tipados
- **Artefacto**: contrato back↔front como fuente de verdad — doc de API (patrón iosfa) o tipos
  end-to-end (tRPC/Zod). Envelope de respuesta global + forma de paginación fijadas desde el
  día uno: listas pesadas devuelven `PaginatedResult<T>`, nunca listas planas (lección iosfa:
  el egress de Railway lo cobró).
- **Regla dura**: el contrato se actualiza **en el MISMO PR** que el cambio de API. Zod (o
  equivalente) en todos los boundaries.
- **Gate**: cero endpoints fuera del contrato.

### 4. Ejecución por features (el loop del motor)
- Cada feature/ticket: spec (`/intake` si no la tiene) → plan de implementación con paths
  exactos y **test-first** (patrón iosfa: el plan enumera el test que falla antes de cada
  paso) → implementación → gate = la verificación e2e de la propia spec → `/pr`.
- Arquitectura en capas en todo backend (hexagonal/clean — relay la enforcea por ESLint:
  domain/application no importan tipos del ORM, usan ports); factories para repositorios
  (patrón Interface+Factory de cuatri: la interfaz no importa nada de la DB, la factory
  inyecta el cliente concreto).
- **Gate por feature**: `typecheck + lint + test + build` en un comando, verde local antes de
  push. Los hooks lo enforcean; nunca `--no-verify`.

### 5. Testing en tres niveles + validación REAL
- Unit colocados · integración con servicios reales (Testcontainers, patrón relay) · e2e
  (Playwright) + smoke nightly.
- **La regla que existe por una herida real**: al menos UNA validación end-to-end del camino
  de valor core SIN fixtures/mocks. En relay, todo el e2e verde contra fixtures escondió
  durante semanas que la propuesta de valor central **no funcionaba**: los adapters ignoraban
  los tools y nadie clonaba repos de verdad. Verde contra mocks no es verde.
- **Gate**: el camino de valor core probado contra servicios reales, con evidencia.

### 6. CI/CD + deploy verificado
- CI por reusables de `parradura-org/workflows` (`node-ci` / `python-ci` / `release-please`);
  monorepos que no calzan documentan por qué usan CI propio. Branch flow: `dev`→ambiente de
  test, `main`→prod; PR a dev primero (regla global del usuario).
- **Deploy verificado, no asumido**: `/health` que pinguea la DB; flujo crítico (login o
  equivalente) probado E2E **en el ambiente deployado**; cuenta de test para checks de prod.
  Env vars: `.env.example` completo + validación fail-fast (el fallback silencioso a
  `localhost:3000` ya pasó una vez). Ambientes no productivos **on-demand, apagados por
  default**, con el procedimiento de encendido documentado (patrón cuatri: staging apagado a
  propósito, CUATRI-9).
- **Gate**: deploy en test verificado por el agente (Railway/Vercel CLI), no por optimismo.

### 7. Auditoría de producción + hardening
- Antes del launch (o después del MVP): `PRODUCTION_AUDIT.md` con hallazgos numerados P0/P1
  (patrón cuatri) → épicas en el board → ejecución con evidencia por ticket.
- **Gate**: P0 en cero; P1 trackeados en el board.

## Checklist de done del proyecto

- [ ] Spec/decisiones de producto confirmadas antes de codear; specs por feature en `docs/specs/`.
- [ ] Migraciones desde cero en ambiente limpio; seeds dry-run por default con hard-block a prod.
- [ ] Contrato back↔front actualizado en el mismo PR que cada cambio de API; paginación en
      toda lista pesada.
- [ ] `typecheck + lint + test + build` en un comando; hooks pre-commit/pre-push activos.
- [ ] Camino de valor core validado SIN mocks, con evidencia.
- [ ] CI verde vía reusables (o excepción documentada); flujo dev→test→main respetado.
- [ ] `/health` con ping a DB; flujo crítico e2e en el ambiente deployado; `.env.example`
      completo + fail-fast.
- [ ] HANDOFF.md actualizado (formato v2), board sincronizado con evidencia (`/jira`),
      gotchas nuevos en CLAUDE.md.

## Gotchas conocidos (transferibles)

- E2E verde contra fixtures puede esconder que el producto no funciona. La validación real
  del camino core no es opcional.
- Feature creep sin cerrar MVP = no launch (cuatri lo pagó con meses).
- Nixpacks con `NODE_ENV=production` deja de instalar devDependencies — `NPM_CONFIG_INCLUDE=dev`
  en el service de Railway (y re-setearlo si el service se recrea).
- Deployments de Railway pueden ser `REMOVED` por límites de uso con volúmenes/env intactos —
  chequear antes de reconstruir de cero.
- Turbo filtra env vars (`passThroughEnv`); puertos fijos "sugeridos" colisionan — detectar
  puertos libres.
- Tokens de clone deben scrubearse del `.git/config` persistido si un agente tiene shell en
  el workspace.
- Docs auto-generados (AGENTS.md de scaffolders) driftean: header de advertencia apuntando al
  CLAUDE.md como autoridad.
- Pins de versión llevan el porqué escrito en CLAUDE.md y el hold de dependabot documentado
  (patrón relay: "Zod v3 a propósito — v4 rompe `.default()`") — un pin sin razón escrita es
  un upgrade accidental esperando sesión.
- Los clones que leen otras sesiones (`~/startup/projects`, `~/.superset/projects`) quedan
  stale: `git fetch origin` antes de citar estado.

## Historial

- 2026-08-25 · v1 · creado por extracción de relay (spec-first, taskboard con gates, lección fixtures), iosfa (contract-first, PaginatedResult, contrato en el mismo PR) y cuatri (viabilidad documentada, migración Supabase→Railway, launch-free) · fuente: recon de repos reales
