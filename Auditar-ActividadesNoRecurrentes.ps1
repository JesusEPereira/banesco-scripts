# ==============================================================================
# Banesco Banco - Gerencia de Administracion de Seguridad
# Script: Auditar-ActividadesNoRecurrentes.ps1
# Proposito: Auditar y totalizar Estatus Banco (Col O) y Responsable por cada
#            hoja del documento de Actividades No Recurrentes.
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$FilePath,

    [Parameter()]
    [string]$ColumnaEstatus = "O",

    [Parameter()]
    [string]$ColumnaResponsable = "J",

    [Parameter()]
    [string]$ExportJsonPath = "D:\WKESPEREIRA\D\Scripts\actividades_resumen.json"
)

# Control de codificación seguro para PowerShell ISE y consola estándar
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {}

# Localizar archivo si no se especificó por parámetro
if (-not $FilePath) {
    $searchDirectories = @(
        $PSScriptRoot,
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "."
    )

    $searchFilters = @(
        "*_Clasificaci*Actividades*.xlsx",
        "*Clasificaci*Actividades*.xlsx",
        "*Actividades*No*Recurrentes*.xlsx",
        "*Actividades*.xlsx"
    )

    foreach ($dir in $searchDirectories) {
        try {
            if (Test-Path -LiteralPath $dir -ErrorAction SilentlyContinue) {
                foreach ($filter in $searchFilters) {
                    $candidates = Get-ChildItem -Path $dir -Filter $filter -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notlike "~$*" } |
                    Sort-Object LastWriteTime -Descending
                    if ($candidates) {
                        $FilePath = ($candidates | Select-Object -First 1).FullName
                        break
                    }
                }
                if ($FilePath) { break }
            }
        }
        catch {}
    }
}

# Si no se encontró en carpetas estándar, abrir cuadro de selección interactivo
if (-not $FilePath -or -not (Test-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue)) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Title = "Seleccione el archivo Excel (.xlsx) de Actividades No Recurrentes"
        $openDialog.Filter = "Libros de Excel (*.xlsx;*.xlsm)|*.xlsx;*.xlsm|Todos los archivos (*.*)|*.*"
        $openDialog.InitialDirectory = "$env:USERPROFILE\Downloads"
        
        if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $FilePath = $openDialog.FileName
        }
    }
    catch {}
}

if (-not $FilePath -or -not (Test-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] No se indico ni se encontro un archivo Excel (.xlsx)."
    Write-Host "[INFO] Uso: .\Auditar-ActividadesNoRecurrentes.ps1 -FilePath 'ruta\al\archivo.xlsx'"
    Write-Host "[INFO] Pasos para descargar desde Google Workspace:"
    Write-Host "       1. Abra la hoja en el navegador."
    Write-Host "       2. Haga clic en: Archivo > Descargar > Microsoft Excel (.xlsx)"
    Write-Host "       3. Vuelva a ejecutar este script o arrastre el archivo a 'dashboard_actividades_no_recurrentes.html'"
    exit 1
}

Write-Host "[INFO] Archivo seleccionado para auditoria: $FilePath"

# Motor Primario: Procesamiento de alto rendimiento mediante SheetJS / Node.js
# Esto evita por completo el error COMException 0x800A03EC causado por hojas de cálculo de Google
$nodeScript = Join-Path $PSScriptRoot "scripts\parse_actividades.cjs"
$nodeExe = (Get-Command "node" -ErrorAction SilentlyContinue)

if ($nodeExe -and (Test-Path -LiteralPath $nodeScript -ErrorAction SilentlyContinue)) {
    & $nodeExe.Source $nodeScript $FilePath $ExportJsonPath
    exit 0
}

# Motor Secundario de Contingencia: Automatización Excel COM
Write-Host "[INFO] Ejecutando motor de contingencia Excel COM..."
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $wb = $excel.Workbooks.Open($FilePath, 0, $true)
    $sheetCount = $wb.Sheets.Count
    Write-Host "[INFO] Se detectaron $sheetCount pestanas en el libro."

    $consolidatedReport = @()
    $totalGlobalAbiertos = 0
    $totalGlobalCerrados = 0
    $totalGlobalItems = 0

    foreach ($sheet in $wb.Sheets) {
        $sheetName = $sheet.Name
        $used = $sheet.UsedRange
        $maxRow = $used.Rows.Count
        $maxCol = $used.Columns.Count

        if ($maxRow -lt 2) { continue }

        $openCount = 0
        $closedCount = 0
        $respMap = @{}

        for ($r = 2; $r -le $maxRow; $r++) {
            $respText = ($sheet.Cells.Item($r, 10).Text).Trim()
            $statusText = ($sheet.Cells.Item($r, 15).Text).Trim()

            if (-not $respText -and -not $statusText) { continue }
            if (-not $respText) { $respText = "Sin Asignar" }

            $isClosed = ($statusText -match "^(?i)(Cerrado|Conforme|Completado|Entregado|Cumple|OK)$")
            if ($isClosed) { $closedCount++ } else { $openCount++ }

            if (-not $respMap.ContainsKey($respText)) {
                $respMap[$respText] = @{ Abiertos = 0; Cerrados = 0; Total = 0 }
            }
            if ($isClosed) { $respMap[$respText].Cerrados++ } else { $respMap[$respText].Abiertos++ }
            $respMap[$respText].Total++
        }

        $sheetTotal = $openCount + $closedCount
        $totalGlobalAbiertos += $openCount
        $totalGlobalCerrados += $closedCount
        $totalGlobalItems += $sheetTotal

        $consolidatedReport += [PSCustomObject]@{
            Pestana           = $sheetName
            TotalAbiertos     = $openCount
            TotalCerrados     = $closedCount
            Total             = $sheetTotal
            PorcentajeCerrado = if ($sheetTotal -gt 0) { [Math]::Round(($closedCount / $sheetTotal) * 100, 2) } else { 0 }
            Responsables      = $respMap
        }
    }

    $wb.Close($false)

    Write-Host "`n================================================================================"
    Write-Host " BANESCO - INFORME CONSOLIDADO (EXCEL COM)"
    Write-Host "================================================================================"
    $globalPct = if ($totalGlobalItems -gt 0) { [Math]::Round(($totalGlobalCerrados / $totalGlobalItems) * 100, 2) } else { 0 }
    Write-Host ("  [TOTAL GENERAL] Items: {0} | Cerrados: {1} | Abiertos: {2} | Avance: {3}%" -f $totalGlobalItems, $totalGlobalCerrados, $totalGlobalAbiertos, $globalPct)
}
finally {
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
