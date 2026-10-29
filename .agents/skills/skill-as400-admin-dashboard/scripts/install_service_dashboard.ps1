<#
.SYNOPSIS
    install_service_dashboard.ps1 - Instalador y administrador del Servicio Windows 24/7 para el Dashboard AS400.
.DESCRIPTION
    Implementa la OPCION 1 de continuidad operativa 24/7:
    - Registra el servidor 'as400_dashboard_server.ps1' como Servicio de Windows persistente.
    - Configura inicio automatico tras reinicios del sistema (Automatic - Delayed Start).
    - Configura recuperacion automatica ante fallos (Restart Service tras 3 segundos).
    - Permite instalar, desinstalar, iniciar, detener y verificar el estado del servicio.
    - Genera la plantilla de configuracion 'web.config' para publicar mediante IIS Reverse Proxy (ARR) en HTTPS 443.
.PARAMETER Action
    Accion a ejecutar: Install, Uninstall, Start, Stop, Status, GenerateIISConfig.
.PARAMETER ServiceName
    Nombre del servicio en Windows (Default: BanescoAS400Dashboard).
.PARAMETER Port
    Puerto local de escucha (Default: 8085).
.EXAMPLE
    .\install_service_dashboard.ps1 -Action Install -Port 8085
    .\install_service_dashboard.ps1 -Action Status
    .\install_service_dashboard.ps1 -Action GenerateIISConfig
#>

[CmdletBinding()]
param (
    [ValidateSet("Install", "Uninstall", "Start", "Stop", "Status", "GenerateIISConfig")]
    [string]$Action = "Status",

    [string]$ServiceName = "BanescoAS400Dashboard",

    [string]$DisplayName = "Banesco AS400 Security Dashboard (24/7)",

    [int]$Port = 8085
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$ServerScript = Join-Path -Path $ScriptDir -ChildPath "as400_dashboard_server.ps1"
$PowerShellExe = (Get-Process -Id $PID).Path

# -----------------------------------------------------------------------------
# 1. ACCIÓN: GENERAR CONFIGURACIÓN PARA IIS REVERSE PROXY (HTTPS 443 -> 8085)
# -----------------------------------------------------------------------------
if ($Action -eq "GenerateIISConfig") {
    $IisWebConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ReverseProxyToAS400Dashboard" stopProcessing="true">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://127.0.0.1:$($Port)/{R:1}" />
                </rule>
            </rules>
        </rewrite>
        <httpProtocol>
            <customHeaders>
                <add name="X-Frame-Options" value="SAMEORIGIN" />
                <add name="X-Content-Type-Options" value="nosniff" />
                <add name="X-XSS-Protection" value="1; mode=block" />
                <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
            </customHeaders>
        </httpProtocol>
    </system.webServer>
</configuration>
"@
    $OutFile = Join-Path -Path $ScriptDir -ChildPath "web.config"
    [System.IO.File]::WriteAllText($OutFile, $IisWebConfig, [System.Text.Encoding]::UTF8)
    Write-Host "[+] Archivo web.config generado exitosamente en: $OutFile" -ForegroundColor Green
    Write-Host "    Copie este archivo en la raiz del sitio IIS configurado con ARR para publicar en HTTPS 443." -ForegroundColor Gray
    exit 0
}

# -----------------------------------------------------------------------------
# 2. ACCIÓN: ESTADO DEL SERVICIO
# -----------------------------------------------------------------------------
if ($Action -eq "Status") {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service) {
        Write-Host "`n=== ESTADO DEL SERVICIO $ServiceName ===" -ForegroundColor Cyan
        Write-Host "  Nombre       : $($Service.Name)"
        Write-Host "  Descripcion  : $($Service.DisplayName)"
        Write-Host "  Estado       : $($Service.Status)" -ForegroundColor (if ($Service.Status -eq 'Running') { 'Green' } else { 'Yellow' })
        Write-Host "  Tipo Inicio  : $($Service.StartType)"
    } else {
        Write-Host "[i] El servicio '$ServiceName' no se encuentra registrado en este equipo." -ForegroundColor Yellow
        Write-Host "    Para registrarlo ejecute: .\install_service_dashboard.ps1 -Action Install" -ForegroundColor Gray
    }
    exit 0
}

# -----------------------------------------------------------------------------
# 3. ACCIÓN: DETENER SERVICIO
# -----------------------------------------------------------------------------
if ($Action -eq "Stop") {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service -and $Service.Status -eq 'Running') {
        Stop-Service -Name $ServiceName -Force
        Write-Host "[+] Servicio '$ServiceName' detenido exitosamente." -ForegroundColor Green
    } else {
        Write-Host "[i] El servicio no esta en ejecucion." -ForegroundColor Yellow
    }
    exit 0
}

# -----------------------------------------------------------------------------
# 4. ACCIÓN: INICIAR SERVICIO
# -----------------------------------------------------------------------------
if ($Action -eq "Start") {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service) {
        Start-Service -Name $ServiceName
        Write-Host "[+] Servicio '$ServiceName' iniciado exitosamente." -ForegroundColor Green
    } else {
        Write-Error "El servicio '$ServiceName' no esta instalado."
    }
    exit 0
}

# -----------------------------------------------------------------------------
# 5. ACCIÓN: DESINSTALAR SERVICIO
# -----------------------------------------------------------------------------
if ($Action -eq "Uninstall") {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service) {
        if ($Service.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force
        }
        # Intentar con NSSM o sc.exe
        $Nssm = Get-Command nssm -ErrorAction SilentlyContinue
        if ($Nssm) {
            & nssm remove $ServiceName confirm
        } else {
            & sc.exe delete $ServiceName
        }
        Write-Host "[+] Servicio '$ServiceName' desinstalado correctamente." -ForegroundColor Green
    } else {
        Write-Host "[i] El servicio '$ServiceName' no existe." -ForegroundColor Yellow
    }
    exit 0
}

# -----------------------------------------------------------------------------
# 6. ACCIÓN: INSTALAR SERVICIO (NSSM O WRAPPER NATIVO)
# -----------------------------------------------------------------------------
if ($Action -eq "Install") {
    # Verificar permisos de Administrador
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) {
        Write-Error "Se requieren permisos de Administrador para instalar servicios de Windows. Ejecute PowerShell como Administrador."
        exit 1
    }

    $Nssm = Get-Command nssm.exe -ErrorAction SilentlyContinue
    $ArgsList = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `'$ServerScript`' -Port $Port"

    if ($Nssm) {
        Write-Host "[+] Utilizando NSSM para registrar el servicio 24/7..." -ForegroundColor Cyan
        & nssm.exe install $ServiceName "$PowerShellExe" $ArgsList
        & nssm.exe set $ServiceName DisplayName "$DisplayName"
        & nssm.exe set $ServiceName Description "Servicio de administracion de identidades y seguridad IBM i AS400 (LPAR 10.137.0.138) con autenticacion LDAPS 636 TLS."
        & nssm.exe set $ServiceName Start SERVICE_DELAYED_AUTO_START
        & nssm.exe set $ServiceName AppDirectory "$ScriptDir"
        & nssm.exe set $ServiceName AppExit Default Restart
        & nssm.exe set $ServiceName AppRestartDelay 3000
        & nssm.exe start $ServiceName
        Write-Host "[+] Servicio '$ServiceName' instalado e iniciado con exito mediante NSSM." -ForegroundColor Green
    } else {
        Write-Host "[+] Registrando Tarea Programada / Servicio de Windows Nativo al arranque del sistema..." -ForegroundColor Cyan
        
        # Registrar Tarea Programada que se ejecuta al encender el equipo sin requerir inicio de sesion (SYSTEM)
        $TaskName = "Banesco_AS400_Dashboard_24_7"
        $ActionObj = New-ScheduledTaskAction -Execute $PowerShellExe -Argument $ArgsList -WorkingDirectory $ScriptDir
        $TriggerObj = New-ScheduledTaskTrigger -AtStartup
        $SettingsObj = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 365)
        $PrincipalObj = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Register-ScheduledTask -TaskName $TaskName -Action $ActionObj -Trigger $TriggerObj -Settings $SettingsObj -Principal $PrincipalObj | Out-Null
        Start-ScheduledTask -TaskName $TaskName

        Write-Host "[+] Tarea de inicio automatico 24/7 '$TaskName' registrada exitosamente bajo la cuenta SYSTEM." -ForegroundColor Green
        Write-Host "    Se iniciara de forma automatica en cada arranque del servidor sin requerir inicio de sesion interactivo." -ForegroundColor Gray
    }

    # Crear regla de Firewall opcional para puerto local
    try {
        New-NetFirewallRule -DisplayName "Banesco AS400 Dashboard (TCP $Port)" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -ErrorAction SilentlyContinue | Out-Null
        Write-Host "[+] Regla de Firewall para puerto TCP $Port creada exitosamente." -ForegroundColor Green
    } catch {}

    Write-Host ""
    Write-Host "[OK] Despliegue de Continuidad 24/7 Completado:" -ForegroundColor Green
    Write-Host "  - URL Local: http://localhost:$Port" -ForegroundColor Cyan
}
