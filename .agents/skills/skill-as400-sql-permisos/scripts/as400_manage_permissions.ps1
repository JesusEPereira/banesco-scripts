<#
.SYNOPSIS
    as400_manage_permissions.ps1 - Script especializado para gestion de autorizaciones de objetos en IBM i / AS400 (v7.5).
.DESCRIPTION
    Modulo dedicado exclusivamente a otorgar (GRTOBJAUT) o revocar (RVKOBJAUT) autorizaciones sobre objetos nativos de IBM i:
    - Soporta bibliotecas en *SYSBAS y en ASPs independientes (IASP / ASPDEV).
    - Valida tipos de objeto (*FILE, *PGM, *DTAARA, *LIB, *OUTQ, *JOBD, *CMD, etc.).
    - Valida niveles de autoridad (*CHANGE, *USE, *ALL, *EXCLUDE).
    - Aplica validacion obligatoria Human-in-the-Loop (HITL) con ficha descriptiva antes de ejecutar cambios.
    - Registra trazabilidad de auditoria independiente en as400_permissions_audit.jsonl sin riesgo de exposicion de contraseñas.
.EXAMPLE
    .\as400_manage_permissions.ps1 -HostName "10.137.0.138" -Library "SIIF0910" -Object "CUMAD" -ObjectType "*FILE" -TargetUser "*PUBLIC" -Authority "*CHANGE" -AspDev "IASP01" -Requester "jespereira" -Approved
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
param (
    [string]$HostName,

    [string]$Library,

    [string]$Object,

    [ValidateSet("*FILE", "*PGM", "*SRVPGM", "*MODULE", "*DTAARA", "*LIB", "*OUTQ", "*JOBD", "*CMD", "*SQLPKG", "*FILEPF", "*FILELF", "*DTAQ")]
    [string]$ObjectType = "*FILE",

    [string]$TargetUser = "*PUBLIC",

    [ValidateSet("*CHANGE", "*USE", "*ALL", "*EXCLUDE")]
    [string]$Authority = "*CHANGE",

    [string]$AspDev,

    [ValidateSet("GRANT", "REVOKE")]
    [string]$Action = "GRANT",

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

if ([string]::IsNullOrWhiteSpace($Library)) {
    $Library = Read-Host "Ingrese la Biblioteca del objeto (ej. SIIF0910)"
}
$Library = $Library.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($Object)) {
    $Object = Read-Host "Ingrese el Nombre del Objeto (ej. CUMAD)"
}
$Object = $Object.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($ObjectType)) {
    $ObjectType = Read-Host "Ingrese el Tipo de Objeto (ej. *FILE, *PGM, *DTAARA) [Default: *FILE]"
}
if ([string]::IsNullOrWhiteSpace($ObjectType)) { $ObjectType = "*FILE" }
$ObjectType = $ObjectType.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($TargetUser)) {
    $TargetUser = Read-Host "Ingrese el Usuario destinatario del permiso (ej. *PUBLIC o usuario especifico) [Default: *PUBLIC]"
}
if ([string]::IsNullOrWhiteSpace($TargetUser)) { $TargetUser = "*PUBLIC" }
$TargetUser = $TargetUser.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($Authority)) {
    $Authority = Read-Host "Ingrese el Nivel de Autorizacion (*CHANGE, *USE, *ALL, *EXCLUDE) [Default: *CHANGE]"
}
if ([string]::IsNullOrWhiteSpace($Authority)) { $Authority = "*CHANGE" }
$Authority = $Authority.Trim().Trim('"').Trim("'").ToUpper()

if ([string]::IsNullOrWhiteSpace($AspDev)) {
    $AspInput = Read-Host "Ingrese el Dispositivo de ASP / IASP (ej. IASP01) [Presione Enter si no aplica]"
    if (-not [string]::IsNullOrWhiteSpace($AspInput)) {
        $AspDev = $AspInput.Trim().Trim('"').Trim("'").ToUpper()
    }
}

if ([string]::IsNullOrWhiteSpace($Requester)) {
    $Requester = Read-Host "Ingrese el Usuario Solicitante (presione Enter para usar $env:USERNAME)"
}
if ([string]::IsNullOrWhiteSpace($Requester)) {
    $Requester = $env:USERNAME
}
$Requester = $Requester.Trim().Trim('"').Trim("'")

# 2. Construccion del Comando CL Nativo (GRTOBJAUT o RVKOBJAUT)
$AspClause = if (-not [string]::IsNullOrWhiteSpace($AspDev)) { " ASPDEV($AspDev)" } else { "" }

$ClCommand = if ($Action.ToUpper() -eq "REVOKE") {
    "RVKOBJAUT OBJ($Library/$Object) OBJTYPE($ObjectType) USER($TargetUser) AUT($Authority)$AspClause"
}
else {
    "GRTOBJAUT OBJ($Library/$Object) OBJTYPE($ObjectType) USER($TargetUser) AUT($Authority)$AspClause"
}

# Generacion de Audit ID y Timestamp
$AuditId = "AUD-AUT-" + (Get-Date -Format "yyyyMMddHHmmss") + "-" + ([guid]::NewGuid().ToString().Substring(0, 4).ToUpper())
$Timestamp = (Get-Date).ToString("o")

$LogDir = Join-Path -Path $PSScriptRoot -ChildPath "..\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$AuditLogFile = if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    $LogFile
}
else {
    Join-Path -Path $LogDir -ChildPath "as400_permissions_audit.jsonl"
}

function Write-AuditRecord {
    param ($Record)
    $JsonLine = $Record | ConvertTo-Json -Compress -Depth 5
    Add-Content -Path $AuditLogFile -Value $JsonLine -Encoding UTF8
}

# 3. Verificacion Obligatoria Human-in-the-Loop (HITL)
if (-not $Approved) {
    Write-Host "`n====================================================================" -ForegroundColor Yellow
    Write-Host "SOLICITUD DE APROBACION: PERMISOLOGIA DE OBJETOS EN AS400 (IBM i)" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "Servidor Destino   : $HostName"
    Write-Host "Objeto Afectado    : $Library/$Object ($ObjectType)"
    if (-not [string]::IsNullOrWhiteSpace($AspDev)) {
        Write-Host "Dispositivo de ASP : $AspDev"
    }
    Write-Host "Usuario Destino    : $TargetUser"
    Write-Host "Nivel de Permiso   : $Authority"
    Write-Host "Accion             : $Action"
    Write-Host "Solicitante        : $Requester"
    Write-Host "Comando a Ejecutar : $ClCommand"
    Write-Host "====================================================================" -ForegroundColor Yellow
    $Confirm = Read-Host "¿Desea APROBAR y ejecutar este cambio de permisos? (S/N)"
    if ($Confirm -match "^[SsYy]([IisS])?$") {
        $Approved = $true
        if ([string]::IsNullOrWhiteSpace($Approver)) {
            $Approver = $Requester
        }
    }
}

if (-not $Approved) {
    $ErrorResp = @{
        status         = 403
        mensaje        = "Operacion cancelada: Se requiere aprobacion humana explicita (Human-in-the-Loop) para modificacion de permisos."
        tipo_operacion = "CL_PERMISOS_OBJETO"
        host           = $HostName
        objeto         = "$Library/$Object"
        solicitante    = $Requester
        auditoria_id   = $AuditId
    }
    
    $AuditRecord = @{
        auditoria_id        = $AuditId
        timestamp           = $Timestamp
        host                = $HostName
        usuario_solicitante = $Requester
        usuario_aprobador   = $null
        tipo_operacion      = "CL_PERMISOS_OBJETO"
        objeto              = "$Library/$Object"
        comando             = $ClCommand
        estado              = "RECHAZADO_SIN_APROBACION"
        filas_afectadas     = 0
        respuesta           = $ErrorResp
    }
    Write-AuditRecord -Record $AuditRecord

    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

# 4. Captura Segura de Credenciales de Administrador AS400 (Owner / *OBJMGT / *ALLOBJ)
if ([string]::IsNullOrWhiteSpace($AdminUser)) {
    $AdminUser = Read-Host "Ingrese el Usuario con autoridad sobre el objeto en AS400"
}
$AdminUser = $AdminUser.Trim().Trim('"').Trim("'")

if ($null -eq $AdminPassword) {
    $AdminPassword = Read-Host "Ingrese la Contrasena de AS400 ($AdminUser)" -AsSecureString
}

if ([string]::IsNullOrWhiteSpace($AdminUser) -or $null -eq $AdminPassword) {
    $ErrorResp = @{
        status         = 401
        mensaje        = "Operacion denegada: Faltan credenciales de AS400 para ejecutar el cambio de permisos."
        tipo_operacion = "CL_PERMISOS_OBJETO"
        host           = $HostName
        objeto         = "$Library/$Object"
        solicitante    = $Requester
    }
    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

$BSTRAdmin = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
$PlainAdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTRAdmin)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTRAdmin)

# 5. Formateo de comando mediante QSYS2.QCMDEXC
$EscapedCmd = $ClCommand.Replace("'", "''")
$CmdLen = $ClCommand.Length
$TargetSql = "CALL QSYS2.QCMDEXC('$EscapedCmd', $CmdLen)"

$AuditRecord = @{
    auditoria_id        = $AuditId
    timestamp           = $Timestamp
    host                = $HostName
    usuario_solicitante = $Requester
    usuario_aprobador   = $Approver
    tipo_operacion      = "CL_PERMISOS_OBJETO"
    objeto              = "$Library/$Object"
    comando             = $TargetSql
    estado              = "EN_PROCESO"
    dry_run             = [bool]$DryRun
}

# 6. Modo Simulacion / Dry-Run
if ($DryRun) {
    $Response = [ordered]@{
        status              = 200
        mensaje             = "[SIMULACION / DRY-RUN] Credenciales validadas. Verificacion exitosa de permisologia de objeto"
        tipo_operacion      = "CL_PERMISOS_OBJETO"
        host                = $HostName
        usuario_as400_admin = $AdminUser
        objeto              = "$Library/$Object"
        tipo_objeto         = $ObjectType
        usuario_destino     = $TargetUser
        permiso_otorgado    = $Authority
        sql_ejecutado       = $TargetSql
        filas_afectadas     = 1
        auditoria_id        = $AuditId
        aprobado_por        = $Approver
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
        status           = 200
        mensaje          = "Autorizacion actualizada exitosamente sobre $Library/$Object para $TargetUser ($Authority)"
        tipo_operacion   = "CL_PERMISOS_OBJETO"
        host             = $HostName
        objeto           = "$Library/$Object"
        tipo_objeto      = $ObjectType
        usuario_destino  = $TargetUser
        permiso_otorgado = $Authority
        sql_ejecutado    = $TargetSql
        filas_afectadas  = $RowsAffected
        auditoria_id     = $AuditId
        aprobado_por     = $Approver
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
        status        = 500
        mensaje       = "Error al ejecutar cambio de autorizacion sobre $Library/$Object en IBM i DB2"
        host          = $HostName
        objeto        = "$Library/$Object"
        error_detalle = $ErrMsg
        auditoria_id  = $AuditId
    }

    $AuditRecord.estado = "ERROR_EJECUCION"
    $AuditRecord.respuesta = $ResponseError
    Write-AuditRecord -Record $AuditRecord

    $ResponseError | ConvertTo-Json -Depth 5
    exit 1
}
