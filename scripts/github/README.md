# Automatizacion GitHub / Kanban

Infraestructura operativa del Project #5 de `karolldahian/ikd-powerinsight`.

## Superficie operativa

| Ruta | Rol |
|---|---|
| `project_sync.ps1` | Sincronizador declarativo. Unica pieza ejecutable. |
| `ikd-powerinsight-backlog.json` | Fuente declarativa de planificacion (schema v2). |
| `archive/` | Historico. No ejecutar. Ver `archive/MIGRATION.md`. |

## Project #5 es el Project operativo

Todas las referencias apuntan al Project **#5** del owner `karolldahian`.
Ningun otro Project es operativo. Los Project numbers hardcodeados en
`archive/` son historicos y no aplican.

## Identidad: el numero de Issue

**La identidad primaria de una tarjeta es su numero de Issue.**

El WBS **no** es identidad. El WBS se almacena y se valida, pero jamas se usa
para localizar un item. Ya se observo en produccion que un WBS puede reutilizarse
en una fase posterior; un sincronizador que localice por WBS asignaria el
esfuerzo o la prioridad de una tarea a otra.

Por eso `project_sync.ps1` indexa siempre por `issue`.

## Campos administrados

Solo cinco campos del Project:

| Clave JSON | Campo en el Project | Tipo |
|---|---|---|
| `status` | `Status` | select |
| `phase` | `Phase` | select |
| `priority` | `Priority` | select |
| `effort` | `Effort` | numero |
| `workType` | `Work Type` | select |

`workType` en el JSON corresponde al campo `work Type` de la API, que lleva
espacio y mayuscula. La tabla puente vive dentro del script y es el unico lugar
donde se conoce ese nombre.

Ademas de los cinco campos administrados, el JSON guarda `wbs` y `title` como
**metadata de revision**, no como campos que el script administre:

- `wbs` es la identidad que el script valida (`phase == prefijo de wbs`).
- `title` es el titulo vivo completo, para que una persona pueda leer el WBS y
  su texto sin abrir GitHub. El invariante I16 comprueba que `title` empiece
  por `wbs`.

Un Issue renombrado en GitHub **no** es `DRIFT` y el script nunca reescribe un
titulo: `title` es de solo lectura. Si el renombrado cambia el WBS, eso si lo
detectan I5 e I7. GitHub sigue siendo autoritativo para `milestone`, `body`,
`state`, `stateReason` y `labels`, que **no** se copian al JSON.

## Schema v2

```json
{
  "meta": {
    "schemaVersion": 2,
    "repository": "karolldahian/ikd-powerinsight",
    "projectNumber": 5,
    "source": "github-live-export",
    "generatedAt": "2026-09-26T20:06:44Z",
    "keyedBy": "issue"
  },
  "items": [
    {
      "issue": 229,
      "wbs": "P6.13",
      "title": "P6.13 - Cerrar Gate G6 de ingesta y OCR",
      "phase": "P6",
      "status": "Backlog",
      "priority": "Critical",
      "effort": 5,
      "workType": "Test"
    }
  ]
}
```

`meta.repository` y `meta.source` no son decorativos: los invariantes I14 e
I15 abortan con exit code 2 si el JSON apunta a otro repositorio o si no
declara `source: "github-live-export"`. Un archivo que no viene del Project
vivo no es fuente de verdad.

`phase` se almacena de forma explicita para poder validar el invariante
`phase == prefijo de wbs` sin depender del Project.

### El JSON representa intencion, no un espejo congelado

El JSON es la intencion declarativa de planificacion. Una edicion deliberada del
archivo es legitima y puede expresar una decision futura.

Lo que **no** ocurre es que la edicion se aplique sola: con la politica actual
un `DRIFT` se reporta y se revisa, y no puede aplicarse automaticamente. Ver
`-Apply` mas abajo.

`-Export` existe para bootstrap y reconstruccion desde GitHub, no para regenerar
el archivo antes de cada commit.

**`archive/backlog-legacy.json` esta obsoleto y no es fuente de verdad.** Es un
snapshot de 161 entradas de un Project que tiene 183 items, con schema v1. El
script nunca lo lee. Regenerar el JSON desde el legacy devolveria el Project a
un estado que ya no existe, y reintroduciria los items que la migracion del
Commit A retiro. Si `-Export` falla por rate limit o por un error de API, la
salida correcta es detenerse: **nunca** sustituir datos vivos por el legacy.

## Clasificacion

| Clase | Significado | `-Apply` |
|---|---|---|
| `MATCH` | El valor vivo es igual al declarado. | No-op. |
| `MISSING` | El campo vivo esta vacio y el declarado tiene valor. | Completa el campo. |
| `DRIFT` | Ambos tienen valor y son distintos. | **Aborta.** No sobrescribe. |
| `CONFLICT` | El valor declarado no existe en la taxonomia viva del campo. | **Aborta.** |
| `ORPHAN` | Declarado en el JSON pero ausente del Project. | **Aborta.** |

Un DRIFT significa que alguien cambio el Project y el JSON quedo atras, o que el
JSON declara algo que el Project no refleja. En ambos casos la respuesta correcta
es decidir, no automatizar.

## Modos

### Default: diff de solo lectura

Sin parametros de escritura. Lee el JSON, lee GitHub, compara y muestra las
diferencias. No escribe nada, ni en GitHub ni en disco.

```powershell
.\scripts\github\project_sync.ps1
```

Es el comando habitual que se ejecuta antes de cualquier commit que toque
planificacion.

### -Export: GitHub -> JSON

Lee el Project #5 vivo, valida los invariantes del lado Project y regenera el
JSON con schema v2, ordenado de forma determinista. No modifica GitHub.

```powershell
.\scripts\github\project_sync.ps1 -Export
```

Usarlo para bootstrap, para reconstruir el archivo, o para reflejar en el JSON
un cambio hecho directamente en el Project.

### -Apply: JSON -> Project, solo MISSING

Requiere el flag explicito. Solo completa campos vacios. Si existe cualquier
`DRIFT`, `CONFLICT`, `ORPHAN`, un item del Project sin entrada en el JSON, o un
`CLOSED` con cambios pendientes, aborta **antes de la primera mutacion**.

```powershell
.\scripts\github\project_sync.ps1 -Apply
```

En el estado actual el Project esta completo, asi que `-Apply` no tiene nada que
hacer y sale sin mutaciones.

### La cobertura incompleta tambien es un gate

Un item presente en el Project pero ausente del JSON no se puede sincronizar
nunca, porque el JSON es la fuente declarativa. Si `-Apply` lo ignorara,
completaria los demas campos y su verificacion final diria que todo esta en
orden sin senalar que ese item quedo fuera. Por eso la cobertura incompleta
detiene la operacion: primero se declara, despues se escribe.

### El tipo de cada campo se verifica

El tipo se deduce de la API viva y ademas se compara con el tipo que el campo
debe tener: `Status`, `Phase`, `Priority` y `Work Type` deben ser listas, y
`Effort` un numero. Si alguien cambiara `Status` de una lista a un campo de
texto, el script no intentaria escribir un `--number` sobre el: detiene con
exit code 2.

## CLOSED

Un Issue `CLOSED` que permanece legitimamente dentro del Project no se modifica.
Si tiene un `MISSING` o un `DRIFT`, el script lo reporta y aborta antes de
mutar. No existe override para esta situacion.

## Milestones

`project_sync.ps1` **no modifica milestones**. Solo valida que el prefijo del
milestone vivo coincida con `Phase`. No existe `-SyncMilestones`.

Los milestones se gobiernan por el ciclo normal de trabajo, no por el
sincronizador.

## Invariantes

Validados siempre, antes de cualquier `-Apply`. Una violacion produce exit code
distinto de cero y cero mutaciones.

1. `issue` unico en el JSON.
2. `issue` unico en el Project.
3. WBS unico dentro del Project.
4. Cada item gestionado tiene WBS valido.
5. El WBS almacenado coincide con el extraido del titulo vivo.
6. El `phase` almacenado coincide con el prefijo del WBS.
7. El `Phase` vivo coincide con el prefijo del WBS.
8. El milestone vivo existe.
9. El prefijo del milestone vivo coincide con `Phase`.
10. Todos los Issues declarados existen.
11. Todos los Issues declarados pertenecen al Project #5.
12. `meta.schemaVersion == 2`.
13. `meta.projectNumber == 5`.
14. `meta.repository == karolldahian/ikd-powerinsight`.
15. `meta.source == github-live-export`.
16. El `title` almacenado existe y empieza por el `wbs` almacenado.

## Filtros

```powershell
.\scripts\github\project_sync.ps1 -Phase P6
.\scripts\github\project_sync.ps1 -Issue 229
.\scripts\github\project_sync.ps1 -Phase P6 -Issue 229
```

Sin filtro se consideran todos los items declarados. Los filtros reducen la
presentacion y el plan; **no** desactivan los gates globales de integridad.

## Cobertura

El export cubre por completo el Project #5. El diff default detecta:

- items del JSON ausentes del Project (`ORPHAN`).
- items del Project ausentes del JSON (esto tambien detiene `-Apply`).
- Issues declarados que no existen.
- WBS duplicados.
- numeros de Issue duplicados.

Ninguna de esas condiciones se corrige automaticamente. Crear Issues, agregar
items al Project o eliminarlos del Project quedan fuera del alcance de este
script: son decisiones, no acciones automaticas.

## Codigos de salida

| Codigo | Significado |
|---|---|
| 0 | Sin inconsistencias. |
| 1 | Inconsistencias detectadas (`DRIFT`, `CONFLICT`, `ORPHAN`, cobertura, `CLOSED` con cambios). |
| 2 | Error duro: invariante rota, tipo de campo inesperado, gate fallido, o fallo de `gh`. Cero mutaciones. |

## Requisitos

- PowerShell 5.1 (Windows).
- `gh` CLI autenticado, con acceso de lectura al Project #5 y al repositorio.

## Seguridad de las mutaciones

Todo el codigo capaz de escribir en GitHub esta dentro de un unico bloque
alcanzable solo con `-Apply`. Sin `-Apply` el script no tiene ruta de escritura
remota: no existen llamadas a edicion de Issues, de milestones, ni de alta o
baja de items en el Project.

`gh` falla si se excede el rate limit. El script aborta con exit code 2 en lugar
de tratar un error como si fuera una respuesta vacia.

## archive/

`archive/` es historico y **no debe ejecutarse**.

| Artefacto | Motivo |
|---|---|
| `cleanup-project5-superseded.ps1` | Migracion one-shot ya aplicada el 2026-09-26. Sus assertions ya no se cumplen. |
| `setup-github-backlog.ps1` | Apunta al Project #3, que no existe. Crea, cierra y edita Issues. |
| `update-project-fields.ps1` | IDs de Project, campos y opciones hardcodeados; empareja por WBS y sobreescribe. |
| `backlog-legacy.json` | 161 entradas de un Project de 183 items. Schema v1. |

Los tres scripts llevan **una cabecera `.ADVERTENCIA` en su interior** que dice
que son historicos y que no deben ejecutarse contra el Project #5. El codigo
original no se toco: el unico cambio es el bloque de comentario inicial.

`cleanup-project5-superseded.ps1` es el caso especial. El Commit A (`23d42b7`)
preservo su blob exacto, sin cambios. Al anadir la cabecera, ese blob deja de
ser byte-identico en el working tree, pero sigue intacto e identificable en el
historial Git:

| | SHA-256 |
|---|---|
| Blob de Commit A (`23d42b7`) | `EFA1E3CDBFD74876227824016AF3E49150CC27211A36F02F12707F4BB5B8D238` |
| Con cabecera de advertencia | distinto, y esperado: solo se anaden lineas de comentario |

Detalle de la migracion y de esta transformacion: `archive/MIGRATION.md`.
