# Script de Auditoria Diaria y Escaneo de Archivos Sueltos en Cerebro Digital
$baseDir = "D:\Cerebro Digital"
$logDir = Join-Path $baseDir "10_Notas_y_Comandos\Notas_Trabajo_Textos"
$logFile = Join-Path $logDir "Daily_Scan_Log.txt"

if (-not (Test-Path -Path $baseDir)) {
    Write-Error "No se encontro el directorio base: $baseDir"
    exit 1
}

if (-not (Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logHeader = "=========================================`n[ESCANEOS DIARIOS DE CEREBRO DIGITAL]`nFecha/Hora: $timestamp`n========================================="

Write-Host $logHeader
Add-Content -Path $logFile -Value $logHeader

$masterFolders = Get-ChildItem -Path $baseDir -Directory | Sort-Object Name
$totalFilesAll = 0
$totalSizeAllMB = 0

foreach ($folder in $masterFolders) {
    $files = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue
    $totalSizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    $fileCount = $files.Count
    
    $totalFilesAll += $fileCount
    $totalSizeAllMB += $totalSizeMB

    $line = ("[{0}] - {1} archivos ({2} MB)" -f $folder.Name, $fileCount, $totalSizeMB)
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

$summaryLine = ("`nResumen Total: {0} carpetas maestras | {1} archivos totales | {2} MB" -f $masterFolders.Count, $totalFilesAll, $totalSizeAllMB)
Write-Host $summaryLine
Add-Content -Path $logFile -Value $summaryLine

$looseFiles = Get-ChildItem -Path $baseDir -File
if ($looseFiles.Count -gt 0) {
    $alertMsg = ("`n[ALERTA] Se encontraron {0} archivos sueltos en la raiz de Cerebro Digital. Iniciando reubicacion automatica..." -f $looseFiles.Count)
    Write-Warning $alertMsg
    Add-Content -Path $logFile -Value $alertMsg
    
    $organizeScript = Join-Path $PSScriptRoot "organize_cerebro.ps1"
    if (Test-Path -Path $organizeScript) {
        & $organizeScript
    } else {
        foreach ($lf in $looseFiles) {
            $fileDetail = ("  - {0} ({1} bytes)" -f $lf.Name, $lf.Length)
            Write-Host $fileDetail -ForegroundColor Yellow
            Add-Content -Path $logFile -Value $fileDetail
        }
    }
} else {
    $cleanMsg = "`n[OK] Excelente: Cero (0) archivos sueltos en la raiz de Cerebro Digital.`n"
    Write-Host $cleanMsg -ForegroundColor Green
    Add-Content -Path $logFile -Value $cleanMsg
}

Add-Content -Path $logFile -Value "`n"
