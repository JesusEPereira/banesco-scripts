<#
.SYNOPSIS
    Script de Auditoria: Valida si una lista de usuarios (por sAMAccountName o employeeID/Cedula) 
    se encuentra ubicada en la OU "Temporal" de Active Directory.

.DESCRIPTION
    Permite ingresar usuarios por parametro, archivo CSV/TXT, o portapapeles.
    Verifica la pertenencia a la OU 'Temporal' (o sub-OUs dentro de Temporal).
    Soporta ejecucion mediante el modulo ActiveDirectory o fallback nativo ADSI LDAP.
    Genera salida enriquecida con colores en consola y exporta un reporte CSV en UTF-8.

.PARAMETER Usuarios
    Lista de nombres de usuario o IDs pasados directamente por consola.

.PARAMETER RutaArchivo
    Ruta a un archivo .txt (un usuario por linea) o .csv.

.PARAMETER Columna
    Nombre de la columna en el archivo CSV (si no se indica, autodetecta: employeeID, sAMAccountName, intra, cedula, etc.).

.PARAMETER Clipboard
    Lee la lista de usuarios directamente desde el portapapeles de Windows.

.PARAMETER RutaSalida
    Carpeta de destino para exportar el reporte CSV (por defecto el directorio actual del script).

.PARAMETER FiltroOU
    Texto a buscar en el DistinguishedName para identificar la OU (por defecto: 'OU=Temporal').

.EXAMPLE
    .\Validar_Usuarios_OU_Temporal.ps1 -Usuarios "ammartinezb", "jespereira", "19688632"

.EXAMPLE
    .\Validar_Usuarios_OU_Temporal.ps1 -RutaArchivo "D:\Scripts\PowerShell\ListarUsuariosCI\cruce.csv"

.EXAMPLE
    .\Validar_Usuarios_OU_Temporal.ps1 -Clipboard
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Usuarios,

    [Parameter()]
    [string]$RutaArchivo,

    [Parameter()]
    [string]$Columna,

    [Parameter()]
    [switch]$Clipboard,

    [Parameter()]
    [string]$RutaSalida = "",

    [Parameter()]
    [string]$FiltroOU = "OU=Temporal"
)

# Resolver ruta de salida por defecto si no se especifico
if ([string]::IsNullOrWhiteSpace($RutaSalida)) {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $RutaSalida = $PSScriptRoot
    } else {
        $RutaSalida = (Get-Location).Path
    }
}

# Configuracion de codificacion para salida en consola
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "     VALIDADOR DE USUARIOS EN LA OU TEMPORAL - ACTIVE DIRECTORY                " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ("Fecha / Hora: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor Gray
Write-Host ("Filtro OU objetivo: " + $FiltroOU + "`n") -ForegroundColor DarkCyan

# -----------------------------------------------------------------------------
# 1. Recoleccion de la lista de usuarios / identificadores
# -----------------------------------------------------------------------------
$listaEntrada = [System.Collections.Generic.List[string]]::new()

if ($Clipboard) {
    Write-Host "[*] Leyendo datos desde el portapapeles..." -ForegroundColor Cyan
    $clipData = Get-Clipboard
    if ($clipData) {
        foreach ($line in $clipData) {
            $val = $line.Trim()
            if (-not [string]::IsNullOrWhiteSpace($val)) {
                $listaEntrada.Add($val)
            }
        }
    }
}
elseif (-not [string]::IsNullOrWhiteSpace($RutaArchivo)) {
    if (Test-Path -Path $RutaArchivo) {
        Write-Host "[*] Leyendo archivo: $RutaArchivo" -ForegroundColor Cyan
        $extension = [System.IO.Path]::GetExtension($RutaArchivo).ToLower()
        if ($extension -eq ".csv") {
            $csvData = Import-Csv -Path $RutaArchivo
            if ($csvData.Count -gt 0) {
                # Determinar la columna
                $targetCol = $Columna
                if ([string]::IsNullOrWhiteSpace($targetCol)) {
                    $headers = $csvData[0].PSObject.Properties.Name
                    $colCandidates = @("employeeID", "employeeid", "cedula", "sAMAccountName", "samaccountname", "usuario", "user", "intra", "id", "login")
                    foreach ($c in $colCandidates) {
                        $found = $headers | Where-Object { $_ -eq $c }
                        if ($found) { $targetCol = $found; break }
                    }
                    if (-not $targetCol) {
                        $targetCol = $headers[0] # Primera columna por defecto
                    }
                }
                Write-Host "    -> Utilizando columna: '$targetCol'" -ForegroundColor Yellow
                foreach ($row in $csvData) {
                    $val = "$($row.$targetCol)".Trim()
                    if (-not [string]::IsNullOrWhiteSpace($val)) {
                        $listaEntrada.Add($val)
                    }
                }
            }
        } else {
            # Archivo de texto plano (uno por linea)
            Get-Content -Path $RutaArchivo | ForEach-Object {
                $val = $_.Trim()
                if (-not [string]::IsNullOrWhiteSpace($val)) {
                    $listaEntrada.Add($val)
                }
            }
        }
    } else {
        Write-Error "El archivo especificado no existe: $RutaArchivo"
        return
    }
}
elseif ($Usuarios -and $Usuarios.Count -gt 0) {
    foreach ($u in $Usuarios) {
        if (-not [string]::IsNullOrWhiteSpace($u)) {
            $tokens = $u -split "[,;\s]+"
            foreach ($t in $tokens) {
                if (-not [string]::IsNullOrWhiteSpace($t)) {
                    $listaEntrada.Add($t.Trim())
                }
            }
        }
    }
}
else {
    # Modo interactivo si no se paso ningun parametro
    Write-Host "[i] No se proporcionaron parametros directos." -ForegroundColor Yellow
    Write-Host "    Ingrese los usuarios o cedulas (uno por linea o separados por comas)." -ForegroundColor Gray
    Write-Host "    (Presione ENTER dos veces para iniciar la validacion):" -ForegroundColor Gray
    
    $inputBuffer = @()
    do {
        $in = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($in)) {
            $inputBuffer += ($in -split "[,;\t]")
        }
    } while (-not [string]::IsNullOrWhiteSpace($in))

    foreach ($item in $inputBuffer) {
        $val = $item.Trim()
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            $listaEntrada.Add($val)
        }
    }
}

# Filtrar duplicados manteniendo orden
$usuariosUnicos = $listaEntrada | Select-Object -Unique
$totalAConsultar = $usuariosUnicos.Count

if ($totalAConsultar -eq 0) {
    Write-Warning "No se ingreso ningun usuario o identificador para validar."
    return
}

Write-Host "[+] Total de registros unicos a consultar: $totalAConsultar`n" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 2. Funciones auxiliares de consulta Active Directory
# -----------------------------------------------------------------------------
function Parse-OUHierarchy ([string]$dn) {
    if ([string]::IsNullOrEmpty($dn)) { return "N/A" }
    $parts = $dn -split "," | Where-Object { $_ -like "OU=*" }
    if ($parts) {
        $cleanParts = $parts | ForEach-Object { $_ -replace "^OU=", "" }
        return ($cleanParts -join " / ")
    }
    return "Raiz del Dominio / Builtin"
}

# Detectar disponibilidad del modulo ActiveDirectory
$hasADModule = $false
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    if (Get-Command Get-ADUser -ErrorAction SilentlyContinue) {
        $hasADModule = $true
    }
}

# Si no hay modulo, preparar ADSI
$searcher = $null
if (-not $hasADModule) {
    Write-Warning "Modulo ActiveDirectory (RSAT) no detectado. Se utilizara ADSI LDAP nativo."
    $root = [ADSI]""
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($root)
    $searcher.PageSize = 1000
}

function Buscar-UsuarioAD ([string]$id) {
    $isNumeric = ($id -match '^\d+$')
    
    if ($hasADModule) {
        try {
            $adUser = $null
            if ($isNumeric) {
                # Probar primero como employeeID
                $adUser = Get-ADUser -Filter "employeeID -eq '$id'" -Properties DisplayName, Description, Enabled, DistinguishedName, title, company, employeeID, LastLogonDate -ErrorAction SilentlyContinue | Select-Object -First 1
                if (-not $adUser) {
                    $adUser = Get-ADUser -Filter "sAMAccountName -eq '$id'" -Properties DisplayName, Description, Enabled, DistinguishedName, title, company, employeeID, LastLogonDate -ErrorAction SilentlyContinue | Select-Object -First 1
                }
            } else {
                # Probar primero como sAMAccountName
                $adUser = Get-ADUser -Filter "sAMAccountName -eq '$id'" -Properties DisplayName, Description, Enabled, DistinguishedName, title, company, employeeID, LastLogonDate -ErrorAction SilentlyContinue | Select-Object -First 1
                if (-not $adUser) {
                    $adUser = Get-ADUser -Filter "employeeID -eq '$id' -or Name -eq '$id'" -Properties DisplayName, Description, Enabled, DistinguishedName, title, company, employeeID, LastLogonDate -ErrorAction SilentlyContinue | Select-Object -First 1
                }
            }

            if ($adUser) {
                return [PSCustomObject]@{
                    Encontrado        = $true
                    sAMAccountName    = $adUser.sAMAccountName
                    Nombre            = $adUser.DisplayName
                    EmployeeID        = $adUser.employeeID
                    Habilitado        = [bool]$adUser.Enabled
                    DistinguishedName = $adUser.DistinguishedName
                    Cargo             = $adUser.title
                    Empresa           = $adUser.company
                    UltimoLogon       = $adUser.LastLogonDate
                }
            }
        } catch {
            Write-Verbose "Error al buscar $id con Get-ADUser: $_"
        }
    } else {
        # Fallback ADSI
        try {
            if ($isNumeric) {
                $searcher.Filter = "(|(employeeID=$id)(sAMAccountName=$id))"
            } else {
                $searcher.Filter = "(|(sAMAccountName=$id)(employeeID=$id)(displayName=$id))"
            }
            $res = $searcher.FindOne()
            if ($res) {
                $entry = $res.GetDirectoryEntry()
                $uac = $entry.userAccountControl.Value
                $isDisabled = [bool]($uac -band 2)
                return [PSCustomObject]@{
                    Encontrado        = $true
                    sAMAccountName    = "$($entry.sAMAccountName.Value)"
                    Nombre            = "$($entry.displayName.Value)"
                    EmployeeID        = "$($entry.employeeID.Value)"
                    Habilitado        = (-not $isDisabled)
                    DistinguishedName = "$($entry.distinguishedName.Value)"
                    Cargo             = "$($entry.title.Value)"
                    Empresa           = "$($entry.company.Value)"
                    UltimoLogon       = $null
                }
            }
        } catch {
            Write-Verbose "Error al buscar $id con ADSI: $_"
        }
    }

    return [PSCustomObject]@{
        Encontrado        = $false
        sAMAccountName    = $null
        Nombre            = $null
        EmployeeID        = $null
        Habilitado        = $null
        DistinguishedName = $null
        Cargo             = $null
        Empresa           = $null
        UltimoLogon       = $null
    }
}

# -----------------------------------------------------------------------------
# 3. Procesamiento y evaluacion de usuarios
# -----------------------------------------------------------------------------
$resultados = [System.Collections.Generic.List[PSCustomObject]]::new()
$contador = 0
$enTemporalCount = 0
$otrasOUCount = 0
$noEncontradosCount = 0

Write-Host "Iniciando validacion..." -ForegroundColor Cyan
Write-Host ("-" * 105) -ForegroundColor DarkGray
Write-Host ("{0,-15} {1,-18} {2,-30} {3,-14} {4,-12} {5}" -f "CONSULTADO", "USUARIO AD", "NOMBRE COMPLETO", "ESTADO", "EN TEMPORAL", "RUTA OU") -ForegroundColor White
Write-Host ("-" * 105) -ForegroundColor DarkGray

foreach ($id in $usuariosUnicos) {
    $contador++
    $progreso = [math]::Round(($contador / $totalAConsultar) * 100, 1)
    Write-Progress -Activity "Validando cuentas en Directorio Activo" -Status "Procesando $id ($contador/$totalAConsultar - $progreso%)" -PercentComplete $progreso

    $adData = Buscar-UsuarioAD -id $id

    if ($adData.Encontrado) {
        $dn = $adData.DistinguishedName
        $estaEnTemporal = ($dn -like "*$FiltroOU*")
        $ouLegible = Parse-OUHierarchy -dn $dn
        $estadoCuenta = if ($adData.Habilitado) { "Habilitada" } else { "Deshabilitada" }

        if ($estaEnTemporal) {
            $enTemporalCount++
            $color = "Red"
            $tagTemp = "SI [ALERTA]"
        } else {
            $otrasOUCount++
            $color = "Green"
            $tagTemp = "NO"
        }

        # Formato de visualizacion recortando si es muy largo
        $dispNombre = if ($adData.Nombre) { $adData.Nombre } else { "N/A" }
        if ($dispNombre.Length -gt 28) { $dispNombre = $dispNombre.Substring(0, 25) + "..." }

        $dispOU = $ouLegible
        if ($dispOU.Length -gt 35) { $dispOU = $dispOU.Substring(0, 32) + "..." }

        Write-Host ("{0,-15} {1,-18} {2,-30} {3,-14} {4,-12} {5}" -f `
            $id, `
            $adData.sAMAccountName, `
            $dispNombre, `
            $estadoCuenta, `
            $tagTemp, `
            $dispOU) -ForegroundColor $color

        $resultados.Add([PSCustomObject]@{
            "Consultado"        = $id
            "EncontradoEnAD"    = "SI"
            "EstaEnTemporal"    = if ($estaEnTemporal) { "SI" } else { "NO" }
            "sAMAccountName"    = $adData.sAMAccountName
            "NombreCompleto"    = $adData.Nombre
            "EmployeeID"        = $adData.EmployeeID
            "EstadoCuenta"      = $estadoCuenta
            "OU_Jerarquia"      = $ouLegible
            "DistinguishedName" = $adData.DistinguishedName
            "Cargo"             = $adData.Cargo
            "Empresa"           = $adData.Empresa
            "UltimoLogon"       = if ($adData.UltimoLogon) { $adData.UltimoLogon.ToString("yyyy-MM-dd HH:mm:ss") } else { "N/A" }
        })
    } else {
        $noEncontradosCount++
        Write-Host ("{0,-15} {1,-18} {2,-30} {3,-14} {4,-12} {5}" -f `
            $id, `
            "---", `
            "NO EXISTE EN AD", `
            "N/A", `
            "NO", `
            "N/A") -ForegroundColor DarkYellow

        $resultados.Add([PSCustomObject]@{
            "Consultado"        = $id
            "EncontradoEnAD"    = "NO"
            "EstaEnTemporal"    = "NO"
            "sAMAccountName"    = "N/A"
            "NombreCompleto"    = "NO EXISTE EN DIRECTORIO ACTIVO"
            "EmployeeID"        = "N/A"
            "EstadoCuenta"      = "N/A"
            "OU_Jerarquia"      = "N/A"
            "DistinguishedName" = "N/A"
            "Cargo"             = "N/A"
            "Empresa"           = "N/A"
            "UltimoLogon"       = "N/A"
        })
    }
}

Write-Progress -Activity "Validando cuentas en Directorio Activo" -Completed
Write-Host ("-" * 105) -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# 4. Resumen Estadistico
# -----------------------------------------------------------------------------
Write-Host "`n========================= RESUMEN DE LA VALIDACION =========================" -ForegroundColor Cyan
Write-Host ("  Total Registros Evaluados       : {0}" -f $totalAConsultar) -ForegroundColor White
$alertaColor = if ($enTemporalCount -gt 0) { "Red" } else { "Green" }
Write-Host ("  [!] Usuarios en OU TEMPORAL     : {0}" -f $enTemporalCount) -ForegroundColor $alertaColor
Write-Host ("  [OK] Usuarios en Otras OUs       : {0}" -f $otrasOUCount) -ForegroundColor Green
$notFoundColor = if ($noEncontradosCount -gt 0) { "DarkYellow" } else { "Gray" }
Write-Host ("  [?] No Encontrados en AD        : {0}" -f $noEncontradosCount) -ForegroundColor $notFoundColor
Write-Host "============================================================================`n" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 5. Exportacion de Resultados
# -----------------------------------------------------------------------------
if (-not (Test-Path -Path $RutaSalida)) {
    New-Item -ItemType Directory -Path $RutaSalida -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archivoCSV = Join-Path $RutaSalida "Reporte_Validacion_OU_Temporal_$timestamp.csv"

# Exportar con codificacion UTF-8 con BOM para visualizacion en Excel
$utf8BOM = New-Object System.Text.UTF8Encoding($true)
$csvContent = $resultados | ConvertTo-Csv -NoTypeInformation -Delimiter ";"
[System.IO.File]::WriteAllLines($archivoCSV, $csvContent, $utf8BOM)

Write-Host "[OK] Reporte exportado exitosamente a:" -ForegroundColor Green
Write-Host ("     " + $archivoCSV + "`n") -ForegroundColor White

if ($enTemporalCount -gt 0) {
    Write-Host ("[ALERTA] Se detectaron " + $enTemporalCount + " usuarios dentro de la estructura '" + $FiltroOU + "'.") -ForegroundColor Red
    Write-Host "         Revise el archivo generado para tomar las acciones requeridas." -ForegroundColor Yellow
} else {
    Write-Host ("[COMPLETADO] Ninguno de los usuarios validados se encuentra en la OU '" + $FiltroOU + "'.") -ForegroundColor Green
}
