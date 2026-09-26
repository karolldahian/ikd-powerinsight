#Requires -Version 5.1
<#
.SYNOPSIS
    Limpieza controlada del Project #5: retira del project los items de los
    Issues #90-#99 (fase RAG antigua, P9.1-P9.10, cerrada como NOT_PLANNED) y
    configura los cinco campos del Issue #229 (P6.13) solo si estan vacios.

.DESCRIPTION
    Idempotente y seguro por construccion:
      - Dry-run es el comportamiento por defecto. -Apply es obligatorio para mutar.
      - Nunca edita, cierra, reabre ni renombra Issues.
      - Nunca modifica milestones.
      - Nunca ejecuta comandos Git que escriban.
      - Aborta si queda algun WBS duplicado, item sin WBS o campo vacio inesperado.

    El Project #5 vivo es la fuente de verdad. El JSON del backlog no se lee
    ni se regenera aqui.

.PARAMETER Apply
    Aplica las mutaciones. Sin este flag no se escribe nada en GitHub.
#>
[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$Owner = 'karolldahian',
    [string]$Repo = 'ikd-powerinsight',
    [int]$ProjectNumber = 5
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoFull = "$Owner/$Repo"

# ============================================================
# CONJUNTO SUPERSEDED: Issues cerrados de la fase RAG antigua.
# Se retiran del Project #5 unicamente; los Issues no se tocan.
# ============================================================

$SupersededIssues = [ordered]@{
    90  = 'P9.1'
    91  = 'P9.2'
    92  = 'P9.3'
    93  = 'P9.4'
    94  = 'P9.5'
    95  = 'P9.6'
    96  = 'P9.7'
    97  = 'P9.8'
    98  = 'P9.9'
    99  = 'P9.10'
}

# ============================================================
# SEED: Issue recien creado con los campos del Project pendientes.
# Valores especificados por el usuario. No se infieren.
# ============================================================

$SeedIssueNumber = 229
$SeedExpectedWbs = 'P6.13'

# `Key` es el nombre exacto de la propiedad que devuelve
# `gh project item-list --format json`. Ojo: Work Type lleva espacio.
$TrackedFields = @(
    [pscustomobject]@{ Key = 'status';    FieldName = 'Status';    Kind = 'select' }
    [pscustomobject]@{ Key = 'phase';     FieldName = 'Phase';     Kind = 'select' }
    [pscustomobject]@{ Key = 'priority';  FieldName = 'Priority';  Kind = 'select' }
    [pscustomobject]@{ Key = 'effort';    FieldName = 'Effort';    Kind = 'number' }
    [pscustomobject]@{ Key = 'work Type'; FieldName = 'Work Type'; Kind = 'select' }
)

$SeedExpected = [ordered]@{
    'status'    = 'Backlog'
    'phase'     = 'P6'
    'priority'  = 'Critical'
    'effort'    = 5
    'work Type' = 'Test'
}

# ============================================================
# HELPERS
# ============================================================

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}

function Get-GhJson {
    param([string[]]$Arguments)

    $command = "gh $($Arguments -join ' ')"

    # Una sola invocacion: nunca se reintenta. En caso de fallo se reportan
    # exit code y stderr para no ocultar la causa real (rate limit, red, etc).
    $global:LASTEXITCODE = 0
    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {

        $detail = (($output | ForEach-Object { [string]$_ }) -join ' | ').Trim()

        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = '(stderr vacio)'
        }

        throw "$command fallo con exit code $exitCode. Detalle: $detail"
    }

    # En exito se descarta cualquier linea de stderr para no corromper el JSON.
    $stdout = (($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) | Out-String)

    if ([string]::IsNullOrWhiteSpace($stdout)) {
        throw "$command devolvio una respuesta vacia."
    }

    try {
        $parsed = $stdout | ConvertFrom-Json
    }
    catch {
        throw "$command devolvio una respuesta que no es JSON valido. Respuesta: $stdout"
    }

    if ($null -eq $parsed) {
        throw "$command devolvio JSON vacio."
    }

    return $parsed
}

function Invoke-Gh {
    param([string[]]$Arguments)

    $raw = & gh @Arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "gh $($Arguments -join ' ') fallo con exit code $LASTEXITCODE : $raw"
    }

    return $raw
}

function Get-WbsFromTitle {
    param([string]$Title)

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $null
    }

    if ($Title -match '^(P\d+\.\d+)(\s|$)') {
        return $Matches[1]
    }

    return $null
}

function Test-ValueEmpty {
    param($Value)

    if ($null -eq $Value) {
        return $true
    }

    return [string]::IsNullOrWhiteSpace([string]$Value)
}

function Test-ValueEqual {
    param($Actual, $Expected)

    if (Test-ValueEmpty $Actual) {
        return $false
    }

    if ($Expected -is [int] -or $Expected -is [double] -or $Expected -is [long]) {
        $parsed = 0.0
        if (-not [double]::TryParse(([string]$Actual), [ref]$parsed)) {
            return $false
        }
        return $parsed -eq [double]$Expected
    }

    return ([string]$Actual).Trim() -eq ([string]$Expected).Trim()
}

function Get-ItemValue {
    param($Item, [string]$Key)

    $prop = $Item.PSObject.Properties[$Key]

    if ($null -eq $prop) {
        return $null
    }

    return $prop.Value
}

# ============================================================
# AUDITORIA
# ============================================================

function Invoke-Audit {
    param(
        [object[]]$Items,
        [hashtable]$IssueStateByNumber,
        [string]$Label
    )

    Write-Section "REAUDITORIA ($Label)"

    $scored = @(
        foreach ($item in $Items) {
            [pscustomobject]@{
                Number  = [int]$item.content.number
                Title   = [string]$item.title
                ItemId  = [string]$item.id
                Wbs     = Get-WbsFromTitle $item.title
            }
        }
    )

    # WBS duplicados
    $dupes = @($scored | Where-Object { $_.Wbs } | Group-Object Wbs | Where-Object Count -gt 1)

    if ($dupes.Count -gt 0) {
        Write-Host "WBS DUPLICADOS: $($dupes.Count)" -ForegroundColor Red
        foreach ($group in $dupes) {
            Write-Host ("  {0} x{1}" -f $group.Name, $group.Count) -ForegroundColor Red
            foreach ($member in $group.Group) {
                Write-Host ("      #{0}  {1}" -f $member.Number, $member.Title)
            }
        }
    }
    else {
        Write-Host "WBS duplicados  : 0" -ForegroundColor Green
    }

    # Items sin WBS
    $noWbs = @($scored | Where-Object { -not $_.Wbs })

    if ($noWbs.Count -gt 0) {
        Write-Host "ITEMS SIN WBS  : $($noWbs.Count)" -ForegroundColor Red
        foreach ($member in $noWbs) {
            Write-Host ("      #{0}  {1}" -f $member.Number, $member.Title) -ForegroundColor Red
        }
    }
    else {
        Write-Host "Items sin WBS   : 0" -ForegroundColor Green
    }

    # Campos vacios
    $empties = @()

    foreach ($spec in $TrackedFields) {
        $missing = @(
            $Items | Where-Object { Test-ValueEmpty (Get-ItemValue $_ $spec.Key) }
        )

        if ($missing.Count -gt 0) {
            $empties += [pscustomobject]@{
                Field = $spec.FieldName
                Count = $missing.Count
                Items = $missing
            }
        }
    }

    if ($empties.Count -gt 0) {
        Write-Host "CAMPOS VACIOS   : detectados" -ForegroundColor Yellow
        foreach ($entry in $empties) {
            Write-Host ("      {0,-10} {1} item(s)" -f $entry.Field, $entry.Count) -ForegroundColor Yellow
            foreach ($member in $entry.Items) {
                Write-Host ("          #{0}  {1}" -f $member.content.number, $member.title)
            }
        }
    }
    else {
        Write-Host "Campos vacios   : 0 en los 5 campos" -ForegroundColor Green
    }

    # Trazabilidad de issues cerrados que permanecen en el project
    $closed = @($scored | Where-Object { $IssueStateByNumber[$_.Number] -eq 'closed' })

    Write-Host ""
    Write-Host ("Items auditados : {0}" -f $scored.Count)
    Write-Host ("Issues abiertos : {0}" -f @($scored | Where-Object { $IssueStateByNumber[$_.Number] -eq 'open' }).Count)
    Write-Host ("Issues cerrados : {0} (se conservan, no se editan)" -f $closed.Count)

    return [pscustomobject]@{
        DuplicateWbs   = $dupes.Count
        ItemsWithoutWbs = $noWbs.Count
        EmptyFields    = $empties.Count
    }
}

# ============================================================
# PREFLIGHT
# ============================================================

Write-Section "MODO"

if ($Apply) {
    Write-Host "APPLY: se modificara GitHub." -ForegroundColor Yellow
}
else {
    Write-Host "DRY-RUN: GitHub NO sera modificado. Usa -Apply para escribir." -ForegroundColor Green
}

Write-Section "PREFLIGHT"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "gh CLI no esta disponible en el PATH."
}

Write-Host "gh            : $((& gh --version | Select-Object -First 1))"
Write-Host "Repo          : $RepoFull"
Write-Host "Project       : #$ProjectNumber (owner $Owner)"

# La autenticacion se valida de forma implicita: si el token faltara o fuera
# invalido, la primera consulta GraphQL de abajo fallaria y abortaria el script.
# No se ejecuta `gh auth status` porque su resultado no se usaba.

# Project debe resolver. El node ID es requerido por `project item-edit`.
$projectView = Get-GhJson @('project', 'view', "$ProjectNumber", '--owner', $Owner, '--format', 'json')
$projectNodeId = [string]$projectView.id

if ([string]::IsNullOrWhiteSpace($projectNodeId)) {
    throw "No se pudo resolver el node ID del Project #$ProjectNumber."
}

Write-Host "Project #$ProjectNumber : $projectNodeId" -ForegroundColor Green

# Resolver campos y opciones desde el project vivo, sin confiar en IDs hardcodeados.
$fieldList = Get-GhJson @('project', 'field-list', "$ProjectNumber", '--owner', $Owner, '--format', 'json')

$fieldByName = @{}

foreach ($field in $fieldList.fields) {
    $fieldByName[$field.name] = $field
}

foreach ($spec in $TrackedFields) {
    if (-not $fieldByName.ContainsKey($spec.FieldName)) {
        throw "El Project #$ProjectNumber no expone el campo '$($spec.FieldName)'."
    }
}

Write-Host "Campos         : Status, Phase, Priority, Effort, Work Type presentes" -ForegroundColor Green

# Resolver los option IDs necesarios para el seed.
$seedOptionIds = @{}

foreach ($spec in $TrackedFields) {

    if ($spec.Kind -ne 'select') {
        continue
    }

    $field = $fieldByName[$spec.FieldName]
    $wanted = [string]$SeedExpected[$spec.Key]
    $option = $null

    if ($null -ne $field.options) {
        $option = @($field.options | Where-Object { $_.name -eq $wanted } | Select-Object -First 1)
    }

    if ($option.Count -eq 0) {
        throw "El campo '$($spec.FieldName)' no tiene la opcion '$wanted'."
    }

    $seedOptionIds[$spec.Key] = $option[0].id
}

Write-Host "Opciones seed  : validas" -ForegroundColor Green

# ============================================================
# ESTADO VIVO
# ============================================================

Write-Section "ESTADO VIVO"

$project = Get-GhJson @('project', 'item-list', "$ProjectNumber", '--owner', $Owner, '--limit', '500', '--format', 'json')
$items = @($project.items)

# Issues via REST. El bucket de rate limit de REST es independiente del de
# GraphQL, asi que GATE 1 sigue siendo verificable durante un bloqueo de
# GraphQL. Campos: number, title, state, state_reason.
$issueList = @(Get-GhJson @('api', "repos/$RepoFull/issues", '--paginate', '-f', 'state=all', '-f', 'per_page=100', '-X', 'GET') |
    Where-Object { -not $_.PSObject.Properties['pull_request'] })

$issueByNumber = @{}
$issueStateByNumber = @{}

foreach ($issue in $issueList) {
    $issueByNumber[[int]$issue.number] = $issue
    $issueStateByNumber[[int]$issue.number] = [string]$issue.state
}

Write-Host ("Issues en {0} : {1} (abiertos {2} / cerrados {3}) [REST]" -f `
    $RepoFull, $issueList.Count, `
    @($issueList | Where-Object state -eq 'open').Count, `
    @($issueList | Where-Object state -eq 'closed').Count)

Write-Host ("Items en Project #{0} : {1}" -f $ProjectNumber, $items.Count)

# Verificar que los items son todos Issues con numero (Gh no usa otro tipo aqui).
foreach ($item in $items) {
    if (-not $item.content.number) {
        throw "El Project #$ProjectNumber contiene un item sin numero de Issue: '$($item.title)'."
    }
}

# ============================================================
# GATE 1: los Issues #90-#99 siguen siendo los esperados
# ============================================================

Write-Section "GATE 1 - VALIDACION DE ISSUES SUPERSEDED ($($SupersededIssues.Count))"

$gateFailures = @()
$removals = @()

foreach ($entry in $SupersededIssues.GetEnumerator()) {

    $number = [int]$entry.Key
    $expectedWbs = [string]$entry.Value
    $issue = $null

    if (-not $issueByNumber.ContainsKey($number)) {
        $gateFailures += "#$number no existe en $RepoFull."
        continue
    }

    $issue = $issueByNumber[$number]

    # REST usa state en minuscula y el campo state_reason (no stateReason).
    $stateOk = ([string]$issue.state -eq 'closed')
    $reasonOk = ([string]$issue.state_reason -eq 'not_planned')
    $actualWbs = Get-WbsFromTitle ([string]$issue.title)
    $wbsOk = ($actualWbs -eq $expectedWbs)

    if (-not $stateOk) {
        $gateFailures += "#$number esta '$($issue.state)'; se esperaba closed. No se retira nada."
    }

    if (-not $reasonOk) {
        $gateFailures += "#$number tiene state_reason '$($issue.state_reason)'; se esperaba not_planned. No se retira nada."
    }

    if (-not $wbsOk) {
        $gateFailures += "#$number tiene WBS '$actualWbs'; se esperaba '$expectedWbs'. No se retira nada."
    }

    $item = @($items | Where-Object { [int]$_.content.number -eq $number } | Select-Object -First 1)
    $inProject = $item.Count -gt 0

    if ($inProject) {
        $removals += [pscustomobject]@{
            Number = $number
            ItemId = [string]$item[0].id
            Title  = [string]$issue.title
        }
    }

    $mark = if ($stateOk -and $reasonOk -and $wbsOk) { 'OK' } else { 'FALLA' }
    $color = if ($mark -eq 'OK') { 'Green' } else { 'Red' }
    $where = if ($inProject) { 'EN PROJECT' } else { 'ya retirado ' }

    Write-Host ("  #{0,-4} {1,-6} {2,-7} {3,-11} {4,-5} {5}" -f `
        $number, $mark, [string]$issue.state, [string]$issue.state_reason, $expectedWbs, $where) -ForegroundColor $color
}

if ($gateFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "GATE 1 FALLIDO:" -ForegroundColor Red
    foreach ($failure in $gateFailures) {
        Write-Host "  $failure" -ForegroundColor Red
    }
    throw "Validacion de Issues superseded fallida. No se realizo ninguna mutacion."
}

Write-Host ""
Write-Host "GATE 1: correcto. $($removals.Count) item(s) a retirar, $($SupersededIssues.Count - $removals.Count) ya retirados." -ForegroundColor Green

# ============================================================
# GATE 2: estado del Issue #229
# ============================================================

Write-Section "GATE 2 - ISSUE #$SeedIssueNumber ($SeedExpectedWbs)"

$seedIssue = $null

if (-not $issueByNumber.ContainsKey($SeedIssueNumber)) {
    throw "El Issue #$SeedIssueNumber no existe en $RepoFull."
}

$seedIssue = $issueByNumber[$SeedIssueNumber]
$seedWbs = Get-WbsFromTitle ([string]$seedIssue.title)

if ($seedWbs -ne $SeedExpectedWbs) {
    throw "El Issue #$SeedIssueNumber tiene WBS '$seedWbs'; se esperaba '$SeedExpectedWbs'."
}

Write-Host ("#{0}  {1}  {2}  {3}" -f $SeedIssueNumber, $seedIssue.state, $seedWbs, $seedIssue.title)

$seedItem = @($items | Where-Object { [int]$_.content.number -eq $SeedIssueNumber } | Select-Object -First 1)

if ($seedItem.Count -eq 0) {
    throw "El Issue #$SeedIssueNumber no esta en el Project #$ProjectNumber."
}

$seedItem = $seedItem[0]

$emptyKeys = @()
$mismatched = @()
$matched = @()

foreach ($spec in $TrackedFields) {

    $actual = Get-ItemValue $seedItem $spec.Key
    $expected = $SeedExpected[$spec.Key]

    if (Test-ValueEmpty $actual) {
        $emptyKeys += $spec.Key
    }
    elseif (Test-ValueEqual $actual $expected) {
        $matched += $spec.Key
    }
    else {
        $mismatched += [pscustomobject]@{
            Field    = $spec.FieldName
            Actual   = $actual
            Expected = $expected
        }
    }
}

foreach ($spec in $TrackedFields) {
    $actual = Get-ItemValue $seedItem $spec.Key
    $state = if (Test-ValueEmpty $actual) { 'VACIO   ' } else { 'asignado' }
    Write-Host ("  {0,-10} {1,-9} actual='{2}'  esperado='{3}'" -f `
        $spec.FieldName, $state, $(if (Test-ValueEmpty $actual) { '-' } else { $actual }), $SeedExpected[$spec.Key])
}

$seedAction = 'NINGUNO'

# C) Valor distinto al esperado -> abortar antes de cualquier mutacion.
if ($mismatched.Count -gt 0) {
    Write-Host ""
    Write-Host "GATE 2 FALLIDO: hay campos con valor distinto al esperado. No se sobrescribe nada." -ForegroundColor Red
    foreach ($entry in $mismatched) {
        Write-Host ("  {0,-10} actual='{1}'  esperado='{2}'" -f $entry.Field, $entry.Actual, $entry.Expected) -ForegroundColor Red
    }
    throw "El Issue #$SeedIssueNumber tiene valores que no coinciden. No se realizo ninguna mutacion."
}

# A) ya correctos -> conservar, no reescribir. B) vacios -> pendientes.
# La rama parcial (COMPLETAR) hace el apply reanudable tras una interrupcion
# entre dos item-edit: solo se escriben los campos que siguen vacios.
if ($emptyKeys.Count -eq $TrackedFields.Count) {
    $seedAction = 'CONFIGURAR'
    Write-Host ""
    Write-Host "Los 5 campos estan vacios: se configuraran en el apply." -ForegroundColor Yellow
}
elseif ($emptyKeys.Count -eq 0) {
    $seedAction = 'YA-CONFIGURADO'
    Write-Host ""
    Write-Host "Los 5 campos ya coinciden con lo esperado. Nada que hacer." -ForegroundColor Green
}
else {
    $seedAction = 'COMPLETAR'
    Write-Host ""
    Write-Host ("Estado parcial recuperable: {0} campo(s) ya correctos se conservan, {1} pendiente(s): {2}" -f `
        $matched.Count, $emptyKeys.Count, ($emptyKeys -join ', ')) -ForegroundColor Yellow
}

# Especificacion de campos a escribir durante -Apply, en el orden de $TrackedFields.
$seedPendingSpecs = @(
    foreach ($spec in $TrackedFields) {
        if ($emptyKeys -contains $spec.Key) { $spec }
    }
)

# ============================================================
# PLAN
# ============================================================

$mutationCount = $removals.Count + $seedPendingSpecs.Count

Write-Section "PLAN ($mutationCount mutacion/es)"

$planIndex = 0

foreach ($removal in $removals) {
    $planIndex++
    $verb = if ($Apply) { 'DELETE ' } else { 'borrar  ' }
    Write-Host ("  [{0,2}] {1} item {2}  (#{3})" -f $planIndex, $verb, $removal.ItemId, $removal.Number)
}

foreach ($spec in $seedPendingSpecs) {
    $planIndex++
    $verb = if ($Apply) { 'SET    ' } else { 'setear ' }
    Write-Host ("  [{0,2}] {1} #{2} {3} = {4}" -f `
        $planIndex, $verb, $SeedIssueNumber, $spec.FieldName, $SeedExpected[$spec.Key])
}

if ($planIndex -eq 0) {
    Write-Host "  (vacio - el Project ya esta en el estado deseado)" -ForegroundColor Green
}

# ============================================================
# APLICAR
# ============================================================

if ($Apply) {

    Write-Section "APLICANDO"

    foreach ($removal in $removals) {
        $null = Invoke-Gh @(
            'project', 'item-delete', "$ProjectNumber",
            '--owner', $Owner,
            '--id', $removal.ItemId
        )

        Write-Host ("  retirado #{0}  {1}" -f $removal.Number, $removal.Title) -ForegroundColor Green
    }

    # Orden 1: retirar #90-#99. Orden 2: completar #229.
    # Solo se escriben los campos que siguen vacios ($emptyKeys): los que ya
    # tienen el valor esperado se conservan y no se reescriben.
    foreach ($spec in $seedPendingSpecs) {

        $editArgs = @(
            'project', 'item-edit',
            '--id', [string]$seedItem.id,
            '--project-id', $projectNodeId,
            '--field-id', [string]$fieldByName[$spec.FieldName].id
        )

        if ($spec.Kind -eq 'select') {
            $editArgs += @('--single-select-option-id', [string]$seedOptionIds[$spec.Key])
        }
        else {
            $editArgs += @('--number', [string]$SeedExpected[$spec.Key])
        }

        $null = Invoke-Gh $editArgs

        Write-Host ("  #{0} {1} = {2}" -f `
            $SeedIssueNumber, $spec.FieldName, $SeedExpected[$spec.Key]) -ForegroundColor Green
    }
}

# ============================================================
# REAUDITORIA
# ============================================================

$remainingItems = $items

if ($Apply) {

    $post = Get-GhJson @('project', 'item-list', "$ProjectNumber", '--owner', $Owner, '--limit', '500', '--format', 'json')
    $remainingItems = @($post.items)
    $auditLabel = "estado real post-apply"
}
else {

    $removedNumbers = @($removals | ForEach-Object { $_.Number })
    $remainingItems = @($items | Where-Object { $removedNumbers -notcontains [int]$_.content.number })
    $auditLabel = "estado simulado (dry-run, no aplicado)"
}

$audit = Invoke-Audit -Items $remainingItems -IssueStateByNumber $issueStateByNumber -Label $auditLabel

# ============================================================
# VEREDICTO
# ============================================================

Write-Section "VEREDICTO"

$problems = @()

if ($audit.DuplicateWbs -gt 0) {
    $problems += "Quedan $($audit.DuplicateWbs) WBS duplicado(s)."
}

if ($audit.ItemsWithoutWbs -gt 0) {
    $problems += "Quedan $($audit.ItemsWithoutWbs) item(s) sin WBS."
}

if ($problems.Count -gt 0) {

    foreach ($problem in $problems) {
        Write-Host "  $problem" -ForegroundColor Red
    }

    Write-Host ""
    if ($Apply) {
        Write-Host "La limpieza no deja el Project #$ProjectNumber integro. Revisar manualmente." -ForegroundColor Red
    }
    exit 1
}

Write-Host "  Sin WBS duplicados" -ForegroundColor Green
Write-Host "  Sin items sin WBS" -ForegroundColor Green

if ($audit.EmptyFields -gt 0) {
    Write-Host "  Campos vacios pendientes: $($audit.EmptyFields) (revisar arriba)" -ForegroundColor Yellow
}
else {
    Write-Host "  Los 5 campos completos en todos los items" -ForegroundColor Green
}

Write-Host ""
if ($Apply) {
    Write-Host "LIMPIEZA APLICADA. Items en el Project #$ProjectNumber : $($remainingItems.Count)" -ForegroundColor Green
    Write-Host "Issues #90-#99 siguen cerrados y sin tocar."
}
else {
    Write-Host "DRY-RUN TERMINADO. GitHub NO fue modificado." -ForegroundColor Green
    Write-Host "Items actuales : $($items.Count)"
    Write-Host "Items esperados : $($remainingItems.Count)"
    Write-Host "Ejecuta con -Apply para aplicar."
}
