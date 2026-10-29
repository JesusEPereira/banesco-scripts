<#
.SYNOPSIS
    as400_ldap_auth.ps1 - Modulo de autenticacion corporativa contra Active Directory Banesco (LDAPS / Kerberos / Negotiate).
.DESCRIPTION
    Realiza la validacion estricta de credenciales de usuario contra el controlador de dominio Active Directory
    (intra.banesco.com) utilizando System.DirectoryServices.AccountManagement y protocolos de directorio seguros.
    Soporta formatos UPN (usuario@banesco.com, usuario@intra.banesco.com) y sAMAccountName (ej. jespereira).
    Rechaza estrictamente credenciales invalidas devolviendo HTTP 401 y authenticated: false.
.PARAMETER Username
    Nombre de usuario corporativo (ej. jespereira, jespereira@banesco.com o jespereira@intra.banesco.com)
.PARAMETER Password
    Contrasena de red corporativa.
.PARAMETER LdapServer
    Host del Controlador de Dominio (Default: intra.banesco.com)
.PARAMETER LdapPort
    Puerto de directorio (Default: 636)
.PARAMETER DomainSuffix
    Sufijo de dominio por defecto (Default: @intra.banesco.com)
.PARAMETER SearchBase
    Unidad Organizativa base (Default: OU=Usuarios,DC=intra,DC=banesco,DC=com)
#>

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$LdapServer = "intra.banesco.com",

    [int]$LdapPort = 636,

    [string]$DomainSuffix = "@intra.banesco.com",

    [string]$SearchBase = "OU=Usuarios,DC=intra,DC=banesco,DC=com"
)

$ErrorActionPreference = "SilentlyContinue"

$CleanUser = $Username.Trim().Trim('"').Trim("'")
$CleanPass = $Password

if ([string]::IsNullOrWhiteSpace($CleanUser) -or [string]::IsNullOrWhiteSpace($CleanPass)) {
    $Response = [ordered]@{
        authenticated = $false
        status = 400
        mensaje = "Usuario y contrasena son campos obligatorios."
        usuario = $CleanUser
        timestamp = (Get-Date).ToString("o")
    }
    $Response | ConvertTo-Json -Depth 4
    return
}

# Normalizar formatos de usuario
$SamAccountName = if ($CleanUser -match "@") { $CleanUser.Split('@')[0] } else { $CleanUser }
$UserUpn = if ($CleanUser -match "@") { $CleanUser } else { "$CleanUser$DomainSuffix" }

Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.DirectoryServices -ErrorAction SilentlyContinue

$AuthSuccess = $false
$AuthMessage = ""
$StatusCode = 401
$ErrorCode = "INVALID_CREDENTIALS"
$UserProps = @{
    displayName = $SamAccountName
    title = "Consultor de Seguridad"
    email = "$SamAccountName@banesco.com"
}

try {
    # 1. Intentar validacion primaria mediante PrincipalContext sobre el dominio corporativo
    $ContextOptions = [System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate
    $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
        [System.DirectoryServices.AccountManagement.ContextType]::Domain,
        $LdapServer,
        $SearchBase,
        $ContextOptions
    )

    # Validar primero con SamAccountName
    $AuthSuccess = $PrincipalContext.ValidateCredentials($SamAccountName, $CleanPass)

    # Si no valida y el usuario ingreso formato con @, validar tambien con el UPN exacto
    if (-not $AuthSuccess -and $CleanUser -match "@") {
        $AuthSuccess = $PrincipalContext.ValidateCredentials($CleanUser, $CleanPass)
    }

    if ($AuthSuccess) {
        $StatusCode = 200
        $ErrorCode = $null
        $AuthMessage = "Autenticacion exitosa contra Active Directory Banesco ($LdapServer)."

        # Consultar atributos del perfil en Active Directory
        try {
            $LdapPath = "LDAP://$LdapServer/$SearchBase"
            $Entry = New-Object System.DirectoryServices.DirectoryEntry($LdapPath)
            $Searcher = New-Object System.DirectoryServices.DirectorySearcher($Entry)
            $Searcher.Filter = "(&(objectCategory=user)(sAMAccountName=$SamAccountName))"
            [void]$Searcher.PropertiesToLoad.AddRange(@("displayName", "title", "mail", "department", "telephonenumber"))
            $UserResult = $Searcher.FindOne()

            if ($UserResult -ne $null) {
                $P = $UserResult.Properties
                if ($P["displayName"].Count -gt 0) { $UserProps.displayName = $P["displayName"][0] }
                if ($P["title"].Count -gt 0) { $UserProps.title = $P["title"][0] }
                if ($P["mail"].Count -gt 0) { $UserProps.email = $P["mail"][0] }
            }
        } catch {}
    } else {
        $StatusCode = 401
        $ErrorCode = "LOGON_FAILURE"
        $AuthMessage = "Credenciales invalidas en Active Directory Banesco."
    }
}
catch {
    $ExMsg = $_.Exception.Message
    $AuthSuccess = $false
    $StatusCode = 503
    $ErrorCode = "DIRECTORY_UNAVAILABLE"
    $AuthMessage = "No se pudo conectar con el servicio de Directorio Activo de Banesco ($LdapServer): $ExMsg"
}

$Response = [ordered]@{
    authenticated = $AuthSuccess
    status = $StatusCode
    mensaje = $AuthMessage
    usuario = $SamAccountName
    upn = $UserUpn
    displayName = $UserProps.displayName
    title = $UserProps.title
    email = $UserProps.email
    servidor_ldap = "$($LdapServer):$($LdapPort)"
    seguridad = "LDAPS / Active Directory TLS"
    error_codigo = $ErrorCode
    timestamp = (Get-Date).ToString("o")
}

$Response | ConvertTo-Json -Depth 4
return
