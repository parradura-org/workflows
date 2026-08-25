# SPEC — <título corto del cambio>

> Ticket: <KEY-N o "sin board: docs/specs/">
> Fecha: YYYY-MM-DD · Origen: <quién lo pidió y por qué canal>
> Estado: draft | lista | en ejecución | implementada (PR #N)

## Contexto

<Por qué existe este pedido, en 2-4 líneas. Qué problema resuelve y para quién.>

## Alcance

### Objetivo
<Qué va a poder hacer el sistema cuando esto esté hecho. Una frase verificable.>

### Fuera de scope (explícito)
- <Todo lo que alguien podría asumir que entra y NO entra. Cada línea acá ahorra un ciclo de retrabajo.>

## Diseño

### Archivos e interfaces involucrados
<Paths exactos. Una spec que no nombra archivos no es autocontenida.>

| Path | Qué se toca |
|---|---|
| `src/...` | |

### Decisiones confirmadas
<Decisiones ya tomadas (por el usuario o por diseño). Con fecha si vinieron del usuario — "X NO va (decisión del usuario YYYY-MM-DD)".>

| Decisión | Por qué |
|---|---|

### Deltas de modelo de datos / contratos
<Solo si aplica: cambios de schema, endpoints nuevos con auth gates, cambios de contrato back↔front. Si cambia la API: el doc de contrato se actualiza en el MISMO PR.>

## Criterios de aceptación

<Given/When/Then o checklist. Cada criterio tiene que ser verificable sin interpretación.>

- [ ] Dado <estado>, cuando <acción>, entonces <resultado observable>

## Verificación end-to-end (obligatoria)

<El paso final machine-checkable que demuestra que el cambio funciona de punta a punta: el comando exacto, el flujo de navegador con Playwright, o el request con la respuesta esperada. **Sin este paso, la spec no está terminada.** La implementación no se reporta como lista hasta que este paso pasa.>

```bash
# comando(s) exacto(s)
```
