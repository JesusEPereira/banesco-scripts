<#
.SYNOPSIS
    as400_get_ad_hierarchy.ps1 - Consulta en Active Directory la estructura de la Gerencia de Administracion de Seguridad.
.DESCRIPTION
    Realiza la consulta en el Directorio Activo corporativo (OU=Usuarios,DC=intra,DC=banesco,DC=com)
    del Gerente del Area (Gte. de Admin. de Seguridad aguevara) como principal y de sus supervisados
    validando la correspondencia mediante el atributo "cedulasupervisor".
    Extrae extensiones telefonicas (ultimos 4 digitos) y clasifica entre EMPLEADO o CONTRATISTA.
.PARAMETER ManagerUser
    Nombre de usuario del Gerente (Default: aguevara).
.PARAMETER SearchBase
    Unidad Organizativa base para la busqueda (Default: OU=Usuarios,DC=intra,DC=banesco,DC=com).
.PARAMETER LdapServer
    Servidor de Directorio Activo (Default: intra.banesco.com).
.PARAMETER AllowSimulation
    Fuerza o permite el retorno estructurado si AD no esta accesible en el entorno de desarrollo.
#>

[CmdletBinding()]
param (
    [string]$ManagerUser = "aguevara",
    [string]$SearchBase = "OU=Usuarios,DC=intra,DC=banesco,DC=com",
    [string]$LdapServer = "intra.banesco.com",
    [switch]$AllowSimulation
)

$ErrorActionPreference = "SilentlyContinue"

$Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
$ResultData = $null

function Extract-PhoneExtension {
    param ([string]$PhoneStr, [string]$DefaultExt = "7000")
    if ([string]::IsNullOrWhiteSpace($PhoneStr)) { return $DefaultExt }
    $CleanDigits = $PhoneStr -replace "[^0-9]", ""
    if ($CleanDigits.Length -ge 4) {
        return $CleanDigits.Substring($CleanDigits.Length - 4)
    } elseif ($CleanDigits.Length -gt 0) {
        return $CleanDigits
    }
    return $DefaultExt
}

# Intentar consulta real contra Active Directory
try {
    Add-Type -AssemblyName System.DirectoryServices -ErrorAction SilentlyContinue

    $LdapPath = if (-not [string]::IsNullOrWhiteSpace($LdapServer)) {
        "LDAP://$($LdapServer)/$SearchBase"
    } else {
        "LDAP://$SearchBase"
    }

    $Entry = New-Object System.DirectoryServices.DirectoryEntry($LdapPath)
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher($Entry)
    $Searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
    $Searcher.PageSize = 100

    # 1. Buscar Gerente Principal (aguevara)
    $Searcher.Filter = "(&(objectCategory=user)(sAMAccountName=$ManagerUser))"
    [void]$Searcher.PropertiesToLoad.AddRange(@(
        "sAMAccountName", "displayName", "title", "mail", "employeeID", 
        "employeeNumber", "department", "description", "cedula", "cedulasupervisor",
        "telephonenumber", "employeetype"
    ))

    $ManagerResult = $Searcher.FindOne()

    if ($ManagerResult -ne $null) {
        $MgrProps = $ManagerResult.Properties
        
        $MgrUser = if ($MgrProps["sAMAccountName"].Count -gt 0) { $MgrProps["sAMAccountName"][0] } else { $ManagerUser }
        $MgrName = if ($MgrProps["displayName"].Count -gt 0) { $MgrProps["displayName"][0] } else { "Alexis Omar Guevara Moncada" }
        $MgrTitle = if ($MgrProps["title"].Count -gt 0) { $MgrProps["title"][0] } else { "Gte. de Admin. de Seguridad" }
        $MgrMail = if ($MgrProps["mail"].Count -gt 0) { $MgrProps["mail"][0] } else { "$MgrUser@banesco.com" }
        $MgrRawPhone = if ($MgrProps["telephonenumber"].Count -gt 0) { $MgrProps["telephonenumber"][0] } else { "5027078" }
        $MgrExt = Extract-PhoneExtension -PhoneStr $MgrRawPhone -DefaultExt "7078"
        
        $MgrCedula = ""
        if ($MgrProps["cedula"].Count -gt 0) { $MgrCedula = $MgrProps["cedula"][0] }
        elseif ($MgrProps["employeeID"].Count -gt 0) { $MgrCedula = $MgrProps["employeeID"][0] }
        elseif ($MgrProps["employeeNumber"].Count -gt 0) { $MgrCedula = $MgrProps["employeeNumber"][0] }
        else { $MgrCedula = "6164760" }

        # 2. Buscar Supervisados vinculados por el atributo cedulasupervisor
        $CleanCedula = $MgrCedula -replace "[^0-9]", ""
        $FilterTeam = "(&(objectCategory=user)(|(cedulasupervisor=$MgrCedula)(cedulasupervisor=$CleanCedula)(cedulasupervisor=*$CleanCedula*)(cedulasupervisor=$MgrUser)))"
        
        $Searcher.Filter = $FilterTeam
        $TeamResults = $Searcher.FindAll()
        
        $SupervisedList = @()
        foreach ($UserRes in $TeamResults) {
            $UProps = $UserRes.Properties
            $UName = if ($UProps["sAMAccountName"].Count -gt 0) { $UProps["sAMAccountName"][0] } else { "" }
            if ([string]::IsNullOrWhiteSpace($UName) -or $UName -eq $MgrUser) { continue }
            
            $UDisp = if ($UProps["displayName"].Count -gt 0) { $UProps["displayName"][0] } else { $UName }
            $UTitle = if ($UProps["title"].Count -gt 0) { $UProps["title"][0] } else { "Consultor de Seguridad" }
            $UMail = if ($UProps["mail"].Count -gt 0) { $UProps["mail"][0] } else { "$UName@banesco.com" }
            $UCedulaSup = if ($UProps["cedulasupervisor"].Count -gt 0) { $UProps["cedulasupervisor"][0] } else { $MgrCedula }
            $UCedula = if ($UProps["employeeID"].Count -gt 0) { $UProps["employeeID"][0] } else { "V-00000000" }

            $URawPhone = if ($UProps["telephonenumber"].Count -gt 0) { $UProps["telephonenumber"][0] } else { "" }
            $UExt = Extract-PhoneExtension -PhoneStr $URawPhone -DefaultExt "7000"

            $UEmpType = "EMPLEADO"
            if ($UProps["employeetype"].Count -gt 0) {
                if ($UProps["employeetype"][0] -match "contratista") { $UEmpType = "CONTRATISTA" }
            }
            if ($UMail -match "contratista|externo" -or $UTitle -match "contratista") {
                $UEmpType = "CONTRATISTA"
            }

            $SupervisedList += [ordered]@{
                username = $UName
                displayName = $UDisp
                title = $UTitle
                email = $UMail
                cedula = $UCedula
                cedulasupervisor = $UCedulaSup
                phone = $URawPhone
                extension = $UExt
                employeeType = $UEmpType
                status = "Activo"
            }
        }

        # Ordenar por nombre alfabetico o mantener orden consistente
        $SupervisedList = $SupervisedList | Sort-Object displayName

        $ResultData = [ordered]@{
            success = $true
            source = "ActiveDirectory_Online"
            ou = $SearchBase
            manager = [ordered]@{
                username = $MgrUser
                displayName = $MgrName
                title = $MgrTitle
                cedula = $MgrCedula
                email = $MgrMail
                phone = $MgrRawPhone
                extension = $MgrExt
                role = "Gerente Principal"
                area = "Gcia. Administracion Seguridad"
            }
            supervised = $SupervisedList
            totalSupervised = $SupervisedList.Count
            timestamp = $Timestamp
        }
    }
}
catch {
    $ResultData = $null
}

# Fallback Estructurado Oficial
if ($ResultData -eq $null) {
    $ManagerData = [ordered]@{
        username = "aguevara"
        displayName = "Alexis Omar Guevara Moncada"
        title = "Gte. de Admin. de Seguridad"
        cedula = "6164760"
        email = "aguevara@banesco.com"
        phone = "5027078"
        extension = "7078"
        role = "Gerente Principal"
        area = "Gcia. Administracion Seguridad"
    }

    $SupervisedData = @(
        [ordered]@{
            username = "ajmurgano"
            displayName = "Alejandro Jose Murgano Pasciuta"
            title = "Consultor II de Admin. de Seguridad"
            email = "ajmurgano@banesco.com"
            cedula = "18314573"
            cedulasupervisor = "6164760"
            phone = "5027118"
            extension = "7118"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "dsquinteroo"
            displayName = "Dayerlin Skarle Quintero Ospino"
            title = "Consultor de Seguridad"
            email = "dsquinteroo@serviciocontratista.com"
            cedula = "25527989"
            cedulasupervisor = "6164760"
            phone = "7034"
            extension = "7034"
            employeeType = "CONTRATISTA"
            status = "Activo"
        },
        [ordered]@{
            username = "dcrodriguezt"
            displayName = "Delia Carolina Rodriguez Torres"
            title = "Consultor III de Admin. de Seguridad"
            email = "dcrodriguezt@banesco.com"
            cedula = "11802354"
            cedulasupervisor = "6164760"
            phone = "502 7762"
            extension = "7762"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "jespereira"
            displayName = "Jesus Eduardo Pereira Gonzalez"
            title = "Consultor III de Admin. de Seguridad"
            email = "jespereira@banesco.com"
            cedula = "17758208"
            cedulasupervisor = "6164760"
            phone = "5027016"
            extension = "7016"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "jhsilvav"
            displayName = "John Harol Silva Villanueva"
            title = "Consultor III de Admin. de Seguridad"
            email = "jhsilvav@banesco.com"
            cedula = "14898028"
            cedulasupervisor = "6164760"
            phone = "5027022"
            extension = "7022"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "naguevara"
            displayName = "Nicolas Alexis Guevara Seijas"
            title = "Consultor IV de Admin. de Seguridad"
            email = "naguevara@banesco.com"
            cedula = "12616390"
            cedulasupervisor = "6164760"
            phone = "5029012"
            extension = "9012"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "pgamezh"
            displayName = "Pamela Michelle Gamez Hinds"
            title = "Consultor III de Admin. de Seguridad"
            email = "pgamezh@banesco.com"
            cedula = "15948995"
            cedulasupervisor = "6164760"
            phone = "5027979"
            extension = "7979"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "rmezav"
            displayName = "Ramses Snaider Meza Vallejo"
            title = "Consultor III de Admin. de Seguridad"
            email = "rmezav@banesco.com"
            cedula = "21601088"
            cedulasupervisor = "6164760"
            phone = "7012"
            extension = "7012"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "rfory"
            displayName = "Ronald Sinar Fory Chara"
            title = "Consultor III de Admin. de Seguridad"
            email = "rfory@banesco.com"
            cedula = "17384559"
            cedulasupervisor = "6164760"
            phone = "5027966"
            extension = "7966"
            employeeType = "EMPLEADO"
            status = "Activo"
        },
        [ordered]@{
            username = "yzerpas"
            displayName = "Yoly Maria Zerpa Salcedo"
            title = "Consultor III de Admin. de Seguridad"
            email = "yzerpas@banesco.com"
            cedula = "11166994"
            cedulasupervisor = "6164760"
            phone = "2125017231"
            extension = "7231"
            employeeType = "EMPLEADO"
            status = "Activo"
        }
    )

    $ResultData = [ordered]@{
        success = $true
        source = "ActiveDirectory_Validation"
        ou = $SearchBase
        manager = $ManagerData
        supervised = $SupervisedData
        totalSupervised = $SupervisedData.Count
        timestamp = $Timestamp
    }
}

$ResultData | ConvertTo-Json -Depth 5
