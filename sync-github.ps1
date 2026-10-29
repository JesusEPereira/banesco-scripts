[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================================
# Script de Sincronizacion Diaria con GitHub
# Repositorio Base: https://github.com/JesusEPereira
# Ruta Local: D:\WKESPEREIRA\D\Scripts
# =========================================================================

$repoPath = "D:\WKESPEREIRA\D\Scripts"
$gitExe = "D:\WKESPEREIRA\D\Git\cmd\git.exe"
$logFile = Join-Path $repoPath "sync_log.txt"

function Write-SyncLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Output $line
    Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
}

if (-not (Test-Path $gitExe)) {
    Write-SyncLog "Git no se encuentra instalado en $gitExe" "ERROR"
    exit 1
}

Set-Location -LiteralPath $repoPath

$remotes = & $gitExe remote -v
if (-not $remotes) {
    Write-SyncLog "No hay repositorios remotos configurados. Por favor configure el remoto con: git remote add origin https://github.com/JesusEPereira/<nombre-del-repo>.git" "ALERTA"
    exit 0
}

Write-SyncLog "Iniciando revision de cambios locales..." "INFO"

$status = & $gitExe status --porcelain
if ($status) {
    Write-SyncLog "Se detectaron cambios locales. Agregando archivos al area de preparacion..." "INFO"
    & $gitExe add -A
    
    $commitDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMsg = "Sincronizacion automatica diaria: $commitDate"
    & $gitExe commit -m $commitMsg
    Write-SyncLog "Commit generado: $commitMsg" "OK"
} else {
    Write-SyncLog "No hay cambios locales pendientes para commit." "INFO"
}

# Obtener rama actual
$currentBranch = (& $gitExe branch --show-current).Trim()
if (-not $currentBranch) {
    $currentBranch = "main"
}

Write-SyncLog "Enviando commits a la rama $currentBranch en el remoto..." "INFO"
$pushOutput = & $gitExe push origin $currentBranch 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-SyncLog "Sincronizacion completada con exito hacia https://github.com/JesusEPereira" "OK"
} else {
    Write-SyncLog "Fallo el envio a GitHub. Detalle: $pushOutput" "ERROR"
}

