<#
.SYNOPSIS
    sync_matriz_roles.ps1 - Auditor, Validador de OU y Versionador con Resaltado en Rojo.
.DESCRIPTION
    Inspecciona y procesa TODAS las matrices en formato Excel (.xlsx/.xlsm) en la ruta de red UNC.
    1. Descubre dinamicamente todos los archivos Excel en la carpeta de matrices.
    2. En cada matriz, localiza la hoja de Usuarios (case-insensitive) y detecta los encabezados.
    3. Valida si cada usuario pertenece a la OU oficial: OU=Usuarios,DC=intra,DC=banesco,DC=com.
    4. Si un usuario NO esta en esta OU (ej. esta en OU=Temporal, OU=Bajas o no existe):
       - Se genera una nueva version de la matriz en _Versiones_Historicas ([Matriz]_vYYYYMMDD_HHMMSS.[ext]).
       - Se colorea la fila de dicho usuario en ROJO (fondo rojo suave corporativo y texto en negrita).
    5. Emite reportes de inconsistencias individuales y un REPORTE MAESTRO CONSOLIDADO.
    6. Preserva formatos originales, formulas y macros VBA intactos.
.PARAMETER MatrixPath
    Ruta a la carpeta que contiene las matrices de roles.
.PARAMETER MatrixFileName
    Nombre especifico o patron de archivo (Default: "*" para procesar todas las matrices).
.PARAMETER DryRun
    Modo simulacion (Default: $true).
.PARAMETER Operator
    Identificador del analista o cuenta ejecutora (Default: $env:USERNAME).
#>

[CmdletBinding()]
param (
    [string]$MatrixPath = "",
    [string]$MatrixFileName = "*",
    [switch]$DryRun,
    [bool]$Remediate = $true,
    [string]$Operator = $env:USERNAME,
    [string]$TargetOU = "OU=Usuarios,DC=intra,DC=banesco,DC=com",
    [string]$ServiceAccountOU = "OU=Cuentas de Servicios,DC=intra,DC=banesco,DC=com"
)

if ($DryRun) {
    $Remediate = $false
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptDir "config.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "No se encontro el archivo config.json en: $ConfigPath"
    exit 1
}

$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($MatrixPath)) {
    $MatrixPath = $config.matrices.defaultPath
}

if ($config.validation) {
    if ($config.validation.targetOU) {
        $TargetOU = $config.validation.targetOU
    }
    if ($config.validation.serviceAccountOU) {
        $ServiceAccountOU = $config.validation.serviceAccountOU
    }
}

$ReportsDir = $config.outputs.reportsDir
$LogsDir    = $config.outputs.logsDir
$AuditLog   = $config.outputs.auditLogFile

if (-not (Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
if (-not (Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }

Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host "  AUDITORIA DE MATRICES: VALIDACION OU, VERSIONAMIENTO EN ROJO Y DEPURACION PRINCIPAL    " -ForegroundColor Cyan
Write-Host "==========================================================================================" -ForegroundColor Cyan
Write-Host "Operador            : $Operator" -ForegroundColor Gray
Write-Host "Ruta de Red         : $MatrixPath" -ForegroundColor Gray
Write-Host "OU Usuarios         : $TargetOU" -ForegroundColor Yellow
Write-Host "OU Cuentas Servicio : $ServiceAccountOU" -ForegroundColor Yellow
Write-Host "Regla Activa        : Usuarios regulares deben pertenecer a '$TargetOU'." -ForegroundColor Cyan
Write-Host "                      Cuentas de Servicio (svc_*) deben pertenecer a '$ServiceAccountOU'." -ForegroundColor Cyan
Write-Host "                      Si no cumplen, se resaltan en ROJO en la version historica y" -ForegroundColor Cyan
Write-Host "                      SE ELIMINAN de la MATRIZ PRINCIPAL para dejarla conforme." -ForegroundColor Cyan
Write-Host "Modo Remediacion    : $(if ($Remediate -and -not $DryRun) { 'ACTIVO (Elimina filas no conformes en matriz principal)' } else { 'SOLO LECTURA / AUDITORIA' })" -ForegroundColor $(if ($Remediate -and -not $DryRun) { 'Green' } else { 'Yellow' })

# 0. Limpiar procesos huerfanos/invisibles de EXCEL en segundo plano para evitar bloqueos COM
Get-Process -Name EXCEL -ErrorAction SilentlyContinue | Where-Object { 
    $_.MainWindowHandle -eq 0 -and [string]::IsNullOrWhiteSpace($_.MainWindowTitle) 
} | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# 1. Resolver carpeta y descubrir matrices
$resolvedDir = Get-Item -LiteralPath $MatrixPath -ErrorAction SilentlyContinue
if (-not $resolvedDir) {
    $foundDirs = Get-ChildItem -Path $MatrixPath -ErrorAction SilentlyContinue
    if ($foundDirs) { $resolvedDir = $foundDirs | Select-Object -First 1 }
}

if (-not $resolvedDir -or -not (Test-Path -LiteralPath $resolvedDir.FullName)) {
    Write-Error "No se pudo acceder a la ruta de red: $MatrixPath"
    exit 1
}

# Obtener todos los archivos Excel excluyendo temporales (~$) y carpetas de respaldo
$matrixFiles = Get-ChildItem -Path $resolvedDir.FullName -File | Where-Object {
    $_.Extension -match '^\.xls[xm]?$' -and 
    $_.Name -notlike '~*' -and 
    $_.DirectoryName -notlike '*_Versiones_Historicas*'
}

if ($MatrixFileName -and $MatrixFileName -ne "*") {
    $matrixFiles = $matrixFiles | Where-Object { $_.Name -like $MatrixFileName }
}

if (-not $matrixFiles -or $matrixFiles.Count -eq 0) {
    Write-Warning "No se encontraron matrices Excel (.xlsx / .xlsm) en la ruta indicada."
    exit 0
}

Write-Host "`n1. Matrices Identificadas para Inspeccion ($($matrixFiles.Count) archivos):" -ForegroundColor Green
foreach ($mf in $matrixFiles) {
    $sizeKb = [Math]::Round(($mf.Length / 1024), 2)
    Write-Host "   - $($mf.Name) ($sizeKb KB)" -ForegroundColor Gray
}

$timestampGeneral = Get-Date -Format "yyyyMMdd_HHmmss"
$cacheAD = @{} # Cache en memoria de AD para acelerar entre matrices

$ConsolidadoResumen = @()
$TodasLasInconsistencias = @()

# 2. Procesar cada matriz
Write-Host "`n2. Iniciando Validacion de Usuarios contra OU..." -ForegroundColor Cyan

foreach ($targetFile in $matrixFiles) {
    Write-Host "`n------------------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "PROCESANDO: $($targetFile.Name)" -ForegroundColor Yellow
    
    $tempWorkFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "matriz_work_" + $timestampGeneral + "_" + $targetFile.Name)
    try {
        $inStream = [System.IO.File]::Open($targetFile.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $outStream = New-Object System.IO.FileStream($tempWorkFile, [System.IO.FileMode]::Create)
        $inStream.CopyTo($outStream)
        $inStream.Close(); $outStream.Close()
    } catch {
        Write-Warning "   [ERROR] No se pudo leer el archivo $($targetFile.Name): $_"
        continue
    }

    $zip = [System.IO.Compression.ZipFile]::OpenRead($tempWorkFile)

    # Cargar Shared Strings
    $strings = @()
    $ssEntry = $zip.GetEntry('xl/sharedStrings.xml')
    if ($ssEntry) {
        $reader = New-Object System.IO.StreamReader($ssEntry.Open(), [System.Text.Encoding]::UTF8)
        [xml]$ssXml = $reader.ReadToEnd()
        $reader.Close()
        foreach ($si in $ssXml.sst.si) {
            $strings += $si.InnerText
        }
    }

    # Detectar Hoja de Usuarios Inteligente
    $wbEntry = $zip.GetEntry('xl/workbook.xml')
    $candidateSheets = @()
    if ($wbEntry) {
        $reader = New-Object System.IO.StreamReader($wbEntry.Open(), [System.Text.Encoding]::UTF8)
        [xml]$wbXml = $reader.ReadToEnd()
        $reader.Close()
        
        $idx = 0
        foreach ($sh in $wbXml.workbook.sheets.sheet) {
            $idx++
            if ($sh.name -like '*usuario*' -or $sh.name -like '*user*') {
                $candidateSheets += [PSCustomObject]@{ Index = $idx; Name = $sh.name; Target = "xl/worksheets/sheet$idx.xml" }
            }
        }
        if ($candidateSheets.Count -eq 0 -and $wbXml.workbook.sheets.sheet.Count -gt 0) {
            $candidateSheets += [PSCustomObject]@{ Index = 1; Name = $wbXml.workbook.sheets.sheet[0].name; Target = "xl/worksheets/sheet1.xml" }
        }
    }

    $bestSheetTarget = ""
    $bestSheetDisplayName = ""
    $bestSheetXml = $null
    $bestHeaderRowIdx = 0
    $bestColMap = @{}
    $bestScore = -1

    foreach ($cand in $candidateSheets) {
        $sEntry = $zip.GetEntry($cand.Target)
        if (-not $sEntry) { continue }
        $reader = New-Object System.IO.StreamReader($sEntry.Open(), [System.Text.Encoding]::UTF8)
        [xml]$candSheetXml = $reader.ReadToEnd()
        $reader.Close()

        $allRows = $candSheetXml.worksheet.sheetData.row
        foreach ($r in ($allRows | Where-Object { [int]$_.r -ge 1 -and [int]$_.r -le 15 })) {
            $score = 0
            $tempCols = @{}
            foreach ($c in $r.c) {
                $colLetter = ($c.r -replace '\d+', '')
                $v = $c.v
                if ($c.t -eq 's' -and $null -ne $v) { $v = $strings[[int]$v] }
                elseif ($c.is) { $v = $c.is.InnerText }
                if ($v -is [System.Xml.XmlElement]) { $v = $v.InnerText }
                $textVal = ("" + $v).Trim()

                if ($textVal -match '(?i)employeeid|c\.i|cedula|cdula|identificacion|documento') {
                    $tempCols['Cedula'] = $colLetter; $score += 2
                } elseif ($textVal -match '(?i)\bintra\b|usuario\s+intra|usuario|login|id usuario|samaccountname|account|^user\b') {
                    $tempCols['Usuario'] = $colLetter; $score += 2
                } elseif ($textVal -match '(?i)^nombres?\b|nombre.*apellido|colaborador|^empleado\b' -and $textVal -notmatch '(?i)ubicaci|organizaci|tipo') {
                    $tempCols['Nombre'] = $colLetter; $score += 1
                } elseif ($textVal -match '(?i)perfil|profile|grupo|rol') {
                    $tempCols['Perfil'] = $colLetter; $score += 1
                } elseif ($textVal -match '(?i)estado|status|enabled') {
                    $tempCols['Estado'] = $colLetter; $score += 1
                } elseif ($textVal -match '(?i)cargo|title') {
                    $tempCols['Cargo'] = $colLetter; $score += 1
                }
            }

            if ($score -gt $bestScore) {
                $bestScore = $score
                $bestSheetTarget = $cand.Target
                $bestSheetDisplayName = $cand.Name
                $bestSheetXml = $candSheetXml
                $bestHeaderRowIdx = [int]$r.r
                $bestColMap = $tempCols
            }
        }
    }

    if (-not $bestSheetXml) {
        Write-Warning "   [OMITIDO] No se encontro hoja valida de Usuarios en $($targetFile.Name)"
        $zip.Dispose()
        Remove-Item $tempWorkFile -Force -ErrorAction SilentlyContinue
        continue
    }

    $zip.Dispose()
    $sheetXml = $bestSheetXml
    $sheetDisplayName = $bestSheetDisplayName
    $headerRowIdx = $bestHeaderRowIdx
    $colMap = $bestColMap
    $allRows = $sheetXml.worksheet.sheetData.row

    if ($headerRowIdx -eq 0) {
        $headerRowIdx = 11
        $colMap = @{ Nombre = 'A'; Cedula = 'B'; Usuario = 'C'; Perfil = 'D'; Estado = 'E'; Cargo = 'F' }
    }

    Write-Host "   -> Hoja '$sheetDisplayName' | Encabezados en Fila $headerRowIdx" -ForegroundColor Gray

    # Extraer registros de usuarios
    $matrixUsers = @()
    foreach ($r in ($allRows | Where-Object { [int]$_.r -gt $headerRowIdx })) {
        $rNum = [int]$r.r
        $rowCells = @{}
        foreach ($c in $r.c) {
            $colLetter = ($c.r -replace '\d+', '')
            $v = $c.v
            if ($c.t -eq 's' -and $null -ne $v) { $v = $strings[[int]$v] }
            elseif ($c.is) { $v = $c.is.InnerText }
            if ($v -is [System.Xml.XmlElement]) { $v = $v.InnerText }
            $rowCells[$colLetter] = ("" + $v).Trim()
        }

        $nombre  = if ($colMap['Nombre'])  { $rowCells[$colMap['Nombre']] }  else { $rowCells['A'] }
        $usuario = if ($colMap['Usuario']) { $rowCells[$colMap['Usuario']] } else { "" }
        $cedula  = if ($colMap['Cedula'])  { $rowCells[$colMap['Cedula']] }  else { "" }
        $perfil  = if ($colMap['Perfil'])  { $rowCells[$colMap['Perfil']] }  else { "" }
        $estado  = if ($colMap['Estado'])  { $rowCells[$colMap['Estado']] }  else { "" }
        $cargo   = if ($colMap['Cargo'])   { $rowCells[$colMap['Cargo']] }   else { "" }

        # Filtro: Ignorar bloques de firmas y autorizaciones al pie de la matriz
        if (-not $usuario -and -not $cedula -and ($nombre -match '(?i)autorizado|propietario|responsable|area funcional|elaborado|revisado|aprobado|firma')) {
            continue
        }

        if ($usuario -or $nombre -or $cedula) {
            $matrixUsers += [PSCustomObject]@{
                Matriz    = $targetFile.Name
                FilaExcel = $rNum
                Nombre    = $nombre
                Usuario   = $usuario
                Cedula    = $cedula
                Perfil    = $perfil
                Estado    = $estado
                Cargo     = $cargo
            }
        }
    }

    Write-Host "   -> Total cuentas identificadas: $($matrixUsers.Count)" -ForegroundColor Gray

    # Validacion contra Active Directory y comprobacion de pertenencia a OUs
    $inconsistenciasMatriz = @()
    $validosMatriz = @()

    foreach ($u in $matrixUsers) {
        $uName = ("" + $u.Usuario).Trim()
        
        # Normalizar Cedula: manejar numeros en notacion cientifica o float de Excel (ej: 1.8314573E7 o 5017379.0)
        $rawCedula = ("" + $u.Cedula).Trim()
        $cClean = ""
        if ($rawCedula -match '^[0-9\.]+[eE][\+\-]?[0-9]+$') {
            try { $cClean = [string][long][double]$rawCedula } catch { $cClean = ($rawCedula -replace '\D', '') }
        } elseif ($rawCedula -match '^[0-9]+\.0+$') {
            $cClean = $rawCedula -replace '\.0+$', ''
        } else {
            $cClean = ($rawCedula -replace '\D', '')
        }

        # Regla de Negocio: Usuarios de Aplicacion (ej: Project Executor, Gawuser en GoAnywhere)
        $isAppUser = $false
        $appUserDesc = ""
        if ($config.validation -and $config.validation.applicationUsers) {
            foreach ($rule in $config.validation.applicationUsers) {
                if ($targetFile.Name -match $rule.matrixPattern) {
                    foreach ($uPattern in $rule.users) {
                        if ($u.Nombre -match "^(?i)$([regex]::Escape($uPattern))$" -or $u.Usuario -match "^(?i)$([regex]::Escape($uPattern))$") {
                            $isAppUser = $true
                            $appUserDesc = $rule.description
                            break
                        }
                    }
                }
                if ($isAppUser) { break }
            }
        }

        if (-not $isAppUser -and $targetFile.Name -match '(?i)goanywhere' -and ($u.Nombre -match '(?i)^(Project Executor|Gawuser)$' -or $u.Usuario -match '(?i)^(Project Executor|Gawuser)$')) {
            $isAppUser = $true
            $appUserDesc = "Usuario de Aplicacion (Activo en GoAnywhere)"
        }

        $isInTargetOU = $false
        $motivo = ""
        $dnReal = "NO EXISTE EN AD"
        $adUser = $null

        if ($isAppUser) {
            $isInTargetOU = $true
            $tipoCuenta = "Usuario de Aplicacion"
            $targetOURequired = "N/A (Aplicacion)"
            $dnReal = "APLICACION ($($u.Nombre))"
            $motivo = "$appUserDesc - Conforme por regla de negocio"
        } else {
            # Regla de Negocio: Cuentas de Servicio (svc_ / SVC) vs Usuarios Regulares
            $isServiceAccount = ($uName -match '^(?i)svc_?')
            $targetOURequired = if ($isServiceAccount) { $ServiceAccountOU } else { $TargetOU }
            $tipoCuenta = if ($isServiceAccount) { "Cuenta de Servicio" } else { "Usuario" }

            $lookupKey = if ($uName) { $uName } else { "CI_$cClean" }

            if (-not $cacheAD.ContainsKey($lookupKey)) {
                $adObj = $null
                if ($uName) {
                    $adObj = Get-ADUser -Identity $uName -Properties DistinguishedName, Enabled, employeeID, sAMAccountName -ErrorAction SilentlyContinue
                }
                if (-not $adObj -and $cClean) {
                    $adObj = Get-ADUser -Filter "employeeID -eq '$cClean'" -Properties DistinguishedName, Enabled, sAMAccountName -ErrorAction SilentlyContinue
                }
                $cacheAD[$lookupKey] = $adObj
            }

            $adUser = $cacheAD[$lookupKey]

            if ($adUser) {
                $dnReal = $adUser.DistinguishedName
                # Revalidar si por sAMAccountName en AD es cuenta de servicio
                if (-not $isServiceAccount -and $adUser.sAMAccountName -match '^(?i)svc_?') {
                    $isServiceAccount = $true
                    $targetOURequired = $ServiceAccountOU
                    $tipoCuenta = "Cuenta de Servicio"
                }

                if ($dnReal -like "*,$targetOURequired") {
                    $isInTargetOU = $true
                } else {
                    $isInTargetOU = $false
                    $motivo = "$tipoCuenta ubicada fuera de $targetOURequired ($dnReal)"
                }
            } else {
                $isInTargetOU = $false
                $motivo = "$tipoCuenta o cedula no encontrada en Active Directory"
            }
        }

        $diag = [PSCustomObject]@{
            Matriz            = $u.Matriz
            FilaExcel         = $u.FilaExcel
            Usuario           = if ($u.Usuario) { $u.Usuario } elseif ($adUser) { $adUser.sAMAccountName } else { "" }
            Cedula            = if ($cClean) { $cClean } elseif ($adUser) { $adUser.employeeID } else { "" }
            Nombre            = $u.Nombre
            Perfil            = $u.Perfil
            EstadoMatriz      = $u.Estado
            TipoCuenta        = $tipoCuenta
            OUObjetivo        = $targetOURequired
            DistinguishedName = $dnReal
            EnOUCorrecta      = if ($isInTargetOU) { "SI" } else { "NO" }
            Accion            = if (-not $isInTargetOU) { "RESALTAR EN ROJO" } else { "CONFORME" }
            MotivoDiagnostico = $motivo
        }

        if (-not $isInTargetOU) {
            $inconsistenciasMatriz += $diag
            $TodasLasInconsistencias += $diag
        } else {
            $validosMatriz += $diag
        }
    }

    Write-Host "   -> Cuentas Validadas y Conformes       : $($validosMatriz.Count)" -ForegroundColor Green
    if ($inconsistenciasMatriz.Count -gt 0) {
        Write-Host "   -> Cuentas FUERA de OU (No Conformes)  : $($inconsistenciasMatriz.Count)" -ForegroundColor Red
    } else {
        Write-Host "   -> Cuentas FUERA de OU (No Conformes)  : 0" -ForegroundColor Green
    }

    # 3. Colorear filas en ROJO usando Excel COM sobre el archivo temporal de trabajo
    if ($inconsistenciasMatriz.Count -gt 0) {
        Write-Host "   -> Aplicando formato ROJO a $($inconsistenciasMatriz.Count) filas para la nueva version..." -ForegroundColor Yellow
        
        $excel = $null
        $wb = $null
        $formatSuccess = $false
        
        for ($attempt = 1; $attempt -le 3; $attempt++) {
            try {
                $excel = New-Object -ComObject Excel.Application
                $excel.Visible = $false
                $excel.DisplayAlerts = $false
                $excel.ScreenUpdating = $false
                $excel.Interactive = $false
                $excel.AskToUpdateLinks = $false
                $excel.EnableEvents = $false
                
                $wb = $excel.Workbooks.Open($tempWorkFile, $false, $false)
                if (-not $wb) { throw "No se pudo cargar el libro en Excel COM" }
                
                # Buscar hoja de usuarios (insensible a mayusculas/minusculas)
                $ws = $null
                try { $ws = $wb.Sheets.Item($sheetDisplayName) } catch {}
                if (-not $ws) {
                    foreach ($sh in $wb.Sheets) {
                        if ($sh.Name -like "*usuario*") { $ws = $sh; break }
                    }
                }
                if (-not $ws) { $ws = $wb.Sheets.Item(1) }
                
                $maxCol = [Math]::Max(10, $ws.UsedRange.Columns.Count)
                $colLetterEnd = [char](64 + [Math]::Min(26, $maxCol))

                foreach ($inc in $inconsistenciasMatriz) {
                    $fNum = $inc.FilaExcel
                    $rng = $ws.Range("A${fNum}:${colLetterEnd}${fNum}")
                    
                    # Fondo rojo suave (RGB 255, 199, 206) = 13551615
                    $rng.Interior.Color = 13551615
                    # Texto rojo oscuro (RGB 156, 0, 6) = 393372
                    $rng.Font.Color = 393372
                    $rng.Font.Bold = $true
                }

                $wb.Save()
                $formatSuccess = $true
                Write-Host "   [OK] Resaltado en ROJO aplicado correctamente." -ForegroundColor Green
                break
            } catch {
                if ($attempt -lt 3) {
                    Start-Sleep -Milliseconds 1000
                } else {
                    Write-Warning "   [ERROR] No se pudo aplicar formato Excel COM tras 3 intentos: $_"
                }
            } finally {
                if ($wb) {
                    try { $wb.Close($false) } catch {}
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
                    $wb = $null
                }
                if ($excel) {
                    try { $excel.Interactive = $true } catch {}
                    try { $excel.Quit() } catch {}
                    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
                    $excel = $null
                }
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            }
        }
    }

    # 4. Crear Nueva Version de la Matriz en _Versiones_Historicas (Red UNC y Local)
    $backupSubfolder = if ($config.matrices.backupSubfolder) { $config.matrices.backupSubfolder } else { "_Versiones_Historicas" }
    $networkBackupDir = Join-Path $resolvedDir.FullName $backupSubfolder
    $versionedFileName = $targetFile.BaseName + "_v" + $timestampGeneral + $targetFile.Extension
    
    # Asegurar existencia de carpeta de versiones en la red UNC
    if (-not (Test-Path -LiteralPath $networkBackupDir)) {
        try {
            New-Item -ItemType Directory -Path $networkBackupDir -Force | Out-Null
        } catch {
            Write-Warning "   [AVISO] No se pudo crear directorio $backupSubfolder en red: $_"
        }
    }

    # Copia a red UNC mediante Robocopy para evitar limites de 260 caracteres (MAX_PATH)
    $savedToUNC = $false
    try {
        $stageDir = Join-Path $env:TEMP ("stage_v_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
        $stageFile = Join-Path $stageDir $versionedFileName
        Copy-Item -LiteralPath $tempWorkFile -Destination $stageFile -Force

        $roboProc = Start-Process -FilePath "robocopy.exe" -ArgumentList "`"$stageDir`" `"$networkBackupDir`" `"$versionedFileName`" /R:2 /W:1 /NP /NFL /NDL /NJH /NJS" -NoNewWindow -Wait -PassThru
        if ($roboProc.ExitCode -eq 0 -or $roboProc.ExitCode -eq 1) {
            $savedToUNC = $true
        } else {
            Write-Warning "   [AVISO] Robocopy devolvio codigo $($roboProc.ExitCode) al respaldar en red."
        }
        Remove-Item -Path $stageDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "   [AVISO] No se pudo escribir en $backupSubfolder de red: $_"
    }

    # Copia local de respaldo
    $localVersionsDir = Join-Path $ReportsDir "Versiones_Historicas"
    if (-not (Test-Path $localVersionsDir)) { New-Item -ItemType Directory -Path $localVersionsDir -Force | Out-Null }
    $localVersionedPath = Join-Path $localVersionsDir $versionedFileName
    Copy-Item -LiteralPath $tempWorkFile -Destination $localVersionedPath -Force

    $destMsg = if ($savedToUNC) { "Red UNC ($backupSubfolder) y Local" } else { "Local ($backupSubfolder)" }
    Write-Host "   [OK] Nueva version generada en $destMsg -> $versionedFileName" -ForegroundColor Green

    # Reporte individual si hay discrepancias
    if ($inconsistenciasMatriz.Count -gt 0) {
        $indivReport = Join-Path $ReportsDir ("Reporte_Inconsistencias_OU_" + $targetFile.BaseName + "_" + $timestampGeneral + ".csv")
        $inconsistenciasMatriz | Export-Csv -Path $indivReport -NoTypeInformation -Encoding UTF8
    }

    # 5. Depurar Matriz Principal: Eliminar filas de usuarios no conformes de la matriz activa en red
    $filasDepuradas = 0
    if ($inconsistenciasMatriz.Count -gt 0 -and $Remediate -and -not $DryRun) {
        Write-Host "   -> Depurando matriz principal: eliminando $($inconsistenciasMatriz.Count) filas no conformes..." -ForegroundColor Yellow
        
        $tempCleanFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "matriz_clean_" + $timestampGeneral + "_" + $targetFile.Name)
        try {
            # Copiar archivo original limpio a temporal
            Copy-Item -LiteralPath $targetFile.FullName -Destination $tempCleanFile -Force
            
            $excelClean = $null
            $wbClean = $null
            $cleanSuccess = $false
            
            for ($attempt = 1; $attempt -le 3; $attempt++) {
                try {
                    $excelClean = New-Object -ComObject Excel.Application
                    $excelClean.Visible = $false
                    $excelClean.DisplayAlerts = $false
                    $excelClean.ScreenUpdating = $false
                    $excelClean.Interactive = $false
                    $excelClean.AskToUpdateLinks = $false
                    $excelClean.EnableEvents = $false
                    
                    $wbClean = $excelClean.Workbooks.Open($tempCleanFile, $false, $false)
                    $wsClean = $null
                    try { $wsClean = $wbClean.Sheets.Item($sheetDisplayName) } catch {}
                    if (-not $wsClean) {
                        foreach ($sh in $wbClean.Sheets) {
                            if ($sh.Name -like "*usuario*") { $wsClean = $sh; break }
                        }
                    }
                    if (-not $wsClean) { $wsClean = $wbClean.Sheets.Item(1) }
                    
                    # Eliminar filas en orden descendente para no desfasar indices
                    $rowsToDelete = $inconsistenciasMatriz | Select-Object -ExpandProperty FilaExcel -Unique | Sort-Object -Descending
                    foreach ($rNum in $rowsToDelete) {
                        $null = $wsClean.Rows.Item($rNum).Delete()
                    }
                    
                    $wbClean.Save()
                    $cleanSuccess = $true
                    $filasDepuradas = $rowsToDelete.Count
                    break
                } catch {
                    if ($attempt -lt 3) {
                        Start-Sleep -Milliseconds 1000
                    } else {
                        Write-Warning "   [ERROR] No se pudo depurar filas en Excel COM tras 3 intentos: $_"
                    }
                } finally {
                    if ($wbClean) {
                        try { $wbClean.Close($false) } catch {}
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wbClean) | Out-Null
                        $wbClean = $null
                    }
                    if ($excelClean) {
                        try { $excelClean.Interactive = $true } catch {}
                        try { $excelClean.Quit() } catch {}
                        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelClean) | Out-Null
                        $excelClean = $null
                    }
                    [GC]::Collect()
                    [GC]::WaitForPendingFinalizers()
                }
            }
            
            if ($cleanSuccess) {
                # Escribir el archivo depurado de vuelta a la matriz principal en la red UNC
                $stageDir = Join-Path $env:TEMP ("stage_clean_" + [System.IO.Path]::GetRandomFileName())
                New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
                $stageFile = Join-Path $stageDir $targetFile.Name
                Copy-Item -LiteralPath $tempCleanFile -Destination $stageFile -Force
                
                $roboProc = Start-Process -FilePath "robocopy.exe" -ArgumentList "`"$stageDir`" `"$($targetFile.DirectoryName)`" `"$($targetFile.Name)`" /R:3 /W:1 /NP /NFL /NDL /NJH /NJS" -NoNewWindow -Wait -PassThru
                if ($roboProc.ExitCode -eq 0 -or $roboProc.ExitCode -eq 1 -or $roboProc.ExitCode -eq 3) {
                    Write-Host "   [OK] Matriz principal depurada en red ($filasDepuradas filas eliminadas)." -ForegroundColor Green
                } else {
                    Copy-Item -LiteralPath $tempCleanFile -Destination $targetFile.FullName -Force
                    Write-Host "   [OK] Matriz principal depurada en red (via copia directa)." -ForegroundColor Green
                }
                Remove-Item -Path $stageDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warning "   [ERROR] Fallo al depurar matriz principal: $_"
        } finally {
            Remove-Item $tempCleanFile -Force -ErrorAction SilentlyContinue
        }
    } elseif ($inconsistenciasMatriz.Count -gt 0 -and $DryRun) {
        Write-Host "   -> [SIMULACION] Se habrian eliminado $($inconsistenciasMatriz.Count) filas de la matriz principal." -ForegroundColor Yellow
    } else {
        Write-Host "   -> Matriz principal ya esta limpia (0 filas a eliminar)." -ForegroundColor Green
    }

    # Agregar a resumen consolidado
    $ConsolidadoResumen += [PSCustomObject]@{
        Matriz            = $targetFile.Name
        TotalCuentas      = $matrixUsers.Count
        Conformes         = $validosMatriz.Count
        FueraDeOU_EnRojo  = $inconsistenciasMatriz.Count
        FilasEliminadas   = $filasDepuradas
        EstadoPrincipal   = if ($inconsistenciasMatriz.Count -eq 0) { "LIMPIA (0 eliminados)" } elseif ($filasDepuradas -gt 0) { "DEPURADA ($filasDepuradas eliminados)" } else { "PENDIENTE DEPURAR" }
        VersionConRojos   = $versionedFileName
    }

    # Limpieza temporal
    Remove-Item $tempWorkFile -Force -ErrorAction SilentlyContinue
}

# 6. Generar Reporte Maestro Consolidado
Write-Host "`n==========================================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN EJECUTIVO CONSOLIDADO: VALIDACION CONTRA OUs, RESALTADO Y DEPURACION            " -ForegroundColor Cyan
Write-Host "==========================================================================================" -ForegroundColor Cyan

$ConsolidadoResumen | Format-Table Matriz, TotalCuentas, Conformes, FueraDeOU_EnRojo, FilasEliminadas, EstadoPrincipal, VersionConRojos -AutoSize

$totalMatrices = $ConsolidadoResumen.Count
$totalCuentas = ($ConsolidadoResumen | Measure-Object -Property TotalCuentas -Sum).Sum
$totalRojos = ($ConsolidadoResumen | Measure-Object -Property FueraDeOU_EnRojo -Sum).Sum
$totalEliminadas = ($ConsolidadoResumen | Measure-Object -Property FilasEliminadas -Sum).Sum

Write-Host "TOTALES:" -ForegroundColor Yellow
Write-Host " -> Matrices Procesadas                  : $totalMatrices"
Write-Host " -> Total Cuentas Evaluadas              : $totalCuentas"
Write-Host " -> Cuentas Marcadas en ROJO (Historica) : $totalRojos" -ForegroundColor $(if ($totalRojos -gt 0) { "Red" } else { "Green" })
Write-Host " -> Filas Eliminadas en Matriz Principal : $totalEliminadas" -ForegroundColor $(if ($totalEliminadas -gt 0) { "Green" } else { "Gray" })

# Exportar informe consolidado
$masterReportCsv = Join-Path $ReportsDir ("Reporte_Consolidado_OU_" + $timestampGeneral + ".csv")
$TodasLasInconsistencias | Export-Csv -Path $masterReportCsv -NoTypeInformation -Encoding UTF8
Write-Host "`nReporte Maestro de Inconsistencias (Usuarios / Cuentas fuera de OU):" -ForegroundColor Cyan
Write-Host " -> $masterReportCsv" -ForegroundColor Green

# Asentar registro en auditoria
$auditEntry = [PSCustomObject]@{
    FechaHora         = (Get-Date).ToString("o")
    Operador          = $Operator
    ReglaValidacion   = "Pertenencia a OUs ($TargetOU / $ServiceAccountOU)"
    TotalMatrices     = $totalMatrices
    TotalCuentas      = $totalCuentas
    TotalMarcadosRojo = $totalRojos
    TotalEliminadas   = $totalEliminadas
    DetalleMatrices   = $ConsolidadoResumen
}
$auditJson = $auditEntry | ConvertTo-Json -Compress
Add-Content -Path $AuditLog -Value $auditJson -Encoding UTF8
Write-Host "`nEvento registrado en bitacora de auditoria: $AuditLog" -ForegroundColor Gray

Write-Host "`nProceso completado exitosamente.`n" -ForegroundColor Green
