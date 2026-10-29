<#
.SYNOPSIS
    Inicia el servidor y frontend del Dashboard de Control de Gestión y Rendimiento de Equipo.
.DESCRIPTION
    Verifica si el puerto ya está en uso, configura el PATH de Node.js, y levanta el servidor en http://localhost:3000
#>

[CmdletBinding()]
param(
    [int]$Port = 3000,
    [switch]$Restart,
    [switch]$OpenBrowser
)

# Configurar salida UTF8 en consola
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Asegurar Node.js en el PATH
if ($env:Path -notlike "*C:\Program Files\nodejs*") {
    $env:Path = "C:\Program Files\nodejs;" + $env:Path
}

$projectDir = "D:\WKESPEREIRA\D\Scripts\control-gestion"
if (-not (Test-Path $projectDir)) {
    Write-Error "No se encontró el directorio del proyecto en $projectDir"
    exit 1
}

# Verificar si el puerto ya está en uso
$existingConnection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue

if ($existingConnection) {
    if ($Restart) {
        Write-Host "Deteniendo proceso anterior en puerto $Port (PID: $($existingConnection.OwningProcess))..." -ForegroundColor Yellow
        Stop-Process -Id $existingConnection.OwningProcess -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    } else {
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host " ¡El Dashboard ya se encuentra activo y corriendo!          " -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host " URL Local : http://localhost:$Port" -ForegroundColor Cyan
        Write-Host " Proceso   : PID $($existingConnection.OwningProcess)" -ForegroundColor Gray
        Write-Host " Si deseas reiniciarlo, usa: .\start_dashboard.ps1 -Restart" -ForegroundColor DarkGray
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        
        Start-Process "http://localhost:$Port"
        return
    }
}

Set-Location -Path $projectDir

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Iniciando Dashboard de Control de Gestión y Rendimiento     " -ForegroundColor Yellow
Write-Host " Gerencia de Administración de Seguridad - Banesco           " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Directorio: $projectDir" -ForegroundColor Gray
Write-Host " URL Local : http://localhost:$Port" -ForegroundColor Cyan
Write-Host " Presione Ctrl + C para detener el servidor." -ForegroundColor Gray
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

# Abrir navegador automáticamente tras iniciar
if ($OpenBrowser) {
    Start-Job -ScriptBlock {
        param($url)
        Start-Sleep -Seconds 3
        Start-Process $url
    } -ArgumentList "http://localhost:$Port" | Out-Null
}

& npm run dev
