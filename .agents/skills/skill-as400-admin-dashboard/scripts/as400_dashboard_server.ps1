<#
.SYNOPSIS
    as400_dashboard_server.ps1 - Servidor HTTP nativo y API REST para el Portal de Seguridad AS400.
.DESCRIPTION
    Servidor backend ligero basado en System.Net.HttpListener para PowerShell.
    Sirve la interfaz web SPA (HTML, CSS, JS) y expone la API REST que orquesta:
    - Autenticacion corporativa LDAPS (636 TLS) contra Active Directory Banesco.
    - Consultas a QSYS2.USER_INFO en IBM i AS400 (LPAR DEV: 10.137.0.138).
    - Modulo de cambio de contrasenas (CHGUSRPRF) con auditoria segregada.
    - Modulo de permisologia de objetos (GRTOBJAUT / RVKOBJAUT) con solicitud de Objeto y Libreria.
    - Streaming de auditoria en vivo de logs jsonl.
.PARAMETER Port
    Puerto local donde escuchara el servidor (Default: 8085).
.PARAMETER OpenBrowser
    Abre automaticamente el navegador predeterminado al iniciar el servidor.
.EXAMPLE
    .\as400_dashboard_server.ps1 -Port 8085 -OpenBrowser
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
param (
    [int]$Port = 8085,

    [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$WebDir = Join-Path -Path $ScriptDir -ChildPath "..\web"
$LogDir = Join-Path -Path $ScriptDir -ChildPath "..\..\skill-as400-sql-permisos\logs"
$PermSkillDir = Join-Path -Path $ScriptDir -ChildPath "..\..\skill-as400-sql-permisos\scripts"

if (-not (Test-Path $WebDir)) {
    Write-Error "No se encontro el directorio web en: $WebDir"
    exit 1
}

$Listener = New-Object System.Net.HttpListener
$Prefix = "http://localhost:$Port/"
$Listener.Prefixes.Add($Prefix)

try {
    $Listener.Start()
}
catch {
    Write-Host ("[!] Error al iniciar HttpListener en el puerto {0}: {1}" -f $Port, $_.Exception.Message) -ForegroundColor Red
    Write-Host "[*] Intentando puerto alternativo 8086..." -ForegroundColor Yellow
    $Port = 8086
    $Listener = New-Object System.Net.HttpListener
    $Prefix = "http://localhost:$Port/"
    $Listener.Prefixes.Add($Prefix)
    $Listener.Start()
}

Write-Host "`n====================================================================" -ForegroundColor Green
Write-Host " BANESCO | SERVIDOR DASHBOARD AS400 (IBM i v7.5 - 10.137.0.138)    " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  -> URL Local        : $Prefix" -ForegroundColor Cyan
Write-Host "  -> Directorio Web   : $WebDir" -ForegroundColor Gray
Write-Host "  -> Seguridad        : LDAPS 636 TLS (Active Directory Banesco)" -ForegroundColor Gray
Write-Host "  -> Estado           : En linea y escuchando solicitudes..." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "Presione Ctrl+C en esta consola para detener el servidor.`n" -ForegroundColor Yellow

if ($OpenBrowser) {
    Start-Process $Prefix
}

function Send-Response {
    param (
        $Response,
        [string]$Content,
        [string]$ContentType = "text/html; charset=utf-8",
        [int]$StatusCode = 200
    )
    $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $Buffer.Length
    $Response.AddHeader("Access-Control-Allow-Origin", "*")
    $Response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $Response.AddHeader("Access-Control-Allow-Headers", "Content-Type, X-AS400-User, X-AS400-Password")
    $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
    $Response.OutputStream.Close()
}

function Send-Json {
    param ($Response, $Data, [int]$StatusCode = 200)
    $JsonStr = $Data | ConvertTo-Json -Depth 5 -Compress
    Send-Response -Response $Response -Content $JsonStr -ContentType "application/json; charset=utf-8" -StatusCode $StatusCode
}

function Read-RequestBody {
    param ($Request)
    $Reader = New-Object System.IO.StreamReader($Request.InputStream, $Request.ContentEncoding)
    $Body = $Reader.ReadToEnd()
    $Reader.Close()
    return $Body
}

# Bucle Principal de Atencion de Peticiones HTTP
while ($Listener.IsListening) {
    try {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response
        $UrlPath = $Request.Url.AbsolutePath
        $Method = $Request.HttpMethod

        # Soporte CORS Preflight
        if ($Method -eq "OPTIONS") {
            Send-Response -Response $Response -Content "" -StatusCode 204
            continue
        }

        # ---------------------------------------------------------------------
        # 1. ENRUTAMIENTO DE ARCHIVOS ESTÁTICOS
        # ---------------------------------------------------------------------
        if ($UrlPath -eq "/" -or $UrlPath -eq "/index.html") {
            $File = Join-Path $WebDir "index.html"
            $Html = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
            Send-Response -Response $Response -Content $Html -ContentType "text/html; charset=utf-8"
            continue
        }
        elseif ($UrlPath -eq "/styles.css") {
            $File = Join-Path $WebDir "styles.css"
            $Css = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
            Send-Response -Response $Response -Content $Css -ContentType "text/css; charset=utf-8"
            continue
        }
        elseif ($UrlPath -eq "/app.js") {
            $File = Join-Path $WebDir "app.js"
            $Js = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
            Send-Response -Response $Response -Content $Js -ContentType "application/javascript; charset=utf-8"
            continue
        }

        # ---------------------------------------------------------------------
        # 2. ENDPOINTS REST API
        # ---------------------------------------------------------------------
        # Validacion en Directorio Activo: Gerente (aguevara) y Supervisados (cedulasupervisor)
        if ($UrlPath -eq "/api/ad/team-hierarchy" -and $Method -eq "GET") {
            $HierarchyScript = Join-Path $ScriptDir "as400_get_ad_hierarchy.ps1"
            $ResultJson = & $HierarchyScript -ManagerUser "aguevara" -SearchBase "OU=Usuarios,DC=intra,DC=banesco,DC=com" -AllowSimulation
            Send-Response -Response $Response -Content $ResultJson -ContentType "application/json; charset=utf-8"
            continue
        }

        # Autenticacion Corporativa contra Active Directory Banesco (LDAPS / TLS)
        if ($UrlPath -eq "/api/auth/login" -and $Method -eq "POST") {
            $Body = Read-RequestBody -Request $Request
            $Payload = $Body | ConvertFrom-Json
            
            $LdapScript = Join-Path $ScriptDir "as400_ldap_auth.ps1"
            $AuthResultJson = & $LdapScript -Username $Payload.username -Password $Payload.password
            
            $AuthObj = $AuthResultJson | ConvertFrom-Json
            $StatusCode = if ($AuthObj.authenticated) { 200 } else { 401 }
            
            Send-Response -Response $Response -Content $AuthResultJson -ContentType "application/json; charset=utf-8" -StatusCode $StatusCode
            continue
        }

        # Buscador Maestro: Consulta a QSYS2.USER_INFO (LPAR 10.137.0.138)
        if ($UrlPath -eq "/api/user-info" -and $Method -eq "GET") {
            $Query = $Request.QueryString["user"]
            $StatusFilter = $Request.QueryString["status"]
            if ([string]::IsNullOrWhiteSpace($StatusFilter)) { $StatusFilter = "*ALL" }

            $AdminUser = $Request.Headers["X-AS400-User"]
            $AdminPass = $Request.Headers["X-AS400-Password"]
            if ([string]::IsNullOrWhiteSpace($AdminUser)) {
                $AdminUser = $Request.QueryString["adminUser"]
                $AdminPass = $Request.QueryString["adminPass"]
            }

            $UserInfoScript = Join-Path $ScriptDir "as400_get_user_info.ps1"
            if (-not [string]::IsNullOrWhiteSpace($AdminUser) -and -not [string]::IsNullOrWhiteSpace($AdminPass)) {
                $ResultJson = & $UserInfoScript -SearchUser $Query -StatusFilter $StatusFilter -HostName "10.137.0.138" -AdminUser $AdminUser -AdminPassword $AdminPass
                $HttpCode = 200
                try {
                    $ResultObj = $ResultJson | ConvertFrom-Json
                    if ($ResultObj.status) {
                        $HttpCode = [int]$ResultObj.status
                    }
                } catch {
                    $HttpCode = 200
                }
                Send-Response -Response $Response -Content $ResultJson -StatusCode $HttpCode -ContentType "application/json; charset=utf-8"
            } else {
                $ResultJson = @{
                    status = 401
                    error = "CREDENCIALES_REQUERIDAS"
                    mensaje = "Se requieren credenciales de operador IBM i (Usuario y Contraseña) para consultar QSYS2.USER_INFO en línea en 10.137.0.138."
                    host = "10.137.0.138"
                    modo = "REQUIERE_CREDENCIALES"
                    data = @()
                } | ConvertTo-Json -Depth 4
                Send-Response -Response $Response -Content $ResultJson -StatusCode 401 -ContentType "application/json; charset=utf-8"
            }
            continue
        }

        # Modulo Cambio de Contrasena (CHGUSRPRF)
        if ($UrlPath -eq "/api/change-password" -and $Method -eq "POST") {
            $Body = Read-RequestBody -Request $Request
            $Payload = $Body | ConvertFrom-Json
            
            $PwdScript = Join-Path $PermSkillDir "as400_change_password.ps1"
            $SecPass = $Payload.NewPassword | ConvertTo-SecureString -AsPlainText -Force
            $SecAdmin = $Payload.AdminPassword | ConvertTo-SecureString -AsPlainText -Force

            $Result = & $PwdScript `
                -HostName ($Payload.HostName) `
                -TargetUser ($Payload.TargetUser) `
                -NewPassword $SecPass `
                -ForceExpiration ($Payload.ForceExpiration) `
                -AdminUser ($Payload.AdminUser) `
                -AdminPassword $SecAdmin `
                -Requester ($Payload.Requester) `
                -Approved `
                -DryRun:([bool]$Payload.DryRun)

            Send-Response -Response $Response -Content $Result -ContentType "application/json; charset=utf-8"
            continue
        }

        # Modulo Permisologia de Objetos (GRTOBJAUT / RVKOBJAUT)
        if ($UrlPath -eq "/api/manage-permissions" -and $Method -eq "POST") {
            $Body = Read-RequestBody -Request $Request
            $Payload = $Body | ConvertFrom-Json
            
            $PermScript = Join-Path $PermSkillDir "as400_manage_permissions.ps1"
            $SecAdmin = $Payload.AdminPassword | ConvertTo-SecureString -AsPlainText -Force

            $TargetUser = if ([string]::IsNullOrWhiteSpace($Payload.TargetUser)) { "*PUBLIC" } else { $Payload.TargetUser }

            $Result = & $PermScript `
                -HostName ($Payload.HostName) `
                -Library ($Payload.Library) `
                -Object ($Payload.Object) `
                -ObjectType ($Payload.ObjectType) `
                -TargetUser $TargetUser `
                -Authority ($Payload.Authority) `
                -Action ($Payload.Action) `
                -AspDev ($Payload.AspDev) `
                -AdminUser ($Payload.AdminUser) `
                -AdminPassword $SecAdmin `
                -Requester ($Payload.Requester) `
                -Approved `
                -DryRun:([bool]$Payload.DryRun)

            Send-Response -Response $Response -Content $Result -ContentType "application/json; charset=utf-8"
            continue
        }

        # Modulo de Autorizaciones Especiales de Usuario (CHGUSRPRF SPCAUT)
        if ($UrlPath -eq "/api/user-spcaut" -and $Method -eq "POST") {
            $Body = Read-RequestBody -Request $Request
            $Payload = $Body | ConvertFrom-Json
            
            $SpcautScript = Join-Path $ScriptDir "as400_manage_spcaut.ps1"
            $SecAdmin = $Payload.AdminPassword | ConvertTo-SecureString -AsPlainText -Force

            $Result = & $SpcautScript `
                -HostName ($Payload.HostName) `
                -TargetUser ($Payload.TargetUser) `
                -SpecialAuthorities ($Payload.SpecialAuthorities) `
                -AdminUser ($Payload.AdminUser) `
                -AdminPassword $SecAdmin `
                -Requester ($Payload.Requester) `
                -Approved `
                -DryRun:([bool]$Payload.DryRun)

            Send-Response -Response $Response -Content $Result -ContentType "application/json; charset=utf-8"
            continue
        }

        # Feed de Auditoria: Contrasenas
        if ($UrlPath -eq "/api/logs/passwords" -and $Method -eq "GET") {
            $LogFile = Join-Path $LogDir "as400_password_audit.jsonl"
            $Entries = @()
            if (Test-Path $LogFile) {
                $Lines = Get-Content -Path $LogFile -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                foreach ($Line in ($Lines | Select-Object -Last 30)) {
                    $Entries += ($Line | ConvertFrom-Json)
                }
            }
            [array]::Reverse($Entries)
            Send-Json -Response $Response -Data $Entries
            continue
        }

        # Feed de Auditoria: Permisos
        if ($UrlPath -eq "/api/logs/permissions" -and $Method -eq "GET") {
            $LogFile = Join-Path $LogDir "as400_permissions_audit.jsonl"
            $Entries = @()
            if (Test-Path $LogFile) {
                $Lines = Get-Content -Path $LogFile -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                foreach ($Line in ($Lines | Select-Object -Last 30)) {
                    $Entries += ($Line | ConvertFrom-Json)
                }
            }
            [array]::Reverse($Entries)
            Send-Json -Response $Response -Data $Entries
            continue
        }

        # 404 No Encontrado
        Send-Response -Response $Response -Content "Ruta no encontrada" -StatusCode 404
    }
    catch {
        Write-Host "Error al procesar solicitud: $($_.Exception.Message)" -ForegroundColor Red
        if ($Response) {
            Send-Response -Response $Response -Content "Error interno del servidor" -StatusCode 500
        }
    }
}
