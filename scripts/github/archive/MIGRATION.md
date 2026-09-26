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

`scripts/github/archive/cleanup-project5-superseded.ps1`

Ejecutado en una única invocación con `-Apply`, precedida de un dry-run que
validó los gates y produjo el plan de 15 mutaciones (10 `item-delete` +
5 `item-edit`).

### Estado de este script

Commit A lo conservó **en la ruta donde se ejecutó** (`scripts/github/`) para
preservar la evidencia sin alterar su contenido. Commit B lo movió a `archive/`
y le añadió una cabecera `.ADVERTENCIA` al inicio. Ver "Transformación de los
artefactos archivados" más abajo.

- Blob registrado en `23d42b7` (Commit A), sin cabecera:
  `EFA1E3CDBFD74876227824016AF3E49150CC27211A36F02F12707F4BB5B8D238`
  (23018 bytes, 0 bytes CR)
- Ese blob **sigue intacto en el historial Git** y es la copia de referencia
  byte a byte de lo que realmente se ejecutó.

**No debe reutilizarse como sincronizador general.** Es una operación one-shot,
de alcance cerrado y con assertions específicas (#90-#99 presentes en el
Project, #229 con exactamente cinco campos vacíos) que hoy ya no se cumplen.
Reejecutarlo sería un no-op, no una comprobación de integridad.

---

## 2026-09-26 — Retiro de la infraestructura histórica (Commit B)

### Contexto

El Commit A preservó la evidencia de la limpieza. El Commit B retira de la
superficie operativa la automatización obsoleta y la substituye por un
sincronizador declarativo propio.

### Artefactos retirados de la superficie operativa

| Desde | Hacia | Motivo |
|---|---|---|
| `scripts/github/cleanup-project5-superseded.ps1` | `scripts/github/archive/cleanup-project5-superseded.ps1` | Migración one-shot ya aplicada. |
| `scripts/github/setup-github-backlog.ps1` | `scripts/github/archive/setup-github-backlog.ps1` | Apunta al Project **#3**, que no existe. Crea, cierra y edita Issues. |
| `scripts/github/update-project-fields.ps1` | `scripts/github/archive/update-project-fields.ps1` | IDs y conteos hardcodeados; empareja por WBS. |
| `scripts/github/ikd-powerinsight-backlog.json` | `scripts/github/archive/backlog-legacy.json` | Schema v1 con 161 entradas de un Project de 183 items. |

### Contenido preservado y transformación de los artefactos archivados

El legacy JSON **no se editó**: conserva sus 161 entradas y su contenido
intacto, con el mismo blob (`c8e08644b6085bbe2d855ce96b94092878623cb6`) que
tenía en el Commit A. El nuevo
`scripts/github/ikd-powerinsight-backlog.json` se generó desde el estado vivo
del Project #5 con `-Export` y es un archivo distinto con schema v2.

Los tres scripts archivados **sí** recibieron una transformación: se les añadió
un bloque de comentario `.ADVERTENCIA` al inicio, para que quien abra el archivo
directamente vea que es histórico y que no debe ejecutarse contra el Project #5.
No basta con avisar en este documento: el riesgo real es que alguien abra el
script y lo ejecute.

| Artefacto | Líneas añadidas | Líneas borradas |
|---|---|---|
| `cleanup-project5-superseded.ps1` | 14 | 0 |
| `setup-github-backlog.ps1` | 13 | 0 |
| `update-project-fields.ps1` | 15 | 0 |

**Ningúnscript perdió código.** En `setup-github-backlog.ps1` y
`update-project-fields.ps1` el diff muestra una línea eliminada porque su BOM
UTF-8 estaba adherido a `param([switch]$Apply)`, que era la primera línea del
archivo; al anteponer el bloque de comentario, ese BOM pasa a abrir el archivo y
`param(...)` queda como la última línea del bloque. El BOM sigue en el byte 0 y
el `param` sigue siendo un bloque de parámetros válido (`ParamBlockAst` con el
parámetro `Apply`).

Consecuencia asumida y aceptada: el blob de `cleanup-project5-superseded.ps1`
**ya no es byte-idéntico** al del Commit A, porque lleva la cabecera. La copia
byte-exacta de lo que se ejecutó sigue disponible e identificable:

```
git cat-file -p 23d42b7:scripts/github/cleanup-project5-superseded.ps1
```

### Sustituto

`scripts/github/project_sync.ps1` con fuente declarativa propia
(`schemaVersion` 2, indexada por número de Issue).

El archivo declarativo se genera siempre desde el Project vivo con `-Export`
(GitHub → JSON local). `backlog-legacy.json` no se lee nunca como entrada: es un
snapshot obsoleto de 161 entradas frente a un Project de 183 items.

Los Items heredados del Project #5 que permanecen en el archivo exportado
conservan su condición de `CLOSED` sin ser modificados: el sincronizador nunca
escribe sobre un Issue cerrado.

La automatización mantenible del Project #5 es `project_sync.ps1` con fuente
declarativa propia. Los scripts de este directorio **no deben ejecutarse**.
