#Requires -Version 5.1
<#
.SYNOPSIS
    Sincronizador declarativo del Project #5 (ikd-powerinsight).

.DESCRIPTION
    Compara la intencion declarativa de planificacion (backlog JSON, schema v2)
    contra el estado vivo del Project #5 y, solo bajo demanda explicita,
    completa los campos que esten vacios.

    Principios de diseno:
      - La identidad de una tarjeta es su numero de Issue. NUNCA el WBS.
      - El WBS es un dato de auditoria: se valida, no se usa para localizar.
      - GitHub es autoritativo para titulo, milestone, body, state y labels.
      - El default es lectura pura: sin -Export ni -Apply no se escribe nada,
        ni en GitHub ni en disco.
      - Un valor vivo distinto del declarado (DRIFT) NUNCA se sobrescribe.
      - Un Issue CLOSED nunca se modifica.
      - Los milestones solo se validan, nunca se escriben.

    Direcciones:
      -Export   GitHub vivo  ->  JSON local
      (default) JSON local   ->  solo reporte de diferencias
      -Apply    JSON local   ->  Project, unicamente completando MISSING

    Codigos de salida:
      0  Sin inconsistencias.
      1  Inconsistencias detectadas (DRIFT / CONFLICT / ORPHAN / cobertura).
      2  Error duro: invariante rota o gate fallido. Cero mutaciones.
#>
[CmdletBinding()]
param(
    [switch]$Export,
    [switch]$Apply,
    [string[]]$Phase,
    [int[]]$Issue,
    [string]$Owner = 'karolldahian',
    [string]$Repo = 'ikd-powerinsight',
    [int]$ProjectNumber = 5
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Un error no manejado NUNCA debe reportarse como exito. Sin este trap, una
# excepcion a mitad de camino deja $LASTEXITCODE con el valor de la ultima
# llamada a gh (0), y el operador leeria un fallo como operacion correcta.
$script:MutationStarted = $false

trap {

    Write-Host ""
    Write-Host "ERROR FATAL: $($_.Exception.Message)" -ForegroundColor Red

    $line = 0
    if ($null -ne $_.InvocationInfo) { $line = $_.InvocationInfo.ScriptLineNumber }
    if ($line -gt 0) { Write-Host "  origen: linea $line" -ForegroundColor Red }

    if ($script:MutationStarted) {
        Write-Host "ATENCION: el fallo ocurrio durante -Apply. Revisa el estado del Project manualmente." -ForegroundColor Red
    }
    else {
        Write-Host "Ninguna mutacion fue enviada a GitHub." -ForegroundColor Red
    }

    exit 2
}

$RepoFull = "$Owner/$Repo"
$BacklogPath = Join-Path $PSScriptRoot 'ikd-powerinsight-backlog.json'

$ExpectedSchemaVersion = 2

# Tabla puente: clave del JSON  ->  nombre exacto del campo en el Project.
# 'Work Type' lleva espacio y mayuscula en la API; el JSON usa 'workType'.
# Esta tabla es el UNICO lugar donde se conoce ese nombre.
#
# 'Expected' fija el tipo que el campo DEBE tener. La API deduce el tipo
# vivo, pero deducirlo no basta: si alguien cambiara Status de una lista a un
# campo de texto plano, la API lo seguiria reportando y el script lo
# trataria como numerico. Por eso el tipo esperado se compara con el vivo y
# una discrepancia detiene la operacion en vez de producir un --number sobre
# un campo de texto.
$ManagedFields = @(
    [pscustomobject]@{ JsonKey = 'status';   ProjectField = 'Status';    Expected = 'select' }
    [pscustomobject]@{ JsonKey = 'phase';    ProjectField = 'Phase';     Expected = 'select' }
    [pscustomobject]@{ JsonKey = 'priority'; ProjectField = 'Priority';  Expected = 'select' }
    [pscustomobject]@{ JsonKey = 'effort';   ProjectField = 'Effort';    Expected = 'number' }
    [pscustomobject]@{ JsonKey = 'workType'; ProjectField = 'Work Type'; Expected = 'select' }
)

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

    # Una sola invocacion: nunca se reintenta. Se reportan exit code y stderr
    # para no ocultar la causa real (rate limit, red, etc).
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

# Unica via de escritura remota. Solo se invoca dentro del bloque if ($Apply).
function Invoke-GhMutation {
    param([string[]]$Arguments)

    $global:LASTEXITCODE = 0
    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {

        $detail = (($output | ForEach-Object { [string]$_ }) -join ' | ').Trim()

        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = '(stderr vacio)'
        }

        throw "FALLO de mutacion: gh $($Arguments -join ' ') -> exit code $exitCode. Detalle: $detail"
    }

    return $output
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

function Get-PhaseFromWbs {
    param([string]$Wbs)

    if ([string]::IsNullOrWhiteSpace($Wbs)) {
        return $null
    }

    if ($Wbs -match '^(P\d+)\.\d+$') {
        return $Matches[1]
    }

    return $null
}

function Get-MilestonePhase {
    param([string]$MilestoneTitle)

    if ([string]::IsNullOrWhiteSpace($MilestoneTitle)) {
        return $null
    }

    if ($MilestoneTitle -match '^(P\d+)\s*-') {
        return $Matches[1]
    }

    return $null
}

function Get-MilestoneTitle {
    param($IssueData)

    # Lectura defensiva: un Issue sin milestone devuelve $null en lugar de
    # lanzar bajo Set-StrictMode. La ausencia se reporta como invariante I8.
    if ($null -eq $IssueData) {
        return $null
    }

    $prop = $IssueData.PSObject.Properties['milestone']

    if ($null -eq $prop -or $null -eq $prop.Value) {
        return $null
    }

    $titleProp = $prop.Value.PSObject.Properties['title']

    if ($null -eq $titleProp) {
        return $null
    }

    return $titleProp.Value
}

function Get-ProjectItemsLive {
    <#
      Lee los items del Project con una consulta GraphQL dirigida.

      No se usa `gh project item-list` porque descarga, para cada item, el
      Issue completo: cuerpo en Markdown, labels, assignees, reacciones y
      metadatos de repositorio. Con 183 items eso son ~2500 puntos de cuota de
      GraphQL por ejecucion, la mayoria throwaway. Aqui solo se piden los
      campos que el sincronizador usa de verdad: numero, titulo, state,
      milestone y los valores de campo del Project.

      La forma devuelta es identica a la de `gh project item-list`, de modo que
      el resto del script no depende de cual de las dos rutas se uso.
    #>
    param(
        [string]$Owner,
        [string]$Repo,
        [int]$Number,
        [int]$PageSize = 100
    )

    $body = @'
repository(owner: $owner, name: $repo) {
  projectV2(number: $number) {
    id
    items(first: __PAGESIZE__, after: $endCursor) {
      totalCount
      pageInfo { hasNextPage endCursor }
      nodes {
        id
        type
        content {
          ... on Issue {
            number
            title
            state
            milestone { title }
          }
        }
        fieldValues(first: 40) {
          nodes {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name
              field { ... on ProjectV2FieldCommon { name } }
            }
            ... on ProjectV2ItemFieldNumberValue {
              number
              field { ... on ProjectV2FieldCommon { name } }
            }
          }
        }
      }
    }
  }
}
'@

    # Primera pagina: sin cursor, y por eso sin declarar la variable (GraphQL
    # rechaza una variable declarada y no usada).
    $firstQuery = 'query P($owner: String!, $repo: String!, $number: Int!) {' +
        ($body.Replace('__PAGESIZE__', [string]$PageSize).Replace(', after: $endCursor', '')) + '}'

    $nextQuery = 'query P($owner: String!, $repo: String!, $number: Int!, $endCursor: String) {' +
        ($body.Replace('__PAGESIZE__', [string]$PageSize)) + '}'

    $items = @()
    $projectId = $null
    $totalCount = 0
    $cursor = ''
    $page = 0

    while ($true) {

        $page++

        $ghArgs = @('api', 'graphql', '-f', "query=$firstQuery", '-F', "owner=$Owner", '-F', "repo=$Repo", '-F', "number=$Number")

        if ($page -gt 1) {
            $ghArgs = @('api', 'graphql', '-f', "query=$nextQuery", '-F', "owner=$Owner", '-F', "repo=$Repo", '-F', "number=$Number", '-f', "endCursor=$cursor")
        }

        $data = Get-GhJson $ghArgs

        if ($null -eq $data.data -or $null -eq $data.data.repository -or $null -eq $data.data.repository.projectV2) {
            throw "La consulta del Project #$Number no devolvio datos."
        }

        $p2 = $data.data.repository.projectV2

        if ($null -eq $projectId) {
            $projectId = [string]$p2.id
            $totalCount = [int]$p2.items.totalCount
        }

        # Normalizar cada item a la misma forma que produce `gh project item-list`.
        foreach ($node in @($p2.items.nodes)) {

            $fields = [ordered]@{}

            foreach ($fv in @($node.fieldValues.nodes)) {

                $fieldNameProp = $fv.PSObject.Properties['field']
                if ($null -eq $fieldNameProp -or $null -eq $fieldNameProp.Value) { continue }

                $prop = $fieldNameProp.Value.PSObject.Properties['name']
                if ($null -eq $prop -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) { continue }

                $key = [string]$prop.Value

                if ($null -ne $fv.PSObject.Properties['name']) {
                    $fields[$key] = [string]$fv.name
                }
                elseif ($null -ne $fv.PSObject.Properties['number']) {
                    $fields[$key] = $fv.number
                }
            }

            $content = [pscustomobject]@{
                number    = $null
                title     = $null
                state     = $null
                milestone = $null
            }

            if ($null -ne $node.content) {
                if ($null -ne $node.content.PSObject.Properties['number']) { $content.number = $node.content.number }
                if ($null -ne $node.content.PSObject.Properties['title']) { $content.title = $node.content.title }
                if ($null -ne $node.content.PSObject.Properties['state']) { $content.state = $node.content.state }
                if ($null -ne $node.content.PSObject.Properties['milestone'] -and $null -ne $node.content.milestone) {
                    $content.milestone = [pscustomobject]@{ title = $node.content.milestone.title }
                }
            }

            $row = [pscustomobject]@{
                id      = [string]$node.id
                type    = [string]$node.type
                content = $content

                # `gh project item-list` expone tambien el titulo en primer
                # nivel. Se replica para no cambiar el resto del script.
                title   = $content.title
            }

            # Adjuntar cada valor de campo con su nombre exacto del Project.
            foreach ($k in @($fields.Keys)) {
                $row | Add-Member -NotePropertyName $k -NotePropertyValue $fields[$k]
            }

            $items += $row
        }

        $pageInfo = $p2.items.pageInfo

        if (-not $pageInfo.hasNextPage) { break }

        $cursor = [string]$pageInfo.endCursor

        if ([string]::IsNullOrWhiteSpace($cursor)) {
            throw "GitHub indico hasNextPage pero devolvio un endCursor vacio."
        }
    }

    return [pscustomobject]@{
        Id         = $projectId
        TotalCount = $totalCount
        Items      = $items
    }
}

function Test-ValueEmpty {
    param($Value)

    if ($null -eq $Value) {
        return $true
    }

    return [string]::IsNullOrWhiteSpace([string]$Value)
}

function Test-IsNumeric {
    param($Value)

    if ($null -eq $Value) {
        return $false
    }

    return ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int] -or
            $Value -is [long] -or $Value -is [single] -or $Value -is [double] -or
            $Value -is [decimal])
}

function ConvertTo-Double {
    <#
      Convierte a [double] usando SIEMPRE InvariantCulture.

      No usar [double]::Parse / TryParse sin proveedor: con una cultura cuyo
      separador decimal es la coma, es-CO o es-ES entre otras, el punto se
      interpreta como separador de miles y '2.5' se convierte en 25. Eso
      produjo 183 falsos DRIFT en Effort. Toda conversion numerica de este
      script pasa por aqui.
    #>
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if (Test-IsNumeric $Value) {
        return [double]$Value
    }

    $text = ([string]$Value).Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    $parsed = [double]0.0

    $styles = [System.Globalization.NumberStyles]::Float
    $invariant = [System.Globalization.CultureInfo]::InvariantCulture

    if ([double]::TryParse($text, $styles, $invariant, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Format-InvariantNumber {
    param($Value)

    $number = ConvertTo-Double $Value

    if ($null -eq $number) {
        return [string]$Value
    }

    return $number.ToString('0.############', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-FieldText {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if (Test-IsNumeric $Value) {
        return Format-InvariantNumber $Value
    }

    return ([string]$Value).Trim()
}

function Test-ValueEqual {
    param($Actual, $Expected)

    if (Test-ValueEmpty $Actual) {
        return $false
    }

    # Comparacion numerica cuando el declarado es numerico (Effort).
    if (Test-IsNumeric $Expected) {
        $a = ConvertTo-Double $Actual
        $e = ConvertTo-Double $Expected

        if ($null -eq $a -or $null -eq $e) {
            return $false
        }

        # Tolerancia para absorbing el error de punto flotante binario.
        return ([math]::Abs($a - $e) -lt 0.0000001)
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

function Get-JsonValue {
    param($Row, [string]$Key)

    $prop = $Row.PSObject.Properties[$Key]

    if ($null -eq $prop) {
        return $null
    }

    return $prop.Value
}

# ============================================================
# MODO
# ============================================================

if ($Export -and $Apply) {
    Write-Host "ERROR: -Export y -Apply son mutuamente excluyentes." -ForegroundColor Red
    exit 2
}

Write-Section "MODO"

if ($Export) {
    Write-Host "EXPORT: GitHub vivo -> JSON local. GitHub NO sera modificado." -ForegroundColor Yellow
}
elseif ($Apply) {
    Write-Host "APPLY: se modificara el Project #$ProjectNumber (solo campos MISSING)." -ForegroundColor Yellow
}
else {
    Write-Host "DIFF: solo lectura. GitHub NO sera modificado. Usa -Export o -Apply." -ForegroundColor Green
}

# ============================================================
# PREFLIGHT
# ============================================================

Write-Section "PREFLIGHT"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh CLI no esta disponible en el PATH." -ForegroundColor Red
    exit 2
}

Write-Host "gh            : $((& gh --version | Select-Object -First 1))"
Write-Host "Repo          : $RepoFull"
Write-Host "Project       : #$ProjectNumber (owner $Owner)"

# La autenticacion se valida de forma implicita: si el token faltara o fuera
# invalido, la primera consulta fallaria y abortaria el script.

# El node ID del Project, que `project item-edit` necesita, llega en la misma
# lectura dirigida de items. No hace falta una consulta adicional.

# Resolver campos y opciones desde el Project vivo. Ningun ID hardcodeado.
$fieldList = Get-GhJson @('project', 'field-list', "$ProjectNumber", '--owner', $Owner, '--format', 'json')

$fieldByName = @{}
$fieldOptions = @{}

foreach ($field in $fieldList.fields) {
    $fieldByName[[string]$field.name] = $field

    $map = @{}

    # Solo los campos select exponen 'options'. Bajo Set-StrictMode, preguntar
    # directamente por $field.options en un campo numerico es un error fatal.
    $optionsProp = $field.PSObject.Properties['options']

    if ($null -ne $optionsProp -and $null -ne $optionsProp.Value) {
        foreach ($opt in $optionsProp.Value) {
            $map[[string]$opt.name] = [string]$opt.id
        }
    }
    $fieldOptions[[string]$field.name] = $map
}

# El tipo del campo se deduce de la API viva, no se codifica.
$fieldKind = @{}

foreach ($spec in $ManagedFields) {

    if (-not $fieldByName.ContainsKey($spec.ProjectField)) {
        Write-Host "El Project #$ProjectNumber no expone el campo '$($spec.ProjectField)'." -ForegroundColor Red
        exit 2
    }

    $live = $fieldByName[$spec.ProjectField]
    $type = [string]$live.type

    if ($type -eq 'ProjectV2SingleSelectField') {
        $actual = 'select'
    }
    elseif ($type -eq 'ProjectV2Field') {
        $actual = 'number'
    }
    else {
        Write-Host "Tipo inesperado para '$($spec.ProjectField)': $type" -ForegroundColor Red
        exit 2
    }

    if ($actual -ne $spec.Expected) {
        Write-Host "El campo '$($spec.ProjectField)' es de tipo '$type' ($actual) y se esperaba '$($spec.Expected)'. No se escribe sobre un campo cuyo tipo cambio." -ForegroundColor Red
        exit 2
    }

    $fieldKind[$spec.JsonKey] = $actual
}

$kindDesc = ($ManagedFields | ForEach-Object { "$($_.ProjectField)=$($fieldKind[$_.JsonKey])" }) -join ', '
Write-Host "Campos        : $kindDesc (tipos verificados)" -ForegroundColor Green

# ============================================================
# ESTADO VIVO
# ============================================================

Write-Section "ESTADO VIVO"

$projectLive = Get-ProjectItemsLive -Owner $Owner -Repo $Repo -Number $ProjectNumber
$liveItems = @($projectLive.Items)
$projectNodeIdLive = [string]$projectLive.Id

# Issues via REST: state, title y milestone. Bucket de rate limit independiente.
$issueList = @(Get-GhJson @('api', "repos/$RepoFull/issues", '--paginate', '-f', 'state=all', '-f', 'per_page=100', '-X', 'GET') |
    Where-Object { -not $_.PSObject.Properties['pull_request'] })

$issueByNumber = @{}

# OJO: la variable del bucle se llama $issueRow y no $issue a proposito.
# PowerShell no distingue mayusculas, asi que un $issue aqui colisionaria con
# el parametro [int[]]$Issue e intentaria castear cada Issue a Int32[].
foreach ($issueRow in $issueList) {
    $issueByNumber[[int]$issueRow.number] = $issueRow
}

Write-Host ("Items en Project #{0} : {1}" -f $ProjectNumber, $liveItems.Count)
Write-Host ("Issues en {0} : {1}" -f $RepoFull, $issueList.Count)

# Indice de items vivos por numero de Issue.
$liveByNumber = @{}
$liveDuplicateNumbers = @()

foreach ($item in $liveItems) {

    if ($null -eq $item.content -or $null -eq $item.content.number) {
        Write-Host "El Project #$ProjectNumber contiene un item sin numero de Issue." -ForegroundColor Red
        exit 2
    }

    $num = [int]$item.content.number

    if ($liveByNumber.ContainsKey($num)) {
        $liveDuplicateNumbers += $num
    }
    else {
        $liveByNumber[$num] = $item
    }
}

# Indice de WBS vivos. El WBS NO es identidad: solo se usa para validar.
$liveWbsMap = @{}
$liveWbsDuplicates = @()
$liveNoWbs = @()

foreach ($item in $liveItems) {

    $wbs = Get-WbsFromTitle ([string]$item.title)

    if ($null -eq $wbs) {
        $liveNoWbs += [int]$item.content.number
        continue
    }

    if ($liveWbsMap.ContainsKey($wbs)) {
        $liveWbsDuplicates += $wbs
    }
    else {
        $liveWbsMap[$wbs] = $item
    }
}

# ============================================================
# EXPORT
# ============================================================

if ($Export) {

    Write-Section "EXPORT (GitHub vivo -> JSON)"

    # Invariantes del lado Project. Una violacion impide generar el archivo:
    # un export de estado inconsistente propagaria el defecto.
    $exportFailures = @()

    # I2: issue unico en el Project.
    foreach ($dup in ($liveDuplicateNumbers | Sort-Object -Unique)) {
        $exportFailures += "Issue #$dup aparece mas de una vez en el Project #$ProjectNumber."
    }

    # I3: WBS unico dentro del Project.
    foreach ($dup in ($liveWbsDuplicates | Sort-Object -Unique)) {
        $exportFailures += "WBS '$dup' esta duplicado en el Project #$ProjectNumber."
    }

    # I4 / I7: WBS valido y Phase vivo coherente con el prefijo del WBS.
    foreach ($item in $liveItems) {

        $num = [int]$item.content.number
        $wbs = Get-WbsFromTitle ([string]$item.title)

        if ($null -eq $wbs) {
            $exportFailures += "#$num no tiene un WBS valido en el titulo: '$($item.title)'."
            continue
        }

        $wbsPhase = Get-PhaseFromWbs $wbs
        $livePhase = [string](Get-ItemValue $item 'phase')

        if ([string]::IsNullOrWhiteSpace($livePhase)) {
            $exportFailures += "#$num tiene Phase vacio; no se puede exportar."
            continue
        }

        if ($livePhase -ne $wbsPhase) {
            $exportFailures += "#$num tiene Phase '$livePhase' pero su WBS '$wbs' implica '$wbsPhase'."
        }
    }

    # I8 / I9: milestone vivo existe y su prefijo coincide con Phase.
    foreach ($item in $liveItems) {

        $num = [int]$item.content.number

        if (-not $issueByNumber.ContainsKey($num)) {
            $exportFailures += "#$num esta en el Project pero no existe como Issue en $RepoFull."
            continue
        }

        $milestoneTitle = [string](Get-MilestoneTitle $issueByNumber[$num])

        if ([string]::IsNullOrWhiteSpace($milestoneTitle)) {
            $exportFailures += "#$num no tiene milestone asignado."
            continue
        }

        $msPhase = Get-MilestonePhase $milestoneTitle
        $livePhase = [string](Get-ItemValue $item 'phase')

        if ($msPhase -ne $livePhase) {
            $exportFailures += "#$num tiene Phase '$livePhase' pero milestone '$milestoneTitle' (prefijo '$msPhase')."
        }
    }

    if ($exportFailures.Count -gt 0) {
        Write-Host ""
        Write-Host "EXPORT ABORTADO: invariantes del Project violados. No se escribio el JSON." -ForegroundColor Red
        foreach ($failure in $exportFailures) {
            Write-Host "  $failure" -ForegroundColor Red
        }
        exit 2
    }

    Write-Host "Invariantes del Project: correctos" -ForegroundColor Green

    # Construir una entrada por item, en orden determinista por numero de Issue.
    $rows = @()

    foreach ($item in ($liveItems | Sort-Object { [int]$_.content.number })) {

        $num = [int]$item.content.number
        $liveTitle = [string]$item.title
        $wbs = Get-WbsFromTitle $liveTitle
        $wbsPhase = Get-PhaseFromWbs $wbs
        $effortValue = Get-ItemValue $item 'effort'

        # 'title' y 'wbs' son redundantes a proposito: 'wbs' es la identidad
        # que el script valida, y 'title' es el texto vivo completo que una
        # persona revisa. Si el titulo se renumera y el WBS se queda atras,
        # ambos se ven al leer el JSON.
        $rows += [pscustomobject][ordered]@{
            issue    = $num
            wbs      = $wbs
            title    = $liveTitle
            phase    = $wbsPhase
            status   = [string](Get-ItemValue $item 'status')
            priority = [string](Get-ItemValue $item 'priority')
            effort   = (ConvertTo-Double $effortValue)
            workType = [string](Get-ItemValue $item 'work Type')
        }
    }

    $doc = [pscustomobject][ordered]@{
        meta = [pscustomobject][ordered]@{
            schemaVersion = $ExpectedSchemaVersion
            repository    = $RepoFull
            projectNumber = $ProjectNumber
            source        = 'github-live-export'
            generatedAt   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
            keyedBy       = 'issue'
        }
        items = $rows
    }

    $json = ($doc | ConvertTo-Json -Depth 5)

    # ConvertTo-Json usa CRLF en Windows. Se normaliza a LF para que el archivo
    # sea byte-identico independientemente de la plataforma que lo regenera.
    $json = $json -replace "`r`n", "`n"

    # UTF-8 sin BOM, salto de linea final, sobreescritura explicita.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($BacklogPath, ($json + "`n"), $utf8NoBom)

    Write-Host ""
    Write-Host "Escrito  : $BacklogPath" -ForegroundColor Green
    Write-Host "Entradas : $($rows.Count)" -ForegroundColor Green
    Write-Host "GitHub NO fue modificado." -ForegroundColor Green
    exit 0
}

# ============================================================
# CARGAR Y VALIDAR LA FUENTE DECLARATIVA
# ============================================================

Write-Section "FUENTE DECLARATIVA"

if (-not (Test-Path $BacklogPath)) {
    Write-Host "No existe $BacklogPath. Generalo con: .\project_sync.ps1 -Export" -ForegroundColor Red
    exit 2
}

$doc = Get-Content $BacklogPath -Raw -Encoding UTF8 | ConvertFrom-Json

# --- Invariantes de identidad del documento ---

$hardFailures = @()

$meta = $doc.PSObject.Properties['meta']

if ($null -eq $meta -or $null -eq $meta.Value) {
    Write-Host "El JSON no tiene bloque 'meta'." -ForegroundColor Red
    exit 2
}

$metaObj = $meta.Value

# I12
if ([int]$metaObj.schemaVersion -ne $ExpectedSchemaVersion) {
    $hardFailures += "meta.schemaVersion es '$($metaObj.schemaVersion)'; se esperaba $ExpectedSchemaVersion."
}

# I13
if ([int]$metaObj.projectNumber -ne $ProjectNumber) {
    $hardFailures += "meta.projectNumber es '$($metaObj.projectNumber)'; se esperaba $ProjectNumber."
}

# I14
if ([string]$metaObj.repository -ne $RepoFull) {
    $hardFailures += "meta.repository es '$($metaObj.repository)'; se esperaba '$RepoFull'."
}

# I15
if ([string]$metaObj.source -ne 'github-live-export') {
    $hardFailures += "meta.source es '$($metaObj.source)'; se esperaba 'github-live-export'. Un JSON que no viene del Project vivo no es fuente de verdad."
}

$declared = @($doc.items)

if ($declared.Count -eq 0) {
    $hardFailures += "El JSON no declara ningun item."
}

# I1: issue unico en el JSON.
$seenNumbers = @{}
$jsonDuplicateNumbers = @()

foreach ($row in $declared) {

    $num = [int]$row.issue

    if ($seenNumbers.ContainsKey($num)) {
        $jsonDuplicateNumbers += $num
    }
    else {
        $seenNumbers[$num] = $row
    }
}

foreach ($dup in ($jsonDuplicateNumbers | Sort-Object -Unique)) {
    $hardFailures += "El JSON declara el Issue #$dup mas de una vez."
}

Write-Host ("Declarado en JSON : {0} entradas" -f $declared.Count)

if ($hardFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "ABORTADO: la fuente declarativa no es valida. Cero mutaciones." -ForegroundColor Red
    foreach ($failure in $hardFailures) {
        Write-Host "  $failure" -ForegroundColor Red
    }
    exit 2
}

Write-Host "meta         : schemaVersion=$($metaObj.schemaVersion) repository=$($metaObj.repository) project=$($metaObj.projectNumber) source=$($metaObj.source) keyedBy=$($metaObj.keyedBy)" -ForegroundColor Green

# ============================================================
# INVARIANTES GLOBALES
#
# Se validan TODOS antes de filtrar. Un filtro de presentacion nunca
# desactiva una comprobacion de integridad.
# ============================================================

Write-Section "INVARIANTES"

$invariantFailures = @()

# I2
foreach ($dup in ($liveDuplicateNumbers | Sort-Object -Unique)) {
    $invariantFailures += "I2  Issue #$dup esta repetido en el Project #$ProjectNumber."
}

# I3
foreach ($dup in ($liveWbsDuplicates | Sort-Object -Unique)) {
    $invariantFailures += "I3  WBS '$dup' esta duplicado en el Project."
}

# I4 / I5 / I6 / I10 / I11 por entrada declarada
foreach ($row in $declared) {

    $num = [int]$row.issue

    # I10
    if (-not $issueByNumber.ContainsKey($num)) {
        $invariantFailures += "I10 El Issue #$num declarado no existe en $RepoFull."
        continue
    }

    # I11
    if (-not $liveByNumber.ContainsKey($num)) {
        $invariantFailures += "I11 El Issue #$num declarado no pertenece al Project #$ProjectNumber."
        continue
    }

    $item = $liveByNumber[$num]
    $liveTitle = [string]$item.title
    $liveWbs = Get-WbsFromTitle $liveTitle
    $storedWbs = [string]$row.wbs

    # I4
    if ($null -eq $liveWbs) {
        $invariantFailures += "I4  El Issue #$num no tiene WBS valido en su titulo."
        continue
    }

    # I5
    if ($storedWbs -ne $liveWbs) {
        $invariantFailures += "I5  #$num declara WBS '$storedWbs' pero el titulo vivo da '$liveWbs'."
    }

    # I16: el title guardado debe ser coherente con el WBS guardado.
    #
    # 'title' es metadata de revision, no un campo que el sync administre: un
    # Issue renombrado en GitHub no es DRIFT y nunca se reescribe. Lo que si se
    # comprueba es la coherencia interna del archivo, para que 'wbs' y 'title'
    # no se contradigan ante quien lo lea. Si el titulo vivo cambia de WBS, eso
    # ya lo detectan I5 e I7.
    $storedTitle = [string]$row.title

    if ([string]::IsNullOrWhiteSpace($storedTitle)) {
        $invariantFailures += "I16 #$num no guarda 'title', que es la metadata con la que se revisa el WBS."
    }
    elseif (-not $storedTitle.StartsWith($storedWbs)) {
        $invariantFailures += "I16 #$num guarda WBS '$storedWbs' pero su 'title' no empieza por ese WBS."
    }

    # I6
    $wbsPhase = Get-PhaseFromWbs $storedWbs
    $storedPhase = [string]$row.phase

    if ($storedPhase -ne $wbsPhase) {
        $invariantFailures += "I6  #$num declara phase '$storedPhase' pero su WBS '$storedWbs' implica '$wbsPhase'."
    }

    # I7
    $livePhase = [string](Get-ItemValue $item 'phase')

    if ($livePhase -ne $wbsPhase) {
        $invariantFailures += "I7  #$num tiene Phase vivo '$livePhase' pero su WBS '$liveWbs' implica '$wbsPhase'."
    }

    # I8
    $milestoneTitle = [string](Get-MilestoneTitle $issueByNumber[$num])

    if ([string]::IsNullOrWhiteSpace($milestoneTitle)) {
        $invariantFailures += "I8  #$num no tiene milestone asignado."
        continue
    }

    # I9
    $msPhase = Get-MilestonePhase $milestoneTitle

    if ($msPhase -ne $livePhase) {
        $invariantFailures += "I9  #$num tiene Phase '$livePhase' pero milestone '$milestoneTitle' (prefijo '$msPhase')."
    }
}

if ($invariantFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "ABORTADO: invariantes rotos. Cero mutaciones." -ForegroundColor Red
    foreach ($failure in $invariantFailures) {
        Write-Host "  $failure" -ForegroundColor Red
    }
    exit 2
}

Write-Host "I1-I16: correctos" -ForegroundColor Green

# ============================================================
# CLASIFICACION
# ============================================================

Write-Section "DIFERENCIAS"

$diffRows = @()

# Dos niveles de conteo. El de item es el que decide: un item se clasifica con
# la severidad mas alta entre sus campos. El de campo sirve para el detalle.
$itemCounts = @{ MATCH = 0; MISSING = 0; DRIFT = 0; CONFLICT = 0; ORPHAN = 0 }
$fieldCounts = @{ MISSING = 0; DRIFT = 0; CONFLICT = 0 }
$closedBlocked = @()

foreach ($row in $declared) {

    $num = [int]$row.issue

    if (-not $liveByNumber.ContainsKey($num) -or -not $issueByNumber.ContainsKey($num)) {
        $itemCounts.ORPHAN++
        $diffRows += [pscustomobject]@{
            Issue = $num; Wbs = [string]$row.wbs; Field = '-'
            Live = '(ausente)'; Want = [string]$row.status; Class = 'ORPHAN'
            Closed = $false; FieldId = $null
        }
        continue
    }

    $item = $liveByNumber[$num]
    $issueState = [string]$issueByNumber[$num].state
    $isClosed = ($issueState -eq 'closed')
    $itemChanged = $false
    $itemSeverity = 'MATCH'

    foreach ($spec in $ManagedFields) {

        $kind = $fieldKind[$spec.JsonKey]
        $projectField = $spec.ProjectField
        $liveValue = Get-ItemValue $item $projectField
        $wantValue = Get-JsonValue $row $spec.JsonKey

        $class = $null
        $liveText = $null
        $wantText = $null
        $fieldId = $null

        # CONFLICT: valor declarado fuera de la taxonomia viva del campo.
        if (-not (Test-ValueEmpty $wantValue)) {

            if ($kind -eq 'select') {
                $valid = $fieldOptions[$projectField].ContainsKey([string]$wantValue)
            }
            else {
                # Numerico: cualquier valor no parseable es un CONFLICT.
                $valid = ($null -ne (ConvertTo-Double $wantValue))
            }

            if (-not $valid) {
                $class = 'CONFLICT'
                $wantText = Format-FieldText $wantValue
                $liveText = Format-FieldText $liveValue
            }
        }

        if ($null -eq $class) {

            if (Test-ValueEmpty $liveValue) {
                if (Test-ValueEmpty $wantValue) {
                    $class = 'MATCH'
                }
                else {
                    $class = 'MISSING'
                    $wantText = Format-FieldText $wantValue
                }
            }
            elseif (Test-ValueEqual $liveValue $wantValue) {
                $class = 'MATCH'
            }
            else {
                $class = 'DRIFT'
                $liveText = Format-FieldText $liveValue
                $wantText = Format-FieldText $wantValue
            }
        }

        if ($class -ne 'MATCH') {
            $fieldCounts[$class]++
            $itemChanged = $true

            # El item hereda la clase mas severa que aparezca en sus campos.
            $severity = @{ MISSING = 1; DRIFT = 2; CONFLICT = 3 }
            if ($severity[$class] -gt $severity[$itemSeverity]) {
                $itemSeverity = $class
            }

            $fieldId = $null
            if ($class -eq 'MISSING') {
                $fieldId = [string]$fieldByName[$projectField].id
            }

            $diffRows += [pscustomobject]@{
                Issue   = $num
                Wbs     = [string]$row.wbs
                Field   = $projectField
                Live    = $liveText
                Want    = $wantText
                Class   = $class
                Closed  = $isClosed
                FieldId = $fieldId
                Option  = $null
                Kind    = $kind
                JsonKey = $spec.JsonKey
            }
        }
    }

    $itemCounts[$itemSeverity]++

    if ($isClosed -and $itemChanged) {
        $closedBlocked += $num
    }
}

# Cobertura: items del Project ausentes del JSON (I8 de cobertura, seccion 8).
$declaredNumbers = @{}
foreach ($row in $declared) { $declaredNumbers[[int]$row.issue] = $true }

$projectOnly = @()

foreach ($item in $liveItems) {
    $num = [int]$item.content.number
    if (-not $declaredNumbers.ContainsKey($num)) {
        $projectOnly += $num
    }
}

# Resolver la opcion destino solo para lo que realmente se va a escribir.
foreach ($d in $diffRows) {
    if ($d.Class -eq 'MISSING') {
        $projectField = $d.Field
        $d.Option = $fieldOptions[$projectField][[string]$d.Want]
    }
}

# --- Filtrado (solo presentacion y plan; los gates ya se ejecutaron) ---

$phaseFilter = @()
foreach ($p in $Phase) { $phaseFilter += ([string]$p).ToUpperInvariant() }

$selected = @($declared)

if ($phaseFilter.Count -gt 0) {
    $selected = @($selected | Where-Object { $phaseFilter -contains ([string]$_.phase).ToUpperInvariant() })
}

if ($null -ne $Issue -and @($Issue).Count -gt 0) {
    $selected = @($selected | Where-Object { @($Issue) -contains [int]$_.issue })
}

$selectedNumbers = @{}
foreach ($row in $selected) { $selectedNumbers[[int]$row.issue] = $true }

$inScope = @($diffRows | Where-Object { $selectedNumbers.ContainsKey($_.Issue) })

$filterDesc = @()
if ($phaseFilter.Count -gt 0) { $filterDesc += "Phase=$($phaseFilter -join ',')" }
if ($null -ne $Issue -and @($Issue).Count -gt 0) { $filterDesc += "Issue=$(@($Issue) -join ',')" }

if ($filterDesc.Count -gt 0) {
    Write-Host ("Filtro        : {0}" -f ($filterDesc -join ' '))
    Write-Host ("En alcance    : {0} de {1} entradas declaradas (gates globales ya ejecutados)" -f $selected.Count, $declared.Count)
}

Write-Host ""
Write-Host ("Items         : MATCH={0} MISSING={1} DRIFT={2} CONFLICT={3} ORPHAN={4}" -f `
    $itemCounts.MATCH, $itemCounts.MISSING, $itemCounts.DRIFT, $itemCounts.CONFLICT, $itemCounts.ORPHAN)
Write-Host ("Campos        : MISSING={0} DRIFT={1} CONFLICT={2}" -f `
    $fieldCounts.MISSING, $fieldCounts.DRIFT, $fieldCounts.CONFLICT)
Write-Host ("Total declarado: {0}" -f $declared.Count)

if ($inScope.Count -gt 0) {
    Write-Host ""
    Write-Host ("{0,-6} {1,-7} {2,-10} {3,-12} {4,-12} {5}" -f 'ISSUE', 'WBS', 'CAMPO', 'VIVO', 'DECLARADO', 'CLASE')

    foreach ($d in $inScope) {
        $color = 'Yellow'
        if ($d.Class -eq 'DRIFT') { $color = 'Red' }
        if ($d.Class -eq 'CONFLICT') { $color = 'Red' }
        if ($d.Class -eq 'ORPHAN') { $color = 'Red' }
        if ($d.Closed) { $color = 'Magenta' }

        Write-Host ("{0,-6} {1,-7} {2,-10} {3,-12} {4,-12} {5}{6}" -f `
            ("#$($d.Issue)"), $d.Wbs, $d.Field, `
            $(if ($null -eq $d.Live) { '(vacio)' } else { $d.Live }), `
            $(if ($null -eq $d.Want) { '(vacio)' } else { $d.Want }), `
            $d.Class, `
            $(if ($d.Closed) { '  [CLOSED]' } else { '' })) -ForegroundColor $color
    }
}
else {
    Write-Host "Sin diferencias en el alcance seleccionado." -ForegroundColor Green
}

# ============================================================
# COBERTURA
# ============================================================

Write-Section "COBERTURA"

Write-Host ("Items en Project      : {0}" -f $liveItems.Count)
Write-Host ("Declarados en el JSON : {0}" -f $declared.Count)

if ($projectOnly.Count -gt 0) {
    Write-Host ""
    Write-Host "Items del Project SIN entrada en el JSON (no se crean ni se anaden):" -ForegroundColor Yellow
    foreach ($num in ($projectOnly | Sort-Object)) {
        $item = $liveByNumber[$num]
        Write-Host ("  #{0,-5} {1}" -f $num, $item.title) -ForegroundColor Yellow
    }
}

# ============================================================
# GATES DE -APPLY
# ============================================================

if ($Apply) {

    Write-Section "GATES DE APLICACION"

    # Un DRIFT nunca se sobrescribe. Un CONFLICT es un valor fuera de
    # taxonomia. Un ORPHAN apunta a algo que no esta en el Project. Un item
    # del Project sin entrada en el JSON deja la declaracion incompleta.
    # Cualquiera de los cuatro detiene la operacion.
    #
    # DRIFT y CONFLICT se cuentan a nivel de CAMPO, no de item. Un item que
    # arrastra a la vez un DRIFT y un CONFLICT se clasifica como CONFLICT por
    # severidad, y contar solo items dejaria el DRIFT sin reportar.
    $blocking = @()

    if ($fieldCounts.DRIFT -gt 0) {
        $blocking += "$($fieldCounts.DRIFT) campo(s) en DRIFT. Un valor vivo distinto del declarado no se sobrescribe automaticamente: revisa y decide."
    }
    if ($fieldCounts.CONFLICT -gt 0) {
        $blocking += "$($fieldCounts.CONFLICT) campo(s) en CONFLICT, con valor fuera de la taxonomia viva del Project."
    }
    if ($itemCounts.ORPHAN -gt 0) {
        $blocking += "$($itemCounts.ORPHAN) entrada(s) ORPHAN declaradas pero ausentes del Project."
    }
    if ($closedBlocked.Count -gt 0) {
        $blocking += "Issue(s) CLOSED con cambios pendientes: $($closedBlocked -join ', '). Un CLOSED no se modifica."
    }

    # Completar campos MISSING es correcto solo si el alcance del JSON es
    # integro. Un item del Project sin entrada declara deja items que nunca
    # se podrian sincronizar, y escribir sobre esa base oculta el agujero:
    # el gate posterior veraria "todo en orden" y no lo reportaria.
    if ($projectOnly.Count -gt 0) {
        $blocking += "$($projectOnly.Count) item(s) del Project sin entrada en el JSON: $(($projectOnly | Sort-Object) -join ', '). La declaracion esta incompleta; declara esos items antes de escribir."
    }

    if ($blocking.Count -gt 0) {
        Write-Host ""
        Write-Host "APPLY ABORTADO antes de la primera mutacion." -ForegroundColor Red
        foreach ($b in $blocking) {
            Write-Host "  $b" -ForegroundColor Red
        }
        exit 1
    }

    $plan = @($inScope | Where-Object { $_.Class -eq 'MISSING' })

    # El node ID lo trajo la lectura dirigida del Project, sin coste extra.
    $projectNodeId = $projectNodeIdLive

    if ([string]::IsNullOrWhiteSpace($projectNodeId)) {
        Write-Host "No se pudo resolver el node ID del Project #$ProjectNumber." -ForegroundColor Red
        exit 2
    }

    Write-Host "Project node  : $projectNodeId" -ForegroundColor Green

    Write-Host "Gates superados. Plan: $($plan.Count) mutacion(es)." -ForegroundColor Green

    if ($plan.Count -eq 0) {
        Write-Host "Nada que completar: no hay campos MISSING en el alcance." -ForegroundColor Green
        Write-Host "GitHub NO fue modificado." -ForegroundColor Green
        exit 0
    }

    Write-Host ""
    Write-Host "PLAN:"
    $i = 0
    foreach ($p in $plan) {
        $i++
        Write-Host ("  [{0,2}] #{1,-5} {2,-10} = {3}" -f $i, $p.Issue, $p.Field, $p.Want)
    }

    # ============================================================
    # APLICAR
    #
    # Unica region del script con capacidad de escritura remota.
    # Todo gate ya se ejecuto; el plan se construyo completo.
    # ============================================================

    Write-Section "APLICANDO"

    $applied = 0

    # A partir de aqui el script puede escribir en GitHub. El trap usa esta
    # bandera para no afirmar "cero mutaciones" si algo falla a medias.
    $script:MutationStarted = $true

    foreach ($p in $plan) {

        $mutationArgs = @(
            'project', 'item-edit',
            '--id', [string]$liveByNumber[[int]$p.Issue].id,
            '--project-id', $projectNodeId,
            '--field-id', $p.FieldId
        )

        if ($p.Kind -eq 'select') {
            $mutationArgs += @('--single-select-option-id', $p.Option)
        }
        else {
            $mutationArgs += @('--number', (Format-InvariantNumber $p.Want))
        }

        $null = Invoke-GhMutation $mutationArgs
        $applied++

        Write-Host ("  #{0,-5} {1,-10} = {2}" -f $p.Issue, $p.Field, $p.Want) -ForegroundColor Green
    }

    # ============================================================
    # VERIFICACION POSTCONDICIONES
    #
    # Una unica relectura viva.
    # ============================================================

    Write-Section "VERIFICACION"

    # Una unica relectura viva para comprobar las postcondiciones.
    $post = Get-ProjectItemsLive -Owner $Owner -Repo $Repo -Number $ProjectNumber
    $postByNumber = @{}

    foreach ($item in @($post.Items)) {
        $postByNumber[[int]$item.content.number] = $item
    }

    $unverified = @()

    foreach ($p in $plan) {
        $item = $postByNumber[[int]$p.Issue]
        $now = [string](Get-ItemValue $item $p.Field)

        if (-not (Test-ValueEqual $now $p.Want)) {
            $unverified += "#$($p.Issue) $($p.Field): se esperaba '$($p.Want)' y se lee '$now'."
        }
    }

    if ($unverified.Count -gt 0) {
        Write-Host ""
        Write-Host "POSTCONDICIONES FALLIDAS:" -ForegroundColor Red
        foreach ($u in $unverified) {
            Write-Host "  $u" -ForegroundColor Red
        }
        exit 1
    }

    Write-Host "$applied mutacion(es) aplicada(s) y verificadas." -ForegroundColor Green
    Write-Host "APPLY COMPLETADO." -ForegroundColor Green
    exit 0
}

# ============================================================
# VEREDICTO (solo lectura)
# ============================================================

Write-Section "VEREDICTO"

$inconsistencies = 0

# Consistencia a nivel de campo, igual que el gate de -Apply: un DRIFT cuenta
# aunque el item se haya clasificado como CONFLICT por severidad.
if ($fieldCounts.DRIFT -gt 0 -or $fieldCounts.CONFLICT -gt 0 -or $itemCounts.ORPHAN -gt 0) {
    $inconsistencies = 1
}
if ($closedBlocked.Count -gt 0) {
    $inconsistencies = 1
}
if ($projectOnly.Count -gt 0) {
    $inconsistencies = 1
}

if ($inconsistencies -eq 1) {
    Write-Host "  Inconsistencias detectadas." -ForegroundColor Yellow
    if ($projectOnly.Count -gt 0) {
        Write-Host "  Cobertura incompleta: $($projectOnly.Count) item(s) del Project sin entrada en el JSON." -ForegroundColor Yellow
    }
    if ($closedBlocked.Count -gt 0) {
        Write-Host "  Issue(s) CLOSED con cambios pendientes (no modificables)." -ForegroundColor Yellow
    }
    Write-Host "  Revisa el detalle arriba. -Apply abortaria." -ForegroundColor Yellow
    exit 1
}

Write-Host "  JSON y Project #5 son consistentes." -ForegroundColor Green
Write-Host "  Nada que escribir."
Write-Host ""
Write-Host "GitHub NO fue modificado." -ForegroundColor Green
exit 0
