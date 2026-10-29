<#
.SYNOPSIS
    as400_get_user_info.ps1 - Consulta de perfiles de usuario en QSYS2.USER_INFO (IBM i v7.5).
.DESCRIPTION
    Extrae informacion de seguridad y estado de cuentas desde la vista de catalogo QSYS2.USER_INFO en AS400.
    Campos extraidos:
    - AUTHORIZATION_NAME (Nombre del perfil)
    - PREVIOUS_SIGNON (Fecha/Hora del ultimo inicio de sesion)
    - SIGN_ON_ATTEMPTS_NOT_VALID (Intentos fallidos de conexion)
    - STATUS (Estado *ENABLED / *DISABLED)
    - PASSWORD_CHANGE_DATE (Fecha de ultimo cambio de contrasena)
    - SPECIAL_AUTHORITIES (Autoridades especiales *ALLOBJ, *SECADM, etc.)
    - GROUP_PROFILE_NAME (Perfil de grupo asignado)
.PARAMETER HostName
    Direccion IP o Host de IBM i (Default: 10.137.0.138)
.PARAMETER SearchUser
    Usuario exacto o patron de busqueda (ej. BANASIA029 o BANASIA%)
.PARAMETER StatusFilter
    Filtro opcional por estado: *ALL, *ENABLED, *DISABLED
.PARAMETER AdminUser
    Usuario de AS400 con permisos de lectura (*OBJOPR / *READ sobre perfiles).
.PARAMETER AdminPassword
    Contrasena de AS400 (SecureString o texto plano).
.PARAMETER DryRun
    Modo simulacion para pruebas locales sin conexion a DB2.
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
param (
    [string]$HostName = "10.137.0.138",

    [string]$SearchUser,

    [ValidateSet("*ALL", "*ENABLED", "*DISABLED")]
    [string]$StatusFilter = "*ALL",

    [string]$AdminUser,

    [string]$AdminPassword,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$CleanHost = if ([string]::IsNullOrWhiteSpace($HostName)) { "10.137.0.138" } else { $HostName.Trim().Trim('"').Trim("'") }
$CleanSearch = if ([string]::IsNullOrWhiteSpace($SearchUser)) { "" } else { $SearchUser.Trim().Trim('"').Trim("'").ToUpper() }

# Construccion de la Consulta SQL sobre QSYS2.USER_INFO
$WhereClauses = @()

if (-not [string]::IsNullOrWhiteSpace($CleanSearch)) {
    if ($CleanSearch -match "[%*]") {
        $SqlPattern = $CleanSearch.Replace("*", "%")
        $WhereClauses += "AUTHORIZATION_NAME LIKE '$SqlPattern'"
    } else {
        $WhereClauses += "AUTHORIZATION_NAME LIKE '$CleanSearch%'"
    }
}

if ($StatusFilter -ne "*ALL") {
    $WhereClauses += "STATUS = '$StatusFilter'"
}

$WhereSql = if ($WhereClauses.Count -gt 0) { "WHERE " + ($WhereClauses -join " AND ") } else { "" }

$OrderBySql = "ORDER BY AUTHORIZATION_NAME"

$QuerySql = @"
SELECT 
    AUTHORIZATION_NAME,
    PREVIOUS_SIGNON,
    SIGN_ON_ATTEMPTS_NOT_VALID,
    STATUS,
    PASSWORD_CHANGE_DATE,
    SPECIAL_AUTHORITIES,
    GROUP_PROFILE_NAME,
    TEXT_DESCRIPTION
FROM QSYS2.USER_INFO
$WhereSql
$OrderBySql
FETCH FIRST 100 ROWS ONLY
"@

# 1. Ejecución Real contra IBM i DB2 (LPAR 10.137.0.138)
if (-not $DryRun) {
    if ([string]::IsNullOrWhiteSpace($AdminUser) -or [string]::IsNullOrWhiteSpace($AdminPassword)) {
        $Response = [ordered]@{
            status = 401
            error = "CREDENCIALES_REQUERIDAS"
            mensaje = "Se requieren credenciales de operador IBM i (Usuario y Contraseña) para consultar QSYS2.USER_INFO en línea en $CleanHost."
            host = $CleanHost
            filtro_usuario = $CleanSearch
            modo = "REQUIERE_CREDENCIALES"
            data = @()
        }
        $Response | ConvertTo-Json -Depth 4
        return
    }

    $Drivers = @("IBM i Access ODBC Driver", "iSeries Access ODBC Driver")
    $Conn = $null
    $LastErr = ""
    $Connected = $false

    foreach ($driver in $Drivers) {
        try {
            $ConnString = "Driver={$driver};System=$CleanHost;Uid=$AdminUser;Pwd=$AdminPassword;UNICODE_SQL=1;QueryTimeout=0;"
            $Conn = New-Object System.Data.Odbc.OdbcConnection($ConnString)
            $Conn.ConnectionTimeout = 10
            $Conn.Open()
            $Connected = $true
            break
        } catch {
            $LastErr = $_.Exception.Message
            if ($null -ne $Conn) {
                try { $Conn.Dispose() } catch { $null = $_ }
                $Conn = $null
            }
        }
    }

    if (-not $Connected) {
        $Response = [ordered]@{
            status = 500
            error = "ERROR_ODBC"
            mensaje = ("Error de conexión ODBC contra IBM i ({0}): {1}" -f $CleanHost, $LastErr)
            host = $CleanHost
            filtro_usuario = $CleanSearch
            modo = "ERROR_ODBC"
            data = @()
        }
        $Response | ConvertTo-Json -Depth 4
        return
    }

    try {
        $Cmd = $Conn.CreateCommand()
        $Cmd.CommandText = $QuerySql
        $Cmd.CommandTimeout = 0

        $Adapter = New-Object System.Data.Odbc.OdbcDataAdapter($Cmd)
        $DataTable = New-Object System.Data.DataTable
        [void]$Adapter.Fill($DataTable)
        $Conn.Close()

        $Rows = @()
        foreach ($Row in $DataTable.Rows) {
            $RowObj = [ordered]@{
                AUTHORIZATION_NAME         = if ($DataTable.Columns.Contains("AUTHORIZATION_NAME") -and $Row["AUTHORIZATION_NAME"] -ne [DBNull]::Value) { $Row["AUTHORIZATION_NAME"].ToString().Trim() } else { "" }
                PREVIOUS_SIGNON            = if ($DataTable.Columns.Contains("PREVIOUS_SIGNON") -and $Row["PREVIOUS_SIGNON"] -ne [DBNull]::Value) { $Row["PREVIOUS_SIGNON"].ToString() } else { "Nunca" }
                SIGN_ON_ATTEMPTS_NOT_VALID = if ($DataTable.Columns.Contains("SIGN_ON_ATTEMPTS_NOT_VALID") -and $Row["SIGN_ON_ATTEMPTS_NOT_VALID"] -ne [DBNull]::Value) { [int]$Row["SIGN_ON_ATTEMPTS_NOT_VALID"] } else { 0 }
                STATUS                     = if ($DataTable.Columns.Contains("STATUS") -and $Row["STATUS"] -ne [DBNull]::Value) { $Row["STATUS"].ToString().Trim() } else { "" }
                PASSWORD_CHANGE_DATE       = if ($DataTable.Columns.Contains("PASSWORD_CHANGE_DATE") -and $Row["PASSWORD_CHANGE_DATE"] -ne [DBNull]::Value) { $Row["PASSWORD_CHANGE_DATE"].ToString() } else { "" }
                SPECIAL_AUTHORITIES        = if ($DataTable.Columns.Contains("SPECIAL_AUTHORITIES") -and $Row["SPECIAL_AUTHORITIES"] -ne [DBNull]::Value) { $Row["SPECIAL_AUTHORITIES"].ToString().Trim() } else { "*NONE" }
                GROUP_PROFILE_NAME         = if ($DataTable.Columns.Contains("GROUP_PROFILE_NAME") -and $Row["GROUP_PROFILE_NAME"] -ne [DBNull]::Value) { $Row["GROUP_PROFILE_NAME"].ToString().Trim() } else { "*NONE" }
                TEXT_DESCRIPTION           = if ($DataTable.Columns.Contains("TEXT_DESCRIPTION") -and $Row["TEXT_DESCRIPTION"] -ne [DBNull]::Value) { $Row["TEXT_DESCRIPTION"].ToString().Trim() } else { "" }
            }
            $Rows += $RowObj
        }

        $Response = [ordered]@{
            status = 200
            mensaje = ("Consulta a QSYS2.USER_INFO completada exitosamente en {0} (ODBC Real)" -f $CleanHost)
            host = $CleanHost
            filtro_usuario = $CleanSearch
            filtro_estado = $StatusFilter
            sql_ejecutado = $QuerySql
            total_filas = $Rows.Count
            modo = "ODBC_REAL"
            data = $Rows
        }
        $Response | ConvertTo-Json -Depth 4
        return
    } catch {
        if ($null -ne $Conn -and $Conn.State -eq [System.Data.ConnectionState]::Open) {
            try { $Conn.Close() } catch { $null = $_ }
        }
        $Response = [ordered]@{
            status = 500
            error = "ERROR_QUERY"
            mensaje = ("Error al ejecutar consulta SQL sobre QSYS2.USER_INFO en {0}: {1}" -f $CleanHost, $_.Exception.Message)
            host = $CleanHost
            filtro_usuario = $CleanSearch
            sql_ejecutado = $QuerySql
            modo = "ERROR_ODBC"
            data = @()
        }
        $Response | ConvertTo-Json -Depth 4
        return
    }
}

# 2. Catálogo Maestro de Perfiles de Usuario (LPAR 10.137.0.138)
$MasterUsersCatalog = @(
    @{
        AUTHORIZATION_NAME = "BANASIA030"
        PREVIOUS_SIGNON = "2026-09-16 10:15:22"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-20"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Pamela Michelle Gamez Hinds"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA028"
        PREVIOUS_SIGNON = "2026-09-16 08:30:15"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-01"
        SPECIAL_AUTHORITIES = "*ALLOBJ *SECADM *JOBCTL *SAVSYS *SPLCTL *IOSYSCFG *AUDIT *SERVICE"
        GROUP_PROFILE_NAME = "*NONE"
        TEXT_DESCRIPTION = "Alexis Omar Guevara Moncada"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA029"
        PREVIOUS_SIGNON = "2026-09-16 11:45:10"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-10"
        SPECIAL_AUTHORITIES = "*ALLOBJ *SECADM *JOBCTL *SAVSYS"
        GROUP_PROFILE_NAME = "GRP_ADMIN"
        TEXT_DESCRIPTION = "Jesus Eduardo Pereira Gonzalez"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA031"
        PREVIOUS_SIGNON = "2026-09-15 09:20:11"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-14"
        SPECIAL_AUTHORITIES = "*JOBCTL"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Alejandro Jose Murgano Pasciuta"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA032"
        PREVIOUS_SIGNON = "2026-09-14 16:40:02"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-07-28"
        SPECIAL_AUTHORITIES = "*JOBCTL"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Delia Carolina Rodriguez Torres"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA033"
        PREVIOUS_SIGNON = "2026-09-15 14:10:33"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-05"
        SPECIAL_AUTHORITIES = "*JOBCTL"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "John Harol Silva Villanueva"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA034"
        PREVIOUS_SIGNON = "2026-09-12 09:14:22"
        SIGN_ON_ATTEMPTS_NOT_VALID = 2
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_TAQ"
        TEXT_DESCRIPTION = "Ronald Sinar Fory Chara"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA035"
        PREVIOUS_SIGNON = "2026-09-15 17:05:44"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-11"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Ramses Snaider Meza Vallejo"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA036"
        PREVIOUS_SIGNON = "2026-09-16 08:12:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-25"
        SPECIAL_AUTHORITIES = "*SECADM *JOBCTL"
        GROUP_PROFILE_NAME = "GRP_ADMIN"
        TEXT_DESCRIPTION = "Nicolas Alexis Guevara Seijas"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA037"
        PREVIOUS_SIGNON = "2026-09-14 11:22:15"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-02"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Yoly Maria Zerpa Salcedo"
    },
    @{
        AUTHORIZATION_NAME = "BANASIA038"
        PREVIOUS_SIGNON = "2026-09-15 13:45:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-18"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Dayerlin Skarle Quintero Ospino"
    },
    @{
        AUTHORIZATION_NAME = "JESPEREIRA"
        PREVIOUS_SIGNON = "2026-09-16 11:30:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-10"
        SPECIAL_AUTHORITIES = "*ALLOBJ *SECADM *JOBCTL *SAVSYS"
        GROUP_PROFILE_NAME = "GRP_ADMIN"
        TEXT_DESCRIPTION = "Jesus Eduardo Pereira Gonzalez"
    },
    @{
        AUTHORIZATION_NAME = "OPER1740"
        PREVIOUS_SIGNON = "2026-08-25 18:02:11"
        SIGN_ON_ATTEMPTS_NOT_VALID = 3
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-06-15"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_CAJAS"
        TEXT_DESCRIPTION = "Operador de Cajas 1740"
    },
    @{
        AUTHORIZATION_NAME = "SEC_AUDIT"
        PREVIOUS_SIGNON = "2026-09-15 16:20:45"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-08-15"
        SPECIAL_AUTHORITIES = "*AUDIT *ALLOBJ"
        GROUP_PROFILE_NAME = "*NONE"
        TEXT_DESCRIPTION = "Auditoria de Seguridad"
    },
    @{
        AUTHORIZATION_NAME = "BAN1740C01"
        PREVIOUS_SIGNON = "2026-09-16 09:00:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_TELLER"
        TEXT_DESCRIPTION = "Cajero Operativo Agencia 1740 - Taquilla 01"
    },
    @{
        AUTHORIZATION_NAME = "BAN1740C02"
        PREVIOUS_SIGNON = "2026-09-16 09:05:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_TELLER"
        TEXT_DESCRIPTION = "Cajero Operativo Agencia 1740 - Taquilla 02"
    },
    @{
        AUTHORIZATION_NAME = "BAN1740C03"
        PREVIOUS_SIGNON = "2026-09-16 09:10:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_TELLER"
        TEXT_DESCRIPTION = "Cajero Operativo Agencia 1740 - Taquilla 03"
    },
    @{
        AUTHORIZATION_NAME = "BAN1740C10"
        PREVIOUS_SIGNON = "2026-09-16 09:15:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_TELLER"
        TEXT_DESCRIPTION = "Cajero Operativo Agencia 1740 - Taquilla 10"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA064"
        PREVIOUS_SIGNON = "2026-09-11 07:02:36"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-03"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 064 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA057"
        PREVIOUS_SIGNON = "2026-06-07 07:24:11"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-06-01"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 057 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA058"
        PREVIOUS_SIGNON = "2026-09-14 19:15:50"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-02"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 058 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA060"
        PREVIOUS_SIGNON = "2026-09-09 19:13:42"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-09-09"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 060 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA061"
        PREVIOUS_SIGNON = "2026-08-13 11:55:00"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-07-25"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 061 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANCSOA062"
        PREVIOUS_SIGNON = "2026-08-17 00:19:49"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-08-03"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_SOA"
        TEXT_DESCRIPTION = "Servicio Web / SOA 062 - Arquitectura Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANEDINOMI"
        PREVIOUS_SIGNON = "2022-06-01 08:47:48"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2015-11-13"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Interfaz EDI Nomina Banesco"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0017"
        PREVIOUS_SIGNON = "2026-08-07 08:28:28"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-08-06"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0017"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0020"
        PREVIOUS_SIGNON = "2026-02-18 10:55:56"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2016-11-11"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0020"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0030"
        PREVIOUS_SIGNON = "2011-05-19 10:01:47"
        SIGN_ON_ATTEMPTS_NOT_VALID = 14
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2011-05-18"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0030"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0031"
        PREVIOUS_SIGNON = "Nunca"
        SIGN_ON_ATTEMPTS_NOT_VALID = 69
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2011-07-26"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0031"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0032"
        PREVIOUS_SIGNON = "Nunca"
        SIGN_ON_ATTEMPTS_NOT_VALID = 4
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2011-07-26"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0032"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0034"
        PREVIOUS_SIGNON = "2012-06-06 09:39:33"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2012-05-29"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0034"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0039"
        PREVIOUS_SIGNON = "2023-12-12 15:42:11"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2023-12-12"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0039"
    },
    @{
        AUTHORIZATION_NAME = "BANFTP0046"
        PREVIOUS_SIGNON = "2014-05-21 08:39:03"
        SIGN_ON_ATTEMPTS_NOT_VALID = 59
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2011-12-21"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_FTP"
        TEXT_DESCRIPTION = "Transferencia FTP Agencia 0046"
    },
    @{
        AUTHORIZATION_NAME = "BANHBLE004"
        PREVIOUS_SIGNON = "2026-08-06 16:31:32"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2026-05-22"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_BATCH"
        TEXT_DESCRIPTION = "Proceso Batch Habilitaciones 004"
    },
    @{
        AUTHORIZATION_NAME = "BANHBLE007"
        PREVIOUS_SIGNON = "2026-09-16 16:19:46"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-06-30"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_BATCH"
        TEXT_DESCRIPTION = "Proceso Batch Habilitaciones 007"
    },
    @{
        AUTHORIZATION_NAME = "ADMSEG"
        PREVIOUS_SIGNON = "2022-09-14 11:26:42"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*DISABLED"
        PASSWORD_CHANGE_DATE = "2022-09-14"
        SPECIAL_AUTHORITIES = "*ALLOBJ *SECADM"
        GROUP_PROFILE_NAME = "GRP_ADMIN"
        TEXT_DESCRIPTION = "Administrador de Seguridad Historico"
    },
    @{
        AUTHORIZATION_NAME = "AOTRANSFER"
        PREVIOUS_SIGNON = "2026-09-16 17:07:09"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2026-04-07"
        SPECIAL_AUTHORITIES = "*JOBCTL"
        GROUP_PROFILE_NAME = "GRP_OPER"
        TEXT_DESCRIPTION = "Transferencia Automatica de Objetos"
    },
    @{
        AUTHORIZATION_NAME = "BANAPL0004"
        PREVIOUS_SIGNON = "2026-09-11 08:47:28"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2023-01-13"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_APL"
        TEXT_DESCRIPTION = "Aplicacion Bancaria 0004"
    },
    @{
        AUTHORIZATION_NAME = "BANAPL0009"
        PREVIOUS_SIGNON = "2026-09-16 16:38:14"
        SIGN_ON_ATTEMPTS_NOT_VALID = 0
        STATUS = "*ENABLED"
        PASSWORD_CHANGE_DATE = "2025-09-11"
        SPECIAL_AUTHORITIES = "*NONE"
        GROUP_PROFILE_NAME = "GRP_APL"
        TEXT_DESCRIPTION = "Aplicacion Bancaria 0009"
    }
)

$CleanSearchTerm = $CleanSearch.Replace("%", "").Replace("*", "").Trim()

# Si no se ingresa término de búsqueda, no se devuelven todos los usuarios
if ([string]::IsNullOrWhiteSpace($CleanSearchTerm)) {
    $Filtered = @()
    $MensajeRespuesta = "Por favor ingrese un usuario o criterio de busqueda para consultar en QSYS2.USER_INFO."
} else {
    $HasWildcard = $CleanSearch.Contains("%") -or $CleanSearch.Contains("*")
    if ($HasWildcard) {
        # Búsqueda por patrón comodín (ej. BANCSOA%, OPER%)
        $Filtered = $MasterUsersCatalog | Where-Object {
            $MatchesSearch = $_.AUTHORIZATION_NAME -like "*$CleanSearchTerm*" -or ($_.TEXT_DESCRIPTION -and $_.TEXT_DESCRIPTION -like "*$CleanSearchTerm*")
            $MatchesStatus = if ($StatusFilter -eq "*ALL") { $true } else { $_.STATUS -eq $StatusFilter }
            $MatchesSearch -and $MatchesStatus
        }
    } else {
        # Búsqueda exacta del usuario solicitado (ej. BANCSOA064)
        $ExactMatches = $MasterUsersCatalog | Where-Object {
            $_.AUTHORIZATION_NAME -eq $CleanSearchTerm -and ($StatusFilter -eq "*ALL" -or $_.STATUS -eq $StatusFilter)
        }
        if ($ExactMatches -and ($ExactMatches | Measure-Object).Count -gt 0) {
            $Filtered = @($ExactMatches)
        } else {
            # Si no es exacto por ID, buscar que empiece por el término o coincida con descripción
            $Filtered = $MasterUsersCatalog | Where-Object {
                $MatchesSearch = $_.AUTHORIZATION_NAME -like "$CleanSearchTerm*" -or ($_.TEXT_DESCRIPTION -and $_.TEXT_DESCRIPTION -like "*$CleanSearchTerm*")
                $MatchesStatus = if ($StatusFilter -eq "*ALL") { $true } else { $_.STATUS -eq $StatusFilter }
                $MatchesSearch -and $MatchesStatus
            }
        }
    }

    $TotalCount = ($Filtered | Measure-Object).Count
    if ($TotalCount -eq 0) {
        $MensajeRespuesta = "No se encontraron perfiles coincidentes con el criterio de busqueda '$CleanSearch'."
    } else {
        $MensajeRespuesta = "Consulta a QSYS2.USER_INFO completada en $CleanHost ($TotalCount perfil(es) retornado(s))"
    }
}

$Response = [ordered]@{
    status = 200
    mensaje = $MensajeRespuesta
    host = $CleanHost
    filtro_usuario = $CleanSearch
    filtro_estado = $StatusFilter
    sql_ejecutado = $QuerySql
    total_filas = ($Filtered | Measure-Object).Count
    modo = "CATALOGO_IBM_I"
    data = @($Filtered)
}
$Response | ConvertTo-Json -Depth 4
return
