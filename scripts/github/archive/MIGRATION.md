# Migraciones ejecutadas sobre el Project #5

Registro factual de operaciones ya aplicadas. No es documentación de uso: los
scripts conservados aquí son **evidencia histórica** y no deben reutilizarse
como sincronizador general.

---

## 2026-09-26 — Limpieza del Project #5

### Contexto

- Project: **#5** (`ikd-powerinsight`)
- Owner: `karolldahian`
- Repositorio: `karolldahian/ikd-powerinsight`
- Estado inicial: **193 items**

### Operación ejecutada

1. Retirar del Project #5 los items correspondientes a los Issues **#90-#99**
   (fase RAG antigua, WBS `P9.1`-`P9.10`).
2. **No** eliminar ni modificar esos Issues.
3. Configurar los cinco campos de planificación del Issue **#229**.

### Valores aplicados al Issue #229

| Campo | Valor |
|---|---|
| Status | `Backlog` |
| Phase | `P6` |
| Priority | `Critical` |
| Effort | `5` |
| Work Type | `Test` |

### Resultado verificado

- Project #5 = **183 items**
- **0** WBS duplicados
- **0** items sin WBS
- **0** campos inesperadamente vacíos
- #90-#99 siguen **CLOSED / NOT_PLANNED**, conservados y **fuera** del Project #5
- **34** Issues cerrados permanecen dentro del Project #5, sin modificación alguna
- Exit code: `0`

### Script utilizado

`scripts/github/cleanup-project5-superseded.ps1`

Ejecutado en una única invocación con `-Apply`, precedida de un dry-run que
validó los gates y produjo el plan de 15 mutaciones (10 `item-delete` +
5 `item-edit`).

### Estado de este script

Se conserva **en la ruta donde se ejecutó** (`scripts/github/`) como evidencia
reproducible de esta migración. No se movió a `archive/` en este commit.

**No debe reutilizarse como sincronizador general.** Es una operación one-shot,
de alcance cerrado y con assertions específicas (#90-#99 presentes en el
Project, #229 con exactamente cinco campos vacíos) que hoy ya no se cumplen.
Reejecutarlo sería un no-op, no una comprobación de integridad.

La automatización mantenible del Project #5 se substituye por
`project_sync.ps1` con fuente declarativa propia.
