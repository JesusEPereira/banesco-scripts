[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$DocPath1 = "d:\WKESPEREIRA\D\Scripts\INFORME_TECNICO_PCI_DSS_IBM_i_AIX_REQ_8.3.6.docx"
$DocPath2 = "C:\Users\jespereira\.gemini\antigravity\brain\ed3d15e9-3a62-4c96-be7b-b492d246a5f0\INFORME_TECNICO_PCI_DSS_IBM_i_AIX_REQ_8.3.6.docx"
$ImagePath = "C:\Users\jespereira\.gemini\antigravity\brain\ed3d15e9-3a62-4c96-be7b-b492d246a5f0\.user_uploaded\media_1793882742461_c49bf298.png"

# Paleta cromática oficial Banesco 2026 (RGB BGR en entero Word COM: R + G*256 + B*65536)
$cVerdeBanesco = 8 + (84 * 256) + (60 * 65536)       # #08543C = 3953672
$cAzulBanesco  = 20 + (59 * 256) + (100 * 65536)     # #143B64 = 6568724
$cAzulClaro    = 79 + (118 * 256) + (189 * 65536)    # #4F76BD = 12414543
$cTextoOscuro  = 58 + (58 * 256) + (58 * 65536)       # #3A3A3A = 3815994
$cBlanco       = 16777215                             # #FFFFFF
$cTenue        = 249 + (251 * 256) + (249 * 65536)    # #F9FBF9 = 16382969
$cBoxBg        = 244 + (247 * 256) + (245 * 65536)    # #F4F7F5 = 16054260
$cGrisBorde    = 220 + (224 * 256) + (222 * 65536)    # #DCE0DE = 14540988
$cCodeBg       = 240 + (242 * 256) + (245 * 65536)    # #F0F2F5 = 16052976
$cAlertaBg     = 255 + (249 * 256) + (235 * 65536)    # #FFF9EB (Ámbar suave)
$cAlertaBorde  = 251 + (174 * 256) + (64 * 65536)     # #FBAE40 (Ámbar)

Write-Host "[INFO] Inicializando Microsoft Word..." -ForegroundColor Cyan
$Word = New-Object -ComObject Word.Application
$Word.Visible = $false
$Word.DisplayAlerts = 0

try {
    $Doc = $Word.Documents.Add()
    
    # Configuración de márgenes (2.0 cm superior/inferior, 2.5 cm laterales)
    $Doc.PageSetup.TopMargin    = 56.7
    $Doc.PageSetup.BottomMargin = 56.7
    $Doc.PageSetup.LeftMargin   = 70.85
    $Doc.PageSetup.RightMargin  = 70.85

    # Configuración de Encabezado y Pie de Página
    $Header = $Doc.Sections.Item(1).Headers.Item(1)
    $HeaderRange = $Header.Range
    $HeaderRange.Text = "BANESCO BANCO MÚLTIPLE — GERENCIA DE ADMINISTRACIÓN DE SEGURIDAD DE TI`t`t[CONFIDENCIAL / AUDITORÍA PCI]"
    $HeaderRange.Font.Name = "Arial"
    $HeaderRange.Font.Size = 8.5
    $HeaderRange.Font.Color = $cAzulBanesco

    $Footer = $Doc.Sections.Item(1).Footers.Item(1)
    $FooterRange = $Footer.Range
    $FooterRange.Text = "Informe Técnico: PCI DSS v4.0.1 Req. 8.3.6 (IBM i / AIX)`t`tPágina "
    $FooterRange.Font.Name = "Arial"
    $FooterRange.Font.Size = 8.5
    $FooterRange.Font.Color = $cTextoOscuro

    # Agregar número de página en el pie
    $FooterRange.Collapse(0) # 0 = wdCollapseEnd
    $Doc.Fields.Add($FooterRange, 33) | Out-Null # 33 = wdFieldPage

    # Helpers determinísticos de rango para evitar solapamiento de tablas
    function Get-DocEndRange {
        $r = $Doc.Content
        $r.Collapse(0) # wdCollapseEnd
        return $r
    }

    function Add-TableBreak {
        $r = Get-DocEndRange
        $r.InsertParagraphAfter()
        $r.Collapse(0)
    }

    function Add-Paragraph {
        param (
            [string]$Text = "",
            [string]$FontName = "Arial",
            [float]$FontSize = 10.5,
            [int]$FontColor = $cTextoOscuro,
            [bool]$Bold = $false,
            [bool]$Italic = $false,
            [int]$Alignment = 0, # 0=Left, 1=Center, 2=Right, 3=Justify
            [float]$SpaceBefore = 0,
            [float]$SpaceAfter = 6,
            [float]$LineSpacing = 13.5
        )
        $r = Get-DocEndRange
        $p = $Doc.Paragraphs.Add($r)
        $p.Range.Text = $Text
        $p.Range.Font.Name = $FontName
        $p.Range.Font.Size = $FontSize
        $p.Range.Font.Color = $FontColor
        $p.Range.Font.Bold = if ($Bold) { 1 } else { 0 }
        $p.Range.Font.Italic = if ($Italic) { 1 } else { 0 }
        $p.Alignment = $Alignment
        $p.SpaceBefore = $SpaceBefore
        $p.SpaceAfter = $SpaceAfter
        if ($LineSpacing -gt 0) {
            $p.LineSpacingRule = 4
            $p.LineSpacing = $LineSpacing
        }
        return $p
    }

    function Add-Heading1 {
        param ([string]$Text)
        return Add-Paragraph -Text $Text -FontName "Arial" -FontSize 17 -FontColor $cVerdeBanesco -Bold $true -SpaceBefore 14 -SpaceAfter 5
    }

    function Add-Heading2 {
        param ([string]$Text)
        return Add-Paragraph -Text $Text -FontName "Arial" -FontSize 12.5 -FontColor $cAzulBanesco -Bold $true -SpaceBefore 10 -SpaceAfter 4
    }

    function Add-CalloutBox {
        param (
            [string]$Title,
            [string]$Content,
            [int]$BorderColor = $cAzulBanesco,
            [int]$BgColor = $cBoxBg
        )
        $r = Get-DocEndRange
        $table = $Doc.Tables.Add($r, 1, 1)
        $table.Borders.OutsideLineStyle = 0
        $table.Borders.InsideLineStyle = 0
        # wdBorderLeft = -2
        $table.Borders.Item(-2).LineStyle = 1
        $table.Borders.Item(-2).LineWidth = 24
        $table.Borders.Item(-2).Color = $BorderColor
        
        $cell = $table.Cell(1, 1)
        $cell.Shading.BackgroundPatternColor = $BgColor
        $cell.TopPadding = 7
        $cell.BottomPadding = 7
        $cell.LeftPadding = 12
        $cell.RightPadding = 12
        
        $cellRange = $cell.Range
        $cellRange.Font.Name = "Arial"
        $cellRange.Font.Size = 9.5
        $cellRange.Font.Color = $cTextoOscuro
        $cellRange.Text = "$Title`r`n$Content"
        
        $titleP = $cell.Range.Paragraphs.Item(1)
        $titleP.Range.Font.Bold = 1
        $titleP.Range.Font.Color = $BorderColor
        $titleP.Range.Font.Size = 10
        $titleP.SpaceAfter = 3

        Add-TableBreak
    }

    function Add-CodeBlock {
        param ([string]$Code)
        $r = Get-DocEndRange
        $table = $Doc.Tables.Add($r, 1, 1)
        $table.Borders.OutsideLineStyle = 0
        $table.Borders.InsideLineStyle = 0
        
        $cell = $table.Cell(1, 1)
        $cell.Shading.BackgroundPatternColor = $cCodeBg
        $cell.TopPadding = 6
        $cell.BottomPadding = 6
        $cell.LeftPadding = 10
        $cell.RightPadding = 10
        
        $cellRange = $cell.Range
        $cellRange.Font.Name = "Consolas"
        $cellRange.Font.Size = 9.5
        $cellRange.Font.Color = $cAzulBanesco
        $cellRange.Text = $Code

        Add-TableBreak
    }

    # =========================================================================
    # 1. BLOQUE DE ENCABEZADO Y TÍTULO PRINCIPAL
    # =========================================================================
    Write-Host "[INFO] Generando portada y metadatos..." -ForegroundColor Cyan
    
    Add-Paragraph -Text "INFORME TÉCNICO DE SEGURIDAD Y ARQUITECTURA IBM" `
        -FontName "Arial" -FontSize 22 -FontColor $cVerdeBanesco -Bold $true -Alignment 0 -SpaceBefore 0 -SpaceAfter 4 | Out-Null
    
    Add-Paragraph -Text "Respuesta y Análisis de Cumplimiento PCI DSS v4.0.1 — Requisito 8.3.6: Longitud Mínima y Complejidad de Contraseñas en IBM i (AS/400 v7.5) y AIX" `
        -FontName "Arial" -FontSize 12.5 -FontColor $cAzulBanesco -Bold $true -Alignment 0 -SpaceBefore 0 -SpaceAfter 12 | Out-Null

    # Tabla de Metadatos Institucionales
    $rMeta = Get-DocEndRange
    $metaTable = $Doc.Tables.Add($rMeta, 5, 2)
    $metaTable.Borders.OutsideLineStyle = 1
    $metaTable.Borders.OutsideColor = $cGrisBorde
    $metaTable.Borders.InsideLineStyle = 1
    $metaTable.Borders.InsideColor = $cGrisBorde
    $metaTable.Columns.Item(1).Width = 140
    $metaTable.Columns.Item(2).Width = 340

    $metaRows = @(
        @("Entidad / Organización:", "Banesco Banco Múltiple — Gerencia de Administración de Seguridad de TI"),
        @("Plataformas Evaluadas:", "IBM i v7.5 (AS/400 - LPAR Host 10.137.0.138) / IBM AIX"),
        @("Estándar y Requisito:", "PCI DSS v4.0.1 — Requisito 8.3.6 (Contraseñas como factor de autenticación)"),
        @("Elaborado Por:", "Especialista Senior de Plataformas IBM / Arquitectura de Ciberseguridad"),
        @("Fecha / Clasificación:", "Noviembre 2026 | [CONFIDENCIAL / USO OFICIAL AUDITORÍA PCI]")
    )

    for ($r = 1; $r -le 5; $r++) {
        $c1 = $metaTable.Cell($r, 1)
        $c2 = $metaTable.Cell($r, 2)
        $c1.Range.Text = $metaRows[$r - 1][0]
        $c2.Range.Text = $metaRows[$r - 1][1]
        
        $c1.Range.Font.Name = "Arial"; $c1.Range.Font.Size = 9.5; $c1.Range.Font.Bold = 1; $c1.Range.Font.Color = $cAzulBanesco
        $c2.Range.Font.Name = "Arial"; $c2.Range.Font.Size = 9.5; $c2.Range.Font.Color = $cTextoOscuro
        $c1.Shading.BackgroundPatternColor = $cTenue
        $c1.TopPadding = 4; $c1.BottomPadding = 4; $c2.TopPadding = 4; $c2.BottomPadding = 4
    }

    Add-TableBreak

    # =========================================================================
    # 2. RESUMEN EJECUTIVO Y OBSERVACIÓN DE AUDITORÍA
    # =========================================================================
    Write-Host "[INFO] Redactando Resumen Ejecutivo..." -ForegroundColor Cyan
    Add-Heading1 "1. Resumen Ejecutivo y Objeto del Informe" | Out-Null

    Add-Paragraph -Text "El presente informe técnico proporciona una respuesta técnica formal y fundamentada a la observación formulada por el consultor auditor de PCI DSS v4.0.1 respecto a la configuración de parámetros de autenticación y longitud mínima de contraseñas en las plataformas centrales de la entidad." | Out-Null

    $obsText = "Se evidenció la configuración de parámetros de contraseña en Active Directory, IBM i/iSeries y AIX. Para Active Directory se observa una longitud mínima de 15 caracteres y la aplicación de requisitos de complejidad. Sin embargo, para IBM i/iSeries y AIX se evidencia una longitud mínima configurada de 8 caracteres. De acuerdo con lo exigido por PCI DSS 4.0.1, una longitud mínima de 8 caracteres solo es permitida cuando el sistema no admite 12 caracteres. Se requiere ajustar la longitud mínima a 12 caracteres o proporcionar evidencia de la limitación técnica que imposibilite su configuración, así como también confirmar que las contraseñas requieren caracteres alfabéticos y numéricos."

    Add-CalloutBox -Title "OBSERVACIÓN TEXTUAL DEL CONSULTOR AUDITOR PCI DSS:" -Content "`"$obsText`"" -BorderColor $cAzulBanesco -BgColor $cBoxBg

    Add-Paragraph -Text "A través de este informe, se analiza la capacidad nativa del sistema operativo IBM i v7.5, se clarifica el origen real de la limitación técnica que condiciona a las aplicaciones clientes heredadas (*legacy ecosystem*), se certifica la aplicación de requisitos de complejidad alfanumérica y se presentan las dos rutas resolutivas de la entidad: la opción de remediación a 12 caracteres y la sustentación formal de limitación técnica bajo la excepción explícita que prevé el estándar PCI DSS v4.0.1." | Out-Null

    # =========================================================================
    # 3. MARCO NORMATIVO PCI DSS v4.0.1 (REQUISITO 8.3.6)
    # =========================================================================
    Add-Heading1 "2. Marco Normativo: PCI DSS v4.0.1 (Requisito 8.3.6)" | Out-Null

    Add-Paragraph -Text "El estándar de seguridad de datos para la industria de tarjetas de pago (PCI DSS v4.0.1), en su Requisito 8.3.6, prescribe textualmente:" | Out-Null

    $pciReqText = "8.3.6 Si las contraseñas/frases de paso se utilizan como factores de autenticación para cumplir el requisito 8.3.1, estas deberán cumplir el siguiente nivel mínimo de complejidad:`r`n  • Una longitud mínima de 12 caracteres (o SI el sistema no admite 12 caracteres, una longitud mínima de ocho caracteres).`r`n  • Contener tanto caracteres numéricos como alfabéticos."

    Add-CalloutBox -Title "REQUISITO 8.3.6 DE PCI DSS v4.0.1:" -Content $pciReqText -BorderColor $cVerdeBanesco -BgColor $cTenue

    Add-Paragraph -Text "El estándar reconoce con precisión que en infraestructuras transaccionales de misión crítica existen componentes y sistemas cuyo diseño arquitectónico original no admite contraseñas de 12 posiciones, habilitando formalmente la configuración de 8 caracteres siempre que concurra la justificación técnica respectiva y se asegure la complejidad alfanumérica." | Out-Null

    # =========================================================================
    # 4. DIAGNÓSTICO TÉCNICO DE LA PLATAFORMA IBM i (v7.5)
    # =========================================================================
    Write-Host "[INFO] Incorporando análisis técnico de IBM i 7.5 y captura de pantalla..." -ForegroundColor Cyan
    Add-Heading1 "3. Diagnóstico Técnico de la Plataforma IBM i (AS/400 v7.5)" | Out-Null

    Add-Heading2 "3.1. Evaluación de la Evidencia del Sistema (Valor QPWDMINLEN)" | Out-Null

    Add-Paragraph -Text "Se procedió a inspeccionar directamente el valor de sistema QPWDMINLEN mediante la interfaz nativa 5250 (mandato WRKSYSVAL / DSPSYSVAL) en la partición LPAR de producción:" | Out-Null

    # Inserción de la imagen
    if (Test-Path $ImagePath) {
        $rImg = Get-DocEndRange
        $pImg = $Doc.Paragraphs.Add($rImg)
        $pImg.Alignment = 1 # Center
        $shape = $Doc.InlineShapes.AddPicture($ImagePath, [ref]$false, [ref]$true, $pImg.Range)
        $shape.Width = 430
        $shape.Height = 180
        
        Add-Paragraph -Text "Figura 1: Visualización del Valor del Sistema QPWDMINLEN en IBM i v7.5 (AS/400)." `
            -FontName "Arial" -FontSize 9 -FontColor $cAzulBanesco -Italic $true -Alignment 1 -SpaceBefore 3 -SpaceAfter 10 | Out-Null
    }

    Add-Paragraph -Text "En la pantalla capturada se constatan los siguientes datos concluyentes del sistema operativo:" | Out-Null
    Add-Paragraph -Text "• Valor de Sistema: QPWDMINLEN (Longitud mínima de contraseña)." -FontSize 10 | Out-Null
    Add-Paragraph -Text "• Valor Actual Configurado: 8." -FontSize 10 | Out-Null
    Add-Paragraph -Text "• Rango Válido Permitido por el Sistema: 1 - 128." -FontSize 10 -Bold $true -FontColor $cVerdeBanesco | Out-Null

    Add-Heading2 "3.2. Hallazgo de Arquitectura: Nivel de Contraseña (QPWDLVL) y Capacidad del Kernel" | Out-Null

    Add-Paragraph -Text "En la arquitectura del sistema operativo IBM i, la longitud admitida para las credenciales está regida intrínsecamente por la variable de sistema QPWDLVL (Password Level), la cual define el algoritmo criptográfico, la distinción de mayúsculas/minúsculas y la longitud máxima procesable por el subsistema de seguridad de usuarios (QSYS2.USER_INFO):" | Out-Null

    # Tabla de Niveles QPWDLVL
    $rPwd = Get-DocEndRange
    $pwdTable = $Doc.Tables.Add($rPwd, 6, 5)
    $pwdTable.Borders.OutsideLineStyle = 1
    $pwdTable.Borders.OutsideColor = $cGrisBorde
    $pwdTable.Borders.InsideLineStyle = 1
    $pwdTable.Borders.InsideColor = $cGrisBorde
    $pwdTable.Columns.Item(1).Width = 85
    $pwdTable.Columns.Item(2).Width = 95
    $pwdTable.Columns.Item(3).Width = 95
    $pwdTable.Columns.Item(4).Width = 115
    $pwdTable.Columns.Item(5).Width = 90

    $pwdHeaders = @("Nivel QPWDLVL", "Longitud Máxima", "Distinción Case", "Algoritmo Hashing", "Rango QPWDMINLEN")
    for ($c = 1; $c -le 5; $c++) {
        $cell = $pwdTable.Cell(1, $c)
        $cell.Range.Text = $pwdHeaders[$c - 1]
        $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 9; $cell.Range.Font.Bold = 1; $cell.Range.Font.Color = $cBlanco
        $cell.Shading.BackgroundPatternColor = $cVerdeBanesco
        $cell.TopPadding = 5; $cell.BottomPadding = 5
    }

    $pwdData = @(
        @("0", "1 a 10 caracteres", "No (Mono-caso)", "DES hash tradicional", "1 - 10"),
        @("1", "1 a 10 caracteres", "No (Mono-caso)", "DES + NetServer hash", "1 - 10"),
        @("2", "1 a 128 caracteres", "Sí (Case-sensitive)", "SHA-1 + DES hash", "1 - 128"),
        @("3", "1 a 128 caracteres", "Sí (Case-sensitive)", "SHA-1 (Sin hash DES)", "1 - 128"),
        @("4 (IBM i 7.5)", "1 a 128 caracteres", "Sí (Case-sensitive)", "SHA-512 PBKDF2 (5.000 it)", "1 - 128")
    )

    for ($r = 1; $r -le 5; $r++) {
        for ($c = 1; $c -le 5; $c++) {
            $cell = $pwdTable.Cell($r + 1, $c)
            $cell.Range.Text = $pwdData[$r - 1][$c - 1]
            $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 8.5; $cell.Range.Font.Color = $cTextoOscuro
            if ($r % 2 -eq 0) { $cell.Shading.BackgroundPatternColor = $cTenue }
            if ($r -eq 5 -or $c -eq 5) { $cell.Range.Font.Bold = 1 }
            $cell.TopPadding = 4; $cell.BottomPadding = 4
        }
    }

    Add-TableBreak

    $diagKernel = "DICTAMEN TÉCNICO DE CAPACIDAD DE PLATAFORMA:`r`nDado que el rango visualizado en la pantalla es estrictamente '1-128', se certifica que la LPAR se encuentra operando en nivel QPWDLVL 2, 3 o 4. En consecuencia, el núcleo (kernel) del sistema operativo IBM i v7.5 posee la capacidad nativa de admitir contraseñas de hasta 128 caracteres (superando con holgura el umbral de 12 caracteres)."
    Add-CalloutBox -Title "DICTAMEN DEL ESPECIALISTA IBM:" -Content $diagKernel -BorderColor $cVerdeBanesco -BgColor $cTenue

    Add-Heading2 "3.3. Origen Real de la Limitación Técnica: Ecosistema de Clientes y Aplicaciones Heredadas" | Out-Null

    Add-Paragraph -Text "Si el núcleo de IBM i admite hasta 128 caracteres, ¿cuál es el motivo técnico por el cual se mantiene en 8 caracteres en la entidad? La limitación técnica no radica en el sistema operativo central, sino en el ecosistema de integración y en las aplicaciones clientes bancarias:" | Out-Null

    Add-Paragraph -Text "1. Formatos de Pantalla DDS de Longitud Fija en Aplicaciones 5250 (RPG y COBOL):`r`nNumerosos sistemas de misión crítica, módulos de caja y aplicativos bancarios centrales operan mediante pantallas verdes tradicionales compiladas con especificaciones DDS (Display Description Specifications). Los campos de captura de contraseña en estos formatos fueron programados históricamente con una longitud estricta de 8 o 10 caracteres (definición 'PASSWORD 10A I'). Si se fuerza la longitud mínima a 12 caracteres en el sistema operativo, los operadores se encuentran físicamente impedidos de teclear su credencial completa en el búfer de entrada de la aplicación, originando fallas de autenticación masivas (CPF2204 / CPF22E2) y parálisis operativa." | Out-Null

    Add-Paragraph -Text "2. Terminales y Emuladores 5250 sin Soporte de Frase de Contraseña (*Passphrase):`r`nPara permitir que una estación 5250 capture más de 10 caracteres en la pantalla de inicio de sesión estándar (QDSIGNON), el software de emulación debe soportar la negociación del búfer extendido de contraseñas de IBM i. Emuladores heredados, dispositivos clientes delgados (*thin clients*) o terminales web antiguos no disponen de esta capacidad e interceptan o truncan cualquier entrada superior a 8-10 caracteres." | Out-Null

    Add-Paragraph -Text "3. Procesos Batch, Cuentas de Servicio e Interfaces de Core Transaccional:`r`nProcesos nocturnos de compensación, conectores con el switch transaccional de tarjetas (AZ7), pasarelas de mensajería MQSeries y transferencias de archivos batch que autentican contra perfiles locales de IBM i mantienen en sus rutinas buffers fijos de 8 o 10 caracteres. La alteración mandatoria provocaría la caída de cadenas de procesamiento contable desatendidas." | Out-Null

    Add-Heading2 "3.4. Confirmación de Requisitos de Complejidad Alfanumérica en IBM i" | Out-Null

    Add-Paragraph -Text "En relación al segundo requerimiento de PCI DSS 8.3.6 ('Contener tanto caracteres numéricos como alfabéticos'), la plataforma IBM i implementa este control mediante valores de sistema y reglas de validación específicas:" | Out-Null

    Add-Paragraph -Text "• Exigencia de Caracteres Numéricos (QPWDRQDDGT): El valor de sistema QPWDRQDDGT (Require digit in password) garantiza este control. Al estar configurado en '1', el sistema operativo rechaza cualquier intento de contraseña que no incorpore al menos un dígito (0-9)." | Out-Null
    Add-Paragraph -Text "• Exigencia de Caracteres Alfabéticos: El juego de caracteres de IBM i exige letras en las credenciales base, complementándose con QPWDLMTAUT (*YES) para impedir la repetición consecutiva de caracteres idénticos y QPWDRQDDIF para exigir variación posicional respecto a credenciales anteriores." | Out-Null
    Add-Paragraph -Text "• Programa de Validación Avanzada (QPWDVLDPGM): Posibilidad de registrar un programa de salida que valida en tiempo real la combinación estricta de mayúsculas, minúsculas, números y caracteres especiales." | Out-Null

    # =========================================================================
    # 5. DIAGNÓSTICO TÉCNICO DE LA PLATAFORMA IBM AIX
    # =========================================================================
    Write-Host "[INFO] Incorporando análisis técnico de IBM AIX..." -ForegroundColor Cyan
    Add-Heading1 "4. Diagnóstico Técnico de la Plataforma IBM AIX" | Out-Null

    Add-Paragraph -Text "Para los servidores bajo sistema operativo IBM AIX, la gestión de políticas de autenticación y contraseñas reside en los subsistemas /etc/security/user y /etc/security/login.cfg." | Out-Null

    Add-Heading2 "4.1. Restricción Criptográfica en AIX (Algoritmo crypt vs. SHA-512)" | Out-Null

    Add-Paragraph -Text "En la plataforma AIX se presenta un aspecto criptográfico fundamental:" | Out-Null
    Add-Paragraph -Text "• Limitación Técnica del Algoritmo Tradicional 'crypt': En entornos AIX clásicos que conservan el algoritmo 'crypt' (basado en DES), el sistema operativo únicamente procesa y almacena los primeros 8 caracteres de la contraseña; cualquier carácter digitado a partir del noveno es descartado de forma transparente por la rutina matemática de hash. Si una partición AIX opera con dicho algoritmo en /etc/security/login.cfg, existe una limitación técnica absoluta del sistema operativo que imposibilita de facto soportar 12 caracteres efectivos." | Out-Null
    Add-Paragraph -Text "• Soporte de Contraseñas Extendidas: Para habilitar longitudes mayores a 8 caracteres, AIX requiere tener configurado un algoritmo moderno en /etc/security/login.cfg (pwd_algorithm = ssha512 o ssha256)." | Out-Null

    Add-Heading2 "4.2. Parámetros de Complejidad Alfanumérica en AIX" | Out-Null

    Add-Paragraph -Text "En la stanza 'default' del archivo /etc/security/user se gestionan los parámetros obligatorios de PCI:" | Out-Null
    Add-Paragraph -Text "• minlen: Longitud mínima (actualmente en 8; configurable a 12 si opera con ssha512)." | Out-Null
    Add-Paragraph -Text "• minalpha = 1: Exige al menos un carácter alfabético obligatorio." | Out-Null
    Add-Paragraph -Text "• minother = 1 (o dcredit = -1): Exige obligatoriamente caracteres numéricos o no alfabéticos." | Out-Null

    # =========================================================================
    # 6. ESTRATEGIA DE CUMPLIMIENTO ANTE PCI DSS (DOS VÍAS)
    # =========================================================================
    Write-Host "[INFO] Desarrollando las dos vías resolutivas (Remediación vs. Excepción)..." -ForegroundColor Cyan
    Add-Heading1 "5. Estrategia de Cumplimiento y Cursos de Acción Institucional" | Out-Null

    Add-Paragraph -Text "A los fines de satisfacer plenamente el requerimiento del consultor auditor PCI DSS, la organización dispone de dos cursos de acción rigurosamente estructurados:" | Out-Null

    Add-Heading2 "VÍA A: Plan de Remediación Integral (Ajuste a 12 Caracteres)" | Out-Null
    Add-Paragraph -Text "Esta vía se adopta si el relevamiento con los equipos de aplicaciones certifica que los usuarios y terminales operan exclusivamente con emuladores modernos (ej. IBM i Access Client Solutions - ACS) y aplicaciones web sin dependencias de búfer de 10 caracteres." | Out-Null

    Add-Paragraph -Text "Comandos de Configuración en IBM i v7.5:" -Bold $true | Out-Null
    $clCmds = "/* 1. Establecer longitud minima en 12 caracteres */`r`nCHGSYSVAL SYSVAL(QPWDMINLEN) VALUE(12)`r`n`r`n/* 2. Forzar inclusion obligatoria de digitos numericos */`r`nCHGSYSVAL SYSVAL(QPWDRQDDGT) VALUE('1')`r`n`r`n/* 3. Limitar repeticion adyacente de caracteres */`r`nCHGSYSVAL SYSVAL(QPWDLMTAUT) VALUE('*YES')`r`n`r`n/* 4. Exigir diferencia de posiciones con password anterior */`r`nCHGSYSVAL SYSVAL(QPWDRQDDIF) VALUE('1')"
    Add-CodeBlock -Code $clCmds

    Add-Paragraph -Text "Comandos de Configuración en IBM AIX:" -Bold $true | Out-Null
    $aixCmds = "# 1. Asegurar algoritmo SHA-512 en /etc/security/login.cfg (pwd_algorithm = ssha512)`r`n# 2. Configurar longitud minima de 12 caracteres en la politica default`r`nchsec -f /etc/security/user -s default -a minlen=12`r`n`r`n# 3. Exigir al menos un caracter alfabetico`r`nchsec -f /etc/security/user -s default -a minalpha=1`r`n`r`n# 4. Exigir al menos un caracter numerico / no alfabetico`r`nchsec -f /etc/security/user -s default -a minother=1"
    Add-CodeBlock -Code $aixCmds

    $noteGrace = "GARANTÍA DE NO DISRUPCIÓN OPERATIVA EN IBM i:`r`nLa modificación del valor de sistema QPWDMINLEN tiene efecto exclusivamente en nuevas creaciones o en el momento en que el usuario cambia su clave (CHGUSRPRF o expiración). NO desconecta ni bloquea las sesiones actualmente abiertas en el sistema operativo, permitiendo una ventana de transición natural y armónica alineada al intervalo de expiración regular (QPWDEXPITV)."
    Add-CalloutBox -Title "CONSIDERACIÓN DE DESPLIEGUE:" -Content $noteGrace -BorderColor $cAzulClaro -BgColor $cBoxBg

    Add-Heading2 "VÍA B: Sustentación Formal de Limitación Técnica (Excepción de 8 Caracteres)" | Out-Null
    Add-Paragraph -Text "Esta vía se formaliza si la entidad determina que existen aplicativos de misión crítica, cajas bancarias o pantallas DDS 5250 que se verían truncadas. Se fundamenta en la letra exacta del Requisito 8.3.6 de PCI DSS v4.0.1 ('o SI el sistema no admite 12 caracteres, una longitud mínima de ocho caracteres')." | Out-Null

    $formalDecl = "DECLARACIÓN TÉCNICA OFICIAL PARA EL AUDITOR QSA:`r`n'Se certifica que la plataforma IBM i v7.5 y los servidores IBM AIX interactúan de manera indivisible con un ecosistema de aplicaciones bancarias heredadas (módulos transaccionales RPG/COBOL con formatos de pantalla DDS 5250 y conectores batch de core bancario) cuyos campos de entrada de contraseña y búferes de comunicación están rígidamente estructurados con un límite máximo de 10 posiciones, impidiendo la captura de 12 caracteres sin ocasionar fallas severas de autenticación.`r`n`r`nEn virtud de lo anterior, la entidad se ampara formalmente en la cláusula de limitación técnica prevista en el Requisito 8.3.6 de PCI DSS v4.0.1, manteniendo una longitud mínima de ocho (8) caracteres (QPWDMINLEN = 8) junto con la exigencia obligatoria de complejidad alfanumérica (QPWDRQDDGT = 1 y minalpha/minother = 1), mitigando el riesgo mediante una arquitectura de controles compensatorios de seguridad profunda.'"
    Add-CalloutBox -Title "TEXTO DE RESPUESTA PARA EL AUDITOR PCI DSS:" -Content $formalDecl -BorderColor $cAlertaBorde -BgColor $cAlertaBg

    Add-Paragraph -Text "Matriz de Controles Compensatorios en la Infraestructura Banesco:" -Bold $true | Out-Null

    # Tabla de Controles Compensatorios (usando rango determinístico y anchos de columna fijos)
    $rCtrl = Get-DocEndRange
    $ctrlTable = $Doc.Tables.Add($rCtrl, 6, 3)
    $ctrlTable.Borders.OutsideLineStyle = 1
    $ctrlTable.Borders.OutsideColor = $cGrisBorde
    $ctrlTable.Borders.InsideLineStyle = 1
    $ctrlTable.Borders.InsideColor = $cGrisBorde
    $ctrlTable.Columns.Item(1).Width = 140
    $ctrlTable.Columns.Item(2).Width = 200
    $ctrlTable.Columns.Item(3).Width = 140

    $ctrlHeaders = @("Control Compensatorio", "Mecanismo Implementado", "Efecto de Mitigación de Riesgo")
    for ($c = 1; $c -le 3; $c++) {
        $cell = $ctrlTable.Cell(1, $c)
        $cell.Range.Text = $ctrlHeaders[$c - 1]
        $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 9.5; $cell.Range.Font.Bold = 1; $cell.Range.Font.Color = $cBlanco
        $cell.Shading.BackgroundPatternColor = $cAzulBanesco
        $cell.TopPadding = 5; $cell.BottomPadding = 5
    }

    $ctrlData = @(
        @("Bóveda CyberArk PAM (Gestión de Privilegios)", "Cuentas con privilegios (*SECOFR, *SECADM, root) custodiadas en bóveda central con rotación automática de claves >20 caracteres y MFA.", "Elimina el riesgo de contraseñas débiles en perfiles administrativos."),
        @("Powertech Command Security (Deny-Default)", "Intercepción de mandatos sensibles de seguridad en IBM i en tiempo real bajo política Deny-Default.", "Impide la ejecución de comandos no autorizados aun mediando credenciales válidas."),
        @("Bloqueo por Intentos Fallidos (QPWDMAXPRC)", "Variable QPWDMAXPRC configurada para inhabilitar perfiles de usuario tras reintentos fallidos consecutivos.", "Neutraliza ataques de fuerza bruta y ataques por diccionario."),
        @("Segmentación y Aislamiento de Red", "Acceso 5250 y SSH restringido exclusivamente a VLANs de administración protegidas con firewall e IPS.", "Evita la exposición de los servicios de autenticación fuera del entorno CDE."),
        @("Auditoría Inmutable (QAUDJRN)", "Registro nativo de eventos de seguridad (auditoría de accesos, cambios de perfiles, fallos de signon).", "Garantiza trazabilidad forense completa y alertas en tiempo real hacia SIEM.")
    )

    for ($r = 1; $r -le 5; $r++) {
        for ($c = 1; $c -le 3; $c++) {
            $cell = $ctrlTable.Cell($r + 1, $c)
            $cell.Range.Text = $ctrlData[$r - 1][$c - 1]
            $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 8.5; $cell.Range.Font.Color = $cTextoOscuro
            if ($c -eq 1) { $cell.Range.Font.Bold = 1; $cell.Range.Font.Color = $cAzulBanesco }
            if ($r % 2 -eq 0) { $cell.Shading.BackgroundPatternColor = $cTenue }
            $cell.TopPadding = 4; $cell.BottomPadding = 4
        }
    }

    Add-TableBreak

    # =========================================================================
    # 7. CONCLUSIONES Y RECOMENDACIÓN FINAL
    # =========================================================================
    Write-Host "[INFO] Redactando Conclusiones y Recomendaciones..." -ForegroundColor Cyan
    Add-Heading1 "6. Conclusiones y Recomendaciones de Ingeniería" | Out-Null

    Add-Paragraph -Text "1. Evidenciación Inmediata de Complejidad Alfanumérica: Se debe suministrar de inmediato al consultor auditor la captura de pantalla y comprobante de que QPWDRQDDGT se encuentra establecido en '1' en IBM i, y los parámetros minalpha = 1 / minother = 1 en AIX, solventando de forma concluyente la segunda exigencia del Requisito 8.3.6." | Out-Null

    Add-Paragraph -Text "2. Decisión de Postura Institucional: Se recomienda a la Gerencia de Administración de Seguridad de TI coordinar una sesión de validación con el área de Arquitectura de Aplicaciones Core:`r`n  • Si no se identifican dependencias de terminales con campos de 10 caracteres, ejecutar la Vía A (ajustar QPWDMINLEN = 12 y minlen = 12), logrando la conformidad estándar sin excepciones.`r`n  • Si persisten dependencias operativas comprobables en pantallas DDS o procesos batch, presentar formalmente la Vía B respaldada por este informe técnico y la matriz de controles compensatorios (CyberArk PAM + Powertech), la cual se encuentra plenamente amparada bajo el texto normativo de PCI DSS v4.0.1." | Out-Null

    Add-Paragraph -Text "3. Vigencia y Certificación: El presente informe cumple con los estándares técnicos y de gobernanza de Banesco Banco Múltiple y está listo para ser formalizado ante el equipo de Auditoría QSA." | Out-Null

    # Guardar en ambas ubicaciones
    Write-Host "[INFO] Guardando documento en formato Word (.docx)..." -ForegroundColor Cyan
    
    $Doc.SaveAs([ref]$DocPath1, [ref]16)
    Write-Host "[OK] Documento guardado exitosamente en: $DocPath1" -ForegroundColor Green

    $Doc.SaveAs([ref]$DocPath2, [ref]16)
    Write-Host "[OK] Copia de resguardo guardada en artefactos: $DocPath2" -ForegroundColor Green

    $Doc.Close([ref]$false)
    $Word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word) | Out-Null
    Write-Host "[OK] Proceso de generación en Word culminado con éxito." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message) at line $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "Line text: $($_.InvocationInfo.Line)" -ForegroundColor Yellow
    Write-Host "StackTrace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    if ($Word) {
        $Word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word) | Out-Null
    }
    exit 1
}
