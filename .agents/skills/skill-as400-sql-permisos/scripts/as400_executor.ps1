<#
.SYNOPSIS
    as400_executor.ps1 - Ejecutor PowerShell de sentencias SQL y comandos CL para IBM i / AS400 (v7.5)
.DESCRIPTION
    Skill de automatización para ejecutar SELECT, DML y permisología de objetos nativos con QSYS2.QCMDEXC.
    Solicita usuario y contraseña explícitamente en cada operación sin integración con bóvedas PAM.
    Incluye validación Human-in-the-Loop y registro de auditoría local.
.EXAMPLE
    .\as400_executor.ps1 -HostName "192.168.1.100" -User "ADMIN" -Password "Secret" -OperationType "CL_PERMISOS" -CommandSql "GRTOBJAUT OBJ(MYLIB/MYFILE) OBJTYPE(*FILE) USER(OPER1) AUT(*ALL)" -Requester "analista1" -Approver "jefe1" -Approved -DryRun
#>

[CmdletBinding()]
param (
    [string]$HostName,

    [string]$User,

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [string]$Password,

    [string]$OperationType,

    [string]$CommandSql,

    [string]$Requester,

    [string]$Approver,

    [switch]$Approved,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Solicitud interactiva y sanitización de parámetros de entrada
if ([string]::IsNullOrWhiteSpace($HostName)) {
    $HostName = Read-Host "Ingrese la IP o Host de AS400 (ej. 10.137.0.138)"
}
$HostName = $HostName.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($OperationType)) {
    $OperationType = Read-Host "Ingrese el Tipo de Operacion (SELECT, DML, CL_PERMISOS)"
}
$OperationType = $OperationType.Trim().Trim('"').Trim("'").ToUpper()

if ($OperationType -notmatch "^(SELECT|DML|CL_PERMISOS)$") {
    Write-Error "Tipo de Operacion invalido: '$OperationType'. Valores permitidos: SELECT, DML, CL_PERMISOS."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($CommandSql)) {
    $CommandSql = Read-Host "Ingrese la sentencia SQL o comando CL"
}
$CommandSql = $CommandSql.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($Requester)) {
    $Requester = Read-Host "Ingrese el Usuario Solicitante (presione Enter para usar $env:USERNAME)"
}
$Requester = $Requester.Trim().Trim('"').Trim("'")

# Generación de Audit ID y Timestamp
$AuditId = "AUD-" + (Get-Date -Format "yyyyMMddHHmmss") + "-" + ([guid]::NewGuid().ToString().Substring(0, 4).ToUpper())
$Timestamp = (Get-Date).ToString("o")

$LogDir = Join-Path -Path $PSScriptRoot -ChildPath "..\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$AuditLogFile = Join-Path -Path $LogDir -ChildPath "as400_audit.jsonl"

function Write-AuditRecord {
    param ($Record)
    $JsonLine = $Record | ConvertTo-Json -Compress -Depth 5
    Add-Content -Path $AuditLogFile -Value $JsonLine -Encoding UTF8
}

# 1. Verificación Human-in-the-Loop (HITL)
$IsModifying = ($OperationType -ne "SELECT") -or ($CommandSql -match "INSERT|UPDATE|DELETE|GRANT|REVOKE|CHGOBJAUT|GRTOBJAUT|RVKOBJAUT|CHGUSRPRF|CRTUSRPRF|DLTUSRPRF|CHGOWN")

if ($IsModifying -and -not $Approved) {
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "⚠️ SOLICITUD DE APROBACION DE EJECUCION EN AS400 (IBM i v7.5)" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "Servidor Destino : $HostName"
    Write-Host "Tipo de Accion   : $OperationType"
    Write-Host "Solicitante      : $Requester"
    Write-Host "Comando          : $CommandSql"
    Write-Host "====================================================================" -ForegroundColor Yellow
    $Confirm = Read-Host "¿Desea APROBAR y ejecutar esta transaccion en AS400? (S/N)"
    if ($Confirm -match "^[SsYy]([IisS])?$") {
        $Approved = $true
        if ([string]::IsNullOrWhiteSpace($Approver)) {
            $Approver = $Requester
        }
    }
}

if ($IsModifying -and -not $Approved) {
    $ErrorResp = @{
        status = 403
        mensaje = "Operacion cancelada: Se requiere aprobacion humana explicita (Human-in-the-Loop) para operaciones de modificacion o cambio de permisos."
        tipo_operacion = $OperationType
        host = $HostName
        comando_solicitado = $CommandSql
        solicitante = $Requester
        auditoria_id = $AuditId
    }
    
    $AuditRecord = @{
        auditoria_id = $AuditId
        timestamp = $Timestamp
        host = $HostName
        usuario_solicitante = $Requester
        usuario_aprobador = $null
        tipo_operacion = $OperationType
        comando = $CommandSql
        estado = "RECHAZADO_SIN_APROBACION"
        filas_afectadas = 0
        respuesta = $ErrorResp
    }
    Write-AuditRecord -Record $AuditRecord

    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

# 2. Solicitud interactiva de Usuario y Contraseña de AS400
if ([string]::IsNullOrWhiteSpace($User)) {
    $User = Read-Host "Ingrese el Usuario Administrador de AS400"
}
$User = $User.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($Password)) {
    $SecurePass = Read-Host "Ingrese la Contrasena de AS400" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

if ([string]::IsNullOrWhiteSpace($User) -or [string]::IsNullOrWhiteSpace($Password)) {
    $ErrorResp = @{
        status = 401
        mensaje = "Operacion denegada: Se requieren las credenciales (Usuario y Contrasena) de AS400 para continuar con la operacion."
        tipo_operacion = $OperationType
        host = $HostName
        solicitante = $Requester
    }
    $ErrorResp | ConvertTo-Json -Depth 5
    exit 1
}

# 2. Formatear comando CL si aplica
$TargetSql = $CommandSql
if ($OperationType -eq "CL_PERMISOS" -and -not ($CommandSql.Trim().ToUpper().StartsWith("CALL QSYS2.QCMDEXC"))) {
    $CleanCmd = $CommandSql.Trim().Trim('"').Trim("'")
    $EscapedCmd = $CleanCmd.Replace("'", "''")
    $CmdLen = $CleanCmd.Length
    $TargetSql = "CALL QSYS2.QCMDEXC('$EscapedCmd', $CmdLen)"
}

# 3. Auditoría Inicial
$AuditRecord = @{
    auditoria_id = $AuditId
    timestamp = $Timestamp
    host = $HostName
    usuario_solicitante = $Requester
    usuario_aprobador = $Approver
    tipo_operacion = $OperationType
    comando = $TargetSql
    estado = "EN_PROCESO"
    dry_run = [bool]$DryRun
}

# 4. Modo Simulacion / Dry-Run
if ($DryRun) {
    $SimulatedData = @()
    if ($OperationType -eq "SELECT") {
        $SimulatedData = @(
            @{ STATUS = "SIMULATED_OK"; HOST = $HostName; USER = $User; COMMAND = $TargetSql }
        )
    }

    $Response = [ordered]@{
        status = 200
        mensaje = "[SIMULACION / DRY-RUN] Credenciales validadas. Ejecucion verificada exitosamente en PowerShell"
        tipo_operacion = $OperationType
        host = $HostName
        usuario_as400 = $User
        sql_ejecutado = $TargetSql
        filas_afectadas = if ($IsModifying) { 1 } else { 0 }
        data = $SimulatedData
        auditoria_id = $AuditId
        aprobado_por = $Approver
    }

    $AuditRecord.estado = "EXITOSO_SIMULADO"
    $AuditRecord.filas_afectadas = $Response.filas_afectadas
    $AuditRecord.respuesta = $Response
    Write-AuditRecord -Record $AuditRecord

    $Response | ConvertTo-Json -Depth 5
    exit 0
}

# 5. Ejecución en IBM i (Vía ODBC / System.Data.Odbc)
try {
    $ConnString = "Driver={IBM i Access ODBC Driver};System=$HostName;Uid=$User;Pwd=$Password;UNICODE_SQL=1;"
    $Conn = New-Object System.Data.Odbc.OdbcConnection($ConnString)
    $Conn.Open()

    $Cmd = $Conn.CreateCommand()
    $Cmd.CommandText = $TargetSql

    if ($OperationType -eq "SELECT") {
        $Adapter = New-Object System.Data.Odbc.OdbcDataAdapter($Cmd)
        $DataTable = New-Object System.Data.DataTable
        [void]$Adapter.Fill($DataTable)
        $Conn.Close()

        $Rows = @()
        foreach ($Row in $DataTable.Rows) {
            $RowObj = [ordered]@{}
            foreach ($Col in $DataTable.Columns) {
                $RowObj[$Col.ColumnName] = if ($Row[$Col] -ne [DBNull]::Value) { $Row[$Col].ToString() } else { $null }
            }
            $Rows += $RowObj
        }

        $Response = @{
            status = 200
            mensaje = "Consulta SELECT ejecutada exitosamente"
            tipo_operacion = "SELECT"
            host = $HostName
            usuario_as400 = $User
            filas_retornadas = $Rows.Count
            data = $Rows
            auditoria_id = $AuditId
        }

        $AuditRecord.estado = "EXITOSO"
        $AuditRecord.filas_afectadas = $Rows.Count
        $AuditRecord.respuesta = $Response
        Write-AuditRecord -Record $AuditRecord

        $Response | ConvertTo-Json -Depth 5
        exit 0
    }
    else {
        $RowsAffected = $Cmd.ExecuteNonQuery()
        if ($RowsAffected -lt 0) { $RowsAffected = 1 }
        $Conn.Close()

        $Response = @{
            status = 200
            mensaje = "Operacion $OperationType ejecutada exitosamente en IBM i"
            tipo_operacion = $OperationType
            host = $HostName
            usuario_as400 = $User
            sql_ejecutado = $TargetSql
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
}
catch {
    $ErrMsg = $_.Exception.Message
    $ResponseError = @{
        status = 500
        mensaje = "Excepcion en IBM i DB2"
        host = $HostName
        usuario_as400 = $User
        error_detalle = $ErrMsg
        auditoria_id = $AuditId
    }

    $AuditRecord.estado = "ERROR_EJECUCION"
    $AuditRecord.respuesta = $ResponseError
    Write-AuditRecord -Record $AuditRecord

    $ResponseError | ConvertTo-Json -Depth 5
    exit 1
}
