# Script de Mantenimiento y Auditoria de Cerebro Digital
# Permite auditar el estado del repositorio y mover automaticamente archivos huerfanos/sueltos en la raiz.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$AuditOnly
)

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
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   MANTENIMIENTO Y AUDITORIA DE CEREBRO DIGITAL          " -ForegroundColor Cyan
Write-Host "   Fecha/Hora: $timestamp                                " -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan

function Get-TargetFolder {
    param([System.IO.FileInfo]$file)

    $name = $file.Name.ToLower()
    $ext = $file.Extension.ToLower()

    # 1. AS400 / IBM i / DB2 / Vulnerabilidades AS400
    if ($name -match 'as400|ibm_i|ibmi|tlmst|qsys|db2|ftp|telnet') {
        return (Join-Path $baseDir "05_AS400_IBM_i\01_Documentos_y_Manuales")
    }

    # 2. CyberArk PAM
    if ($name -match 'cyberark|pam|cpm|pvwa|psm|vault|safe') {
        return (Join-Path $baseDir "01_CyberArk_PAM")
    }

    # 3. MFA Powertech
    if ($name -match 'mfa|powertech|ptcs|ptcslib') {
        return (Join-Path $baseDir "02_MFA_Powertech")
    }

    # 4. CodeChecker
    if ($name -match 'codechecker|fortify|sonar|checkmarx') {
        return (Join-Path $baseDir "03_CodeChecker\02_Documentacion_y_Guias")
    }

    # 5. Cryptgrip Tokenizacion
    if ($name -match 'cryptgrip|tokeniz') {
        return (Join-Path $baseDir "04_Cryptgrip_Tokenizacion")
    }

    # 6. Antivirus StandGuard
    if ($name -match 'standguard|antivirus|virus') {
        return (Join-Path $baseDir "06_Antivirus_StandGuard")
    }

    # 7. Banesconecta
    if ($name -match 'banesconecta|sicpr') {
        return (Join-Path $baseDir "07_Banesconecta\01_Documentacion_y_Perfiles")
    }

    # 8. Core Tarjeta AZ7
    if ($name -match 'az7|tarjeta|contactless|reconprime') {
        return (Join-Path $baseDir "13_Core_Tarjeta_AZ7\Manuales")
    }

    # 9. Capturas Snagit
    if ($ext -in @('.snag', '.snagx', '.png', '.jpg', '.jpeg', '.gif', '.bmp')) {
        return (Join-Path $baseDir "11_Snagit_Capturas\Capturas_Snagx")
    }

    # 10. Plantillas Institucionales / Presentaciones PPTX
    if ($name -match 'plantilla|presentaci|comite' -or $ext -in @('.pptx', '.potx')) {
        return (Join-Path $baseDir "09_Scripts_y_Herramientas\Plantillas")
    }

    # 11. Seguridad / Certificados / VPN Cisco / SSL
    if ($name -match 'vpn|cisco|certificad|ssl|tls|truststore|p12|csr') {
        return (Join-Path $baseDir "08_Certificados_y_Seguridad\Solicitudes_Formularios")
    }

    # 12. Scripts, Proyectos de automatizacion, paquetes zip
    if ($name -match 'script|automatiz|gestion|control|dash' -or $ext -in @('.ps1', '.py', '.sql', '.zip', '.rar', '.7z', '.bat', '.sh')) {
        return (Join-Path $baseDir "09_Scripts_y_Herramientas\Proyectos_Automatizacion")
    }

    # 13. Notas de texto rapido (.txt)
    if ($ext -eq '.txt') {
        return (Join-Path $baseDir "10_Notas_y_Comandos\Notas_Trabajo_Textos")
    }

    # 14. Personal
    if ($name -match 'ari|poliza|seguro|personal|recibo|constancia') {
        return (Join-Path $baseDir "12_Personal\Otros")
    }

    # Destino por defecto
    return (Join-Path $baseDir "10_Notas_y_Comandos\Notas_Trabajo_Textos")
}

# 1. Detectar archivos sueltos en la raiz
$looseFiles = Get-ChildItem -Path $baseDir -File
$movedCount = 0

if ($looseFiles.Count -gt 0) {
    $alertMsg = ("`n[DETECCION] Se encontraron {0} archivos sueltos en la raiz de Cerebro Digital:" -f $looseFiles.Count)
    Write-Warning $alertMsg
    Add-Content -Path $logFile -Value $alertMsg

    foreach ($lf in $looseFiles) {
        $destFolder = Get-TargetFolder -file $lf
        
        if ($AuditOnly) {
            $msg = ("  - [AUDIT-ONLY] {0} -> Sugerido: {1}" -f $lf.Name, $destFolder)
            Write-Host $msg -ForegroundColor Yellow
            Add-Content -Path $logFile -Value $msg
        } else {
            if (-not (Test-Path -Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }
            
            $targetPath = Join-Path $destFolder $lf.Name
            Move-Item -Path $lf.FullName -Destination $targetPath -Force
            $movedCount++
            
            $moveLog = ("  - [MOVIDO] '{0}' => '{1}'" -f $lf.Name, $destFolder)
            Write-Host $moveLog -ForegroundColor Green
            Add-Content -Path $logFile -Value $moveLog
        }
    }

    if (-not $AuditOnly) {
        $finalMoveMsg = ("`n[REORGANIZACION EXITOSA] Se reubicaron {0} archivos huerfanos a sus carpetas maestras.`n" -f $movedCount)
        Write-Host $finalMoveMsg -ForegroundColor Green
        Add-Content -Path $logFile -Value $finalMoveMsg
    }
} else {
    $okMsg = "`n[OK] Estado Optimo: Cero (0) archivos sueltos en la raiz de Cerebro Digital.`n"
    Write-Host $okMsg -ForegroundColor Green
    Add-Content -Path $logFile -Value $okMsg
}

# 2. Resumen de salud y metricas de las 13 carpetas maestras
$masterFolders = Get-ChildItem -Path $baseDir -Directory | Sort-Object Name
$totalFilesAll = 0
$totalSizeAllMB = 0

Write-Host "Inventario de Carpetas Maestras:" -ForegroundColor Cyan
foreach ($folder in $masterFolders) {
    $files = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue
    $totalSizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    $fileCount = $files.Count
    
    $totalFilesAll += $fileCount
    $totalSizeAllMB += $totalSizeMB

    Write-Host ("  [{0}] - {1} archivos ({2} MB)" -f $folder.Name, $fileCount, $totalSizeMB)
}

$summaryLine = ("`nResumen Total: {0} carpetas maestras | {1} archivos totales | {2} MB" -f $masterFolders.Count, $totalFilesAll, $totalSizeAllMB)
Write-Host $summaryLine -ForegroundColor White
Add-Content -Path $logFile -Value $summaryLine
Add-Content -Path $logFile -Value "`n"
