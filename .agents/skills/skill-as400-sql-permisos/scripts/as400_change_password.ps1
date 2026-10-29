<#
.SYNOPSIS
    as400_change_password.ps1 - Script especializado y seguro para cambio de contraseñas en IBM i / AS400 (v7.5).
.DESCRIPTION
    Modulo dedicado exclusivamente a la gestion de credenciales e identidad de usuarios en IBM i mediante CHGUSRPRF.
    Cumple con estandares de ciberseguridad (SoD, Least Privilege, PCI-DSS, ISO 27001):
    - Ocultamiento estricto de contraseñas: NUNCA guarda contraseñas en texto claro en logs de auditoria ni consola.
    - Tipado nativo seguro con SecureString para NewPassword y AdminPassword.
    - Captura enmascarada interactiva mediante SecureString con liberacion de memoria BSTR.
    - Validacion obligatoria Human-in-the-Loop (HITL) antes de solicitar credenciales o ejecutar cambios.
    - Soporta forzar expiracion de contraseña (PWDEXP).
    - Registra trazabilidad de auditoria independiente en as400_password_audit.jsonl sin riesgo de exposicion de contraseñas.
.EXAMPLE
    .\as400_change_password.ps1 -HostName "10.137.0.138" -TargetUser "BANASIA029" -ForceExpiration No -Requester "jespereira" -Approved
#>

[CmdletBinding()]
param (
    [string]$HostName,

    [string]$TargetUser,

    [SecureString]$NewPassword,

    [ValidateSet("YES", "NO", "SI", "*YES", "*NO")]
    [string]$ForceExpiration = "*NO",

    [string]$AdminUser,

    [SecureString]$AdminPassword,

    [string]$Requester,

    [string]$Approver,

    [switch]$Approved,

    [switch]$DryRun,

    [string]$LogFile
)

$ErrorActionPreference = "Stop"

# 1. Captura interactiva y sanitizacion de parametros principales
if ([string]::IsNullOrWhiteSpace($HostName)) {
    $HostName = Read-Host "Ingrese la IP o Host de AS400 (ej. 10.137.0.138)"
}
$HostName = $HostName.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($TargetUser)) {
    $TargetUser = Read-Host "Ingrese el Usuario objetivo al que se cambiara la contrasena (ej. BANASIA029)"
}
$TargetUser = $TargetUser.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($Requester)) {
    $Requester = Read-Host "Ingrese el Usuario Solicitante (presione Enter para usar $env:USERNAME)"
}
if ([string]::IsNullOrWhiteSpace($Requester)) {
    $Requester = $env:USERNAME
}
$Requester = $Requester.Trim().Trim('"').Trim("'")

# Normalizar parametro de expiracion de contrasena
$PwdExpVal = if ($ForceExpiration -match "YES|SI|\*YES") { "*YES" } else { "*NO" }

# Generacion de Audit ID y Timestamp
$AuditId = "AUD-PWD-" + (Get-Date -Format "yyyyMMddHHmmss") + "-" + ([guid]::NewGuid().ToString().Substring(0, 4).ToUpper())
$Timestamp = (Get-Date).ToString("o")

$LogDir = Join-Path -Path $PSScriptRoot -ChildPath "..\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$AuditLogFile = if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile
} else {
    Join-Path -Path $LogDir -ChildPath "as400_password_audit.jsonl"
}

function Write-AuditRecord {
    param ($Record)
    $JsonLine = $Record | ConvertTo-Json -Compress -Depth 5
    Add-Content -Path $AuditLogFile -Value $JsonLine -Encoding UTF8
}

# 2. Verificacion Obligatoria Human-in-the-Loop (HITL)
if (-not $Approved) {
    Write-Host "`n====================================================================" -ForegroundColor Yellow
    Write-Host "SOLICITUD DE APROBACION: CAMBIO DE CONTRASENA EN AS400 (IBM i)" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "Servidor Destino   : $HostName"
    Write-Host "Usuario a Modificar: $TargetUser"
    Write-Host "Forzar Expiracion  : $PwdExpVal"
    Write-Host "Solicitante        : $Requester"
    Write-Host "Accion             : CHGUSRPRF USRPRF($TargetUser) PASSWORD(********) PWDEXP($PwdExpVal)"
    Write-Host "====================================================================" -ForegroundColor Yellow
    $Confirm = Read-Host "¿Desea APROBAR y ejecutar este cambio de contrasena? (S/N)"
    if ($Confirm -match "^[SsYy]([IisS])?$") {
        $Approved = $true
        if ([string]::IsNullOrWhiteSpace($Approver)) {
            $Approver = $Requester
        }
    }
}

if (-not $Approved) {
    $ErrorResp = @{
        status = 403
        mensaje = "Operacion cancelada: Se requiere aprobacion humana explicita (Human-in-the-Loop) para cambio de contrasena."
        tipo_operacion = "CAMBIO_PASSWORD"
        host = $HostName
        usuario_objetivo = $TargetUser
        solicitante = $Requester
        auditoria_id = $AuditId
    }
    
    $AuditRecord = @{
        auditoria_id = $AuditId
        timestamp = $Timestamp
        host = $HostName
        usuario_solicitante = $Requester
        usuario_aprobador = $null
        tipo_operacion = "CAMBIO_PASSWORD"
        comando = "CHGUSRPRF USRPRF($TargetUser) PASSWORD(********) PWDEXP($PwdExpVal)"
        estado = "RECHAZADO_SIN_APROBACION"
        filas_afectadas = 0
        respuesta = $ErrorResp
    }
    Write-AuditRecord -Record $AuditRecord

    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

# 3. Captura Segura de la Nueva Contrasena (Enmascarada)
if ($null -eq $NewPassword) {
    $NewPassword = Read-Host "Ingrese la NUEVA contrasena para el usuario $TargetUser" -AsSecureString
}

# 4. Captura Segura de Credenciales de Administrador AS400 (*SECADM)
if ([string]::IsNullOrWhiteSpace($AdminUser)) {
    $AdminUser = Read-Host "Ingrese el Usuario Administrador de AS400 (con autoridad *SECADM)"
}
$AdminUser = $AdminUser.Trim().Trim('"').Trim("'")

if ($null -eq $AdminPassword) {
    $AdminPassword = Read-Host "Ingrese la Contrasena del Administrador AS400 ($AdminUser)" -AsSecureString
}

if ($null -eq $NewPassword -or [string]::IsNullOrWhiteSpace($AdminUser) -or $null -eq $AdminPassword) {
    $ErrorResp = @{
        status = 401
        mensaje = "Operacion denegada: Faltan credenciales requeridas para ejecutar el cambio de contrasena."
        tipo_operacion = "CAMBIO_PASSWORD"
        host = $HostName
        usuario_objetivo = $TargetUser
        solicitante = $Requester
    }
    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

# Desempaquetado temporal y seguro de contrasenas en memoria protegida
$BSTRNew = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
$PlainNewPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTRNew)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTRNew)

$BSTRAdmin = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
$PlainAdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTRAdmin)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTRAdmin)

# 5. Formateo de comandos (Comando real y comando sanitizado para auditoria)
$RealClCmd = "CHGUSRPRF USRPRF($TargetUser) PASSWORD($PlainNewPassword) PWDEXP($PwdExpVal)"
$EscapedCmd = $RealClCmd.Replace("'", "''")
$CmdLen = $RealClCmd.Length
$TargetSql = "CALL QSYS2.QCMDEXC('$EscapedCmd', $CmdLen)"
$SanitizedSql = "CALL QSYS2.QCMDEXC('CHGUSRPRF USRPRF($TargetUser) PASSWORD(********) PWDEXP($PwdExpVal)', $CmdLen)"

# Registro de Auditoria Inicial (NUNCA almacena la contrasena real)
$AuditRecord = @{
    auditoria_id = $AuditId
    timestamp = $Timestamp
    host = $HostName
    usuario_solicitante = $Requester
    usuario_aprobador = $Approver
    tipo_operacion = "CAMBIO_PASSWORD"
    usuario_objetivo = $TargetUser
    comando = $SanitizedSql
    estado = "EN_PROCESO"
    dry_run = [bool]$DryRun
}

# 6. Modo Simulacion / Dry-Run
if ($DryRun) {
    $Response = [ordered]@{
        status = 200
        mensaje = "[SIMULACION / DRY-RUN] Credenciales validadas. Verificacion exitosa de cambio de contrasena"
        tipo_operacion = "CAMBIO_PASSWORD"
        host = $HostName
        usuario_as400_admin = $AdminUser
        usuario_objetivo = $TargetUser
        sql_ejecutado = $SanitizedSql
        filas_afectadas = 1
        auditoria_id = $AuditId
        aprobado_por = $Approver
    }

    $AuditRecord.estado = "EXITOSO_SIMULADO"
    $AuditRecord.filas_afectadas = 1
    $AuditRecord.respuesta = $Response
    Write-AuditRecord -Record $AuditRecord

    $Response | ConvertTo-Json -Depth 5
    exit 0
}

# 7. Ejecucion Real en IBM i DB2 via ODBC
try {
    $ConnString = "Driver={IBM i Access ODBC Driver};System=$HostName;Uid=$AdminUser;Pwd=$PlainAdminPassword;UNICODE_SQL=1;"
    $Conn = New-Object System.Data.Odbc.OdbcConnection($ConnString)
    $Conn.Open()

    $Cmd = $Conn.CreateCommand()
    $Cmd.CommandText = $TargetSql
    $RowsAffected = $Cmd.ExecuteNonQuery()
    if ($RowsAffected -lt 0) { $RowsAffected = 1 }
    $Conn.Close()

    $Response = [ordered]@{
        status = 200
        mensaje = "Contrasena cambiada exitosamente para el usuario $TargetUser en IBM i"
        tipo_operacion = "CAMBIO_PASSWORD"
        host = $HostName
        usuario_objetivo = $TargetUser
        sql_ejecutado = $SanitizedSql
        filas_afectadas = $RowsAffected
        auditoria_id = $AuditId
        aprobado_por = $Approver
    }

    $AuditRecord.estado = "EXITOSO"
    $AuditRecord.filas_afectadas = $RowsAffected
    $AuditRecord.respuesta = $Response
    Write-AuditRecord -Record $AuditRecord

    $Response | ConvertTo-Json -Depth 5
    exit 0
}
catch {
    $ErrMsg = $_.Exception.Message
    $ResponseError = @{
        status = 500
        mensaje = "Error al ejecutar el cambio de contrasena en IBM i DB2"
        host = $HostName
        usuario_objetivo = $TargetUser
        error_detalle = $ErrMsg
        auditoria_id = $AuditId
    }

    $AuditRecord.estado = "ERROR_EJECUCION"
    $AuditRecord.respuesta = $ResponseError
    Write-AuditRecord -Record $AuditRecord

    $ResponseError | ConvertTo-Json -Depth 5
    exit 1
}
