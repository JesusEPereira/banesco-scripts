<#
.SYNOPSIS
    test_oracle_connection.ps1 - Diagnóstico de conectividad hacia Oracle BD Capital Humano.
.DESCRIPTION
    Verifica la conectividad de red y puerto hacia el servidor de base de datos Oracle
    de Capital Humano de Banesco (sdb8023.intra.banesco.com:1521, SID: rrhh).
.PARAMETER ConfigPath
    Ruta opcional al archivo config.json (Default: ./config.json).
.EXAMPLE
    .\test_oracle_connection.ps1
#>

[CmdletBinding()]
param (
    [string]$ConfigPath = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $ScriptDir "config.json"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  DIAGNÓSTICO DE CONEXIÓN ORACLE (CAPITAL HUMANO - BANESCO)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $ConfigPath)) {
    Write-Error "No se encontró el archivo de configuración en: $ConfigPath"
    exit 1
}

$config = Get-Content -Raw -Path $ConfigPath -Encoding UTF8 | ConvertFrom-Json
$hostName = $config.oracle.host
$port     = $config.oracle.port
$sid      = $config.oracle.sid
$user     = $config.oracle.user

Write-Host "`n1. Parámetros Configurados:" -ForegroundColor Yellow
Write-Host "   - FQDN / Conexión : $($config.oracle.connectionName)"
Write-Host "   - Host Destino    : $hostName"
Write-Host "   - Puerto TCP      : $port"
Write-Host "   - SID de Base     : $sid"
Write-Host "   - Usuario Esquema : $user"

Write-Host "`n2. Probando Conectividad de Red (TCP $port)..." -ForegroundColor Yellow
try {
    $tcp = Test-NetConnection -ComputerName $hostName -Port $port -WarningAction SilentlyContinue
    if ($tcp.TcpTestSucceeded) {
        Write-Host "   [OK] Puerto $port accesible en $hostName ($($tcp.RemoteAddress))" -ForegroundColor Green
    } else {
        Write-Host "   [FALLO] No se pudo abrir conexión TCP al puerto $port en $hostName" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   [ERROR] Error al verificar TCP: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. Estado de Controladores y Accesos:" -ForegroundColor Yellow
Write-Host "   - Conexión física validada correctamente hacia el clúster de Base de Datos." -ForegroundColor Green
Write-Host "   - Cadena de conexión EZCONNECT lista: ${hostName}:${port}/${sid}" -ForegroundColor Gray
Write-Host "`nDiagnóstico completado con éxito.`n" -ForegroundColor Cyan
