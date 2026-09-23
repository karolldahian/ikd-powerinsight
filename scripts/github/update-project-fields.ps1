param([switch]$Apply)

$ErrorActionPreference = "Stop"

$Owner = "karolldahian"
$ProjectNumber = 5
$ProjectId = "PVT_kwHOD4BgZc4Bke8P"

$BacklogPath = Join-Path $PSScriptRoot "ikd-powerinsight-backlog.json"

# ============================================================
# CAMPOS DEL PROJECT #5
# ============================================================

$Field = @{
    Status   = "PVTSSF_lAHOD4BgZc4Bke8PzhjPXs0"
    Priority = "PVTSSF_lAHOD4BgZc4Bke8PzhjPY8I"
    Effort   = "PVTF_lAHOD4BgZc4Bke8PzhjPZI8"
    Phase    = "PVTSSF_lAHOD4BgZc4Bke8PzhjPZ3c"
    WorkType = "PVTSSF_lAHOD4BgZc4Bke8PzhjPZ_A"
}

# ============================================================
# OPCIONES DE LOS CAMPOS
# ============================================================

$Options = @{
    Status = @{
        "Backlog"     = "c67357c0"
        "Ready"       = "07d667d1"
        "In Progress" = "c1361a97"
        "In Review"   = "a1faee3f"
        "Done"        = "0f285eeb"
    }

    Priority = @{
        "Critical" = "744ce6c0"
        "High"     = "d03748f2"
        "Medium"   = "8f428fbd"
        "Low"      = "e56728ba"
    }

    Phase = @{
        "P0"  = "fbd61540"
        "P1"  = "a72a20da"
        "P2"  = "68550269"
        "P3"  = "188a8204"
        "P4"  = "6383cc0a"
        "P5"  = "6e46fc65"
        "P6"  = "302d7c47"
        "P7"  = "25ea62f4"
        "P8"  = "e67471fc"
        "P9"  = "8d53363b"
        "P10" = "8b2465a1"
        "P11" = "7923125d"
        "P12" = "34ed9527"
        "P13" = "18dc7f45"
        "P14" = "c0cd1f7f"
        "P15" = "4ddb6fe3"
        "P16" = "07cbc5f6"
    }

    WorkType = @{
        "Feature"  = "b918df35"
        "Bug"      = "3e5fec0b"
        "Test"     = "be541988"
        "Docs"     = "5b5661d9"
        "Chore"    = "fcd2962d"
        "Research" = "baf89c46"
    }
}

# ============================================================
# FUNCION SEGURA PARA GH
# ============================================================

function Invoke-Gh {
    param([string[]]$Arguments)

    & gh @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI fallo: gh $($Arguments -join ' ')"
    }
}

# ============================================================
# CARGAR BACKLOG
# ============================================================

$Backlog = Get-Content `
    $BacklogPath `
    -Raw `
    -Encoding UTF8 |
    ConvertFrom-Json

# ============================================================
# CARGAR ITEMS DEL PROJECT
# ============================================================

$ProjectJson = gh project item-list $ProjectNumber `
    --owner $Owner `
    --limit 500 `
    --format json

if ($LASTEXITCODE -ne 0) {
    throw "No se pudieron obtener los items del Project."
}

$Project = $ProjectJson | ConvertFrom-Json

# ============================================================
# VALIDAR CANTIDADES
# ============================================================

Write-Host ""
Write-Host "=== VALIDACION ==="
Write-Host "Backlog JSON: $($Backlog.Count)"
Write-Host "Project items: $($Project.items.Count)"

if ($Backlog.Count -ne 161) {
    throw "El backlog JSON no contiene 161 tareas."
}

if ($Project.items.Count -ne 161) {
    throw "El Project no contiene 161 items."
}

# ============================================================
# VALIDAR COINCIDENCIA POR WBS
# Ejemplo:
# P0.1 -> tarjeta que empieza por P0.1
# P1.6 -> tarjeta que empieza por P1.6
# ============================================================

$Missing = @()
$Duplicates = @()

foreach ($Task in $Backlog) {

    $WbsPattern = "^$([regex]::Escape($Task.wbs))(\s|$)"

    $Matches = @(
        $Project.items |
        Where-Object { $_.title -match $WbsPattern }
    )

    if ($Matches.Count -eq 0) {
        $Missing += $Task.wbs
    }

    if ($Matches.Count -gt 1) {
        $Duplicates += $Task.wbs
    }
}

if ($Missing.Count -gt 0) {

    Write-Host ""
    Write-Host "=== WBS NO ENCONTRADOS ==="

    $Missing | ForEach-Object {
        Write-Host $_
    }

    throw "Hay tareas del JSON que no existen en el Project."
}

if ($Duplicates.Count -gt 0) {

    Write-Host ""
    Write-Host "=== WBS DUPLICADOS ==="

    $Duplicates | ForEach-Object {
        Write-Host $_
    }

    throw "Hay codigos WBS duplicados en el Project."
}

Write-Host "Coincidencia: 161/161"
Write-Host ""

# ============================================================
# DRY RUN
# No modifica GitHub
# ============================================================

if (-not $Apply) {

    Write-Host "=== DRY RUN ==="
    Write-Host "GitHub NO sera modificado."
    Write-Host ""

    foreach ($Task in $Backlog) {

        $Status = $Task.status

        # P0.1 sera nuestra siguiente tarea.
        if ($Task.wbs -eq "P0.1") {
            $Status = "Ready"
        }

        Write-Host (
            "{0,-6} | {1,-12} | {2,-8} | Effort {3} | {4,-4} | {5}" -f `
            $Task.wbs,
            $Status,
            $Task.priority,
            $Task.effort,
            $Task.phase,
            $Task.workType
        )
    }

    Write-Host ""
    Write-Host "=== DRY RUN TERMINADO ==="
    Write-Host "No se modifico GitHub."

    exit
}

# ============================================================
# APLICAR CAMBIOS
# ============================================================

Write-Host ""
Write-Host "=== ACTUALIZANDO PROJECT #5 ==="
Write-Host ""

foreach ($Task in $Backlog) {

    $WbsPattern = "^$([regex]::Escape($Task.wbs))(\s|$)"

    $Item = $Project.items |
        Where-Object { $_.title -match $WbsPattern } |
        Select-Object -First 1

    $Status = $Task.status

    # P0.1 queda lista para comenzar.
    if ($Task.wbs -eq "P0.1") {
        $Status = "Ready"
    }

    Write-Host (
        "[{0}] {1} | {2} | Effort {3} | {4} | {5}" -f `
        $Task.wbs,
        $Status,
        $Task.priority,
        $Task.effort,
        $Task.phase,
        $Task.workType
    )

    # STATUS
    Invoke-Gh @(
        "project", "item-edit",
        "--id", $Item.id,
        "--project-id", $ProjectId,
        "--field-id", $Field.Status,
        "--single-select-option-id", $Options.Status[$Status]
    )

    # PRIORITY
    Invoke-Gh @(
        "project", "item-edit",
        "--id", $Item.id,
        "--project-id", $ProjectId,
        "--field-id", $Field.Priority,
        "--single-select-option-id", $Options.Priority[$Task.priority]
    )

    # EFFORT
    Invoke-Gh @(
        "project", "item-edit",
        "--id", $Item.id,
        "--project-id", $ProjectId,
        "--field-id", $Field.Effort,
        "--number", "$($Task.effort)"
    )

    # PHASE
    Invoke-Gh @(
        "project", "item-edit",
        "--id", $Item.id,
        "--project-id", $ProjectId,
        "--field-id", $Field.Phase,
        "--single-select-option-id", $Options.Phase[$Task.phase]
    )

    # WORK TYPE
    Invoke-Gh @(
        "project", "item-edit",
        "--id", $Item.id,
        "--project-id", $ProjectId,
        "--field-id", $Field.WorkType,
        "--single-select-option-id", $Options.WorkType[$Task.workType]
    )
}

Write-Host ""
Write-Host "=== TERMINADO ==="
Write-Host "161 tareas procesadas."