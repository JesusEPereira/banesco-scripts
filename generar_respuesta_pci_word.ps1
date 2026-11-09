[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$DocPath1 = "d:\WKESPEREIRA\D\Scripts\INFORME_TECNICO_RESPUESTA_PCI_LIMITACION_TECNICA.docx"
$DocPath2 = "C:\Users\jespereira\.gemini\antigravity\brain\ed3d15e9-3a62-4c96-be7b-b492d246a5f0\INFORME_TECNICO_RESPUESTA_PCI_LIMITACION_TECNICA.docx"

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
    
    # Márgenes ejecutivos (2.0 cm superior/inferior, 2.5 cm laterales)
    $Doc.PageSetup.TopMargin    = 56.7
    $Doc.PageSetup.BottomMargin = 56.7
    $Doc.PageSetup.LeftMargin   = 70.85
    $Doc.PageSetup.RightMargin  = 70.85

    # Encabezado
    $Header = $Doc.Sections.Item(1).Headers.Item(1)
    $HeaderRange = $Header.Range
    $HeaderRange.Text = "BANESCO BANCO MÚLTIPLE — GERENCIA DE ADMINISTRACIÓN DE SEGURIDAD DE TI`t`t[CONFIDENCIAL / AUDITORÍA PCI]"
    $HeaderRange.Font.Name = "Arial"
    $HeaderRange.Font.Size = 8.5
    $HeaderRange.Font.Color = $cAzulBanesco

    # Pie de Página
    $Footer = $Doc.Sections.Item(1).Footers.Item(1)
    $FooterRange = $Footer.Range
    $FooterRange.Text = "Sustentación Técnica de Limitación de Plataforma — PCI DSS v4.0.1 Req. 8.3.6`t`tPágina "
    $FooterRange.Font.Name = "Arial"
    $FooterRange.Font.Size = 8.5
    $FooterRange.Font.Color = $cTextoOscuro
    $FooterRange.Collapse(0)
    $Doc.Fields.Add($FooterRange, 33) | Out-Null # 33 = wdFieldPage

    # Helpers determinísticos de rango
    function Get-DocEndRange {
        $r = $Doc.Content
        $r.Collapse(0)
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
            [float]$FontSize = 10,
            [int]$FontColor = $cTextoOscuro,
            [bool]$Bold = $false,
            [bool]$Italic = $false,
            [int]$Alignment = 0,
            [float]$SpaceBefore = 0,
            [float]$SpaceAfter = 5,
            [float]$LineSpacing = 13
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
        return Add-Paragraph -Text $Text -FontName "Arial" -FontSize 15 -FontColor $cVerdeBanesco -Bold $true -SpaceBefore 12 -SpaceAfter 4
    }

    function Add-Heading2 {
        param ([string]$Text)
        return Add-Paragraph -Text $Text -FontName "Arial" -FontSize 12 -FontColor $cAzulBanesco -Bold $true -SpaceBefore 9 -SpaceAfter 3
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
        $cell.TopPadding = 6
        $cell.BottomPadding = 6
        $cell.LeftPadding = 11
        $cell.RightPadding = 11
        
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

    # =========================================================================
    # 1. BLOQUE DE ENCABEZADO Y METADATOS
    # =========================================================================
    Write-Host "[INFO] Generando portada y metadatos institucionales..." -ForegroundColor Cyan
    
    Add-Paragraph -Text "INFORME TÉCNICO OFICIAL DE RESPUESTA A AUDITORÍA PCI DSS v4.0.1" `
        -FontName "Arial" -FontSize 20 -FontColor $cVerdeBanesco -Bold $true -Alignment 0 -SpaceBefore 0 -SpaceAfter 3 | Out-Null
    
    Add-Paragraph -Text "Sustentación Técnica de Limitación de Plataforma y Controles Compensatorios — Requisito 8.3.6 (IBM i / AIX)" `
        -FontName "Arial" -FontSize 12 -FontColor $cAzulBanesco -Bold $true -Alignment 0 -SpaceBefore 0 -SpaceAfter 10 | Out-Null

    # Tabla de Metadatos
    $rMeta = Get-DocEndRange
    $metaTable = $Doc.Tables.Add($rMeta, 5, 2)
    $metaTable.Borders.OutsideLineStyle = 1
    $metaTable.Borders.OutsideColor = $cGrisBorde
    $metaTable.Borders.InsideLineStyle = 1
    $metaTable.Borders.InsideColor = $cGrisBorde
    $metaTable.Columns.Item(1).Width = 140
    $metaTable.Columns.Item(2).Width = 340

    $metaRows = @(
        @("Destinatario / Auditor:", "Equipo de Auditoría QSA PCI DSS / Consultoría de Seguridad"),
        @("Área Emisora / Especialidad:", "Gerencia de Administración de Seguridad de TI / Especialista Senior IBM"),
        @("Plataformas Evaluadas:", "IBM i v7.5 (AS/400 - LPAR Host 10.137.0.138) / IBM AIX"),
        @("Referencia Normativa:", "PCI DSS v4.0.1 — Requisito 8.3.6 (Nivel Mínimo de Longitud y Complejidad)"),
        @("Fecha / Clasificación:", "Noviembre 2026 | [CONFIDENCIAL / USO OFICIAL AUDITORÍA PCI]")
    )

    for ($r = 1; $r -le 5; $r++) {
        $c1 = $metaTable.Cell($r, 1)
        $c2 = $metaTable.Cell($r, 2)
        $c1.Range.Text = $metaRows[$r - 1][0]
        $c2.Range.Text = $metaRows[$r - 1][1]
        
        $c1.Range.Font.Name = "Arial"; $c1.Range.Font.Size = 9; $c1.Range.Font.Bold = 1; $c1.Range.Font.Color = $cAzulBanesco
        $c2.Range.Font.Name = "Arial"; $c2.Range.Font.Size = 9; $c2.Range.Font.Color = $cTextoOscuro
        $c1.Shading.BackgroundPatternColor = $cTenue
        $c1.TopPadding = 3.5; $c1.BottomPadding = 3.5; $c2.TopPadding = 3.5; $c2.BottomPadding = 3.5
    }

    Add-TableBreak

    # =========================================================================
    # 2. DECLARACIÓN FORMAL DE POSTURA INSTITUCIONAL
    # =========================================================================
    Write-Host "[INFO] Redactando Declaración Formal..." -ForegroundColor Cyan
    Add-Heading1 "1. Declaración Formal de Postura Institucional" | Out-Null

    Add-Paragraph -Text "En atención al hallazgo presentado por el consultor auditor de PCI DSS v4.0.1 relativo a la configuración de parámetros de autenticación en las plataformas IBM i (AS/400) e IBM AIX, la Gerencia de Administración de Seguridad de TI de Banesco Banco Múltiple formaliza la presente respuesta técnica institucional." | Out-Null

    $pciText = "8.3.6 Si las contraseñas/frases de paso se utilizan como factores de autenticación para cumplir el requisito 8.3.1, estas deberán cumplir el siguiente nivel mínimo de complejidad:`r`n  • Una longitud mínima de 12 caracteres (o SI el sistema no admite 12 caracteres, una longitud mínima de ocho caracteres).`r`n  • Contener tanto caracteres numéricos como alfabéticos."

    Add-CalloutBox -Title "TEXTO DEL REQUISITO 8.3.6 DE PCI DSS v4.0.1:" -Content $pciText -BorderColor $cVerdeBanesco -BgColor $cTenue

    $posturaText = "La entidad se acoge formalmente a la excepción expresa prevista en el Requisito 8.3.6 ('o SI el sistema no admite 12 caracteres, una longitud mínima de ocho caracteres'). Se certifica que la plataforma mantiene configurada una longitud mínima de ocho (8) caracteres (QPWDMINLEN = 8) junto con el cumplimiento mandatorio de caracteres alfabéticos y numéricos (QPWDRQDDGT = 1). A continuación, se sustentan las imposibilidades técnicas y operativas del ecosistema transaccional que impiden elevar este parámetro a 12 caracteres, respaldadas por una robusta arquitectura de controles compensatorios."
    Add-CalloutBox -Title "DICTAMEN INSTITUCIONAL Y SOLICITUD DE EXCEPCIÓN TÉCNICA:" -Content $posturaText -BorderColor $cAzulBanesco -BgColor $cBoxBg

    # =========================================================================
    # 3. FUNDAMENTACIÓN TÉCNICA DE LA IMPOSIBILIDAD DE CONFIGURAR 12 CARACTERES
    # =========================================================================
    Write-Host "[INFO] Documentando la imposibilidad técnica y ecosistema legacy..." -ForegroundColor Cyan
    Add-Heading1 "2. Fundamentación Técnica: Imposibilidad de Configuración a 12 Caracteres" | Out-Null

    Add-Paragraph -Text "Si bien a nivel de núcleo (kernel) del sistema operativo IBM i v7.5 existe capacidad de procesar frases de contraseña extendidas, fijar la longitud mínima en 12 caracteres (QPWDMINLEN = 12) resulta técnicamente inviable debido a las dependencias críticas e indivisibles del ecosistema de aplicaciones bancarias heredadas y canales transaccionales:" | Out-Null

    Add-Heading2 "2.1. Formatos de Pantalla DDS de 10 Posiciones Fijas en Aplicaciones Legacy (RPG y COBOL)" | Out-Null
    Add-Paragraph -Text "Módulos de misión crítica del core bancario, operativas de agencias y aplicaciones de ventanilla funcionan mediante pantallas tradicionales compiladas bajo especificaciones DDS (Display Description Specifications). En estas pantallas transaccionales, los campos de captura de contraseña fueron definidos históricamente con una longitud fija de 8 o 10 caracteres ('A 10 I' o 'A 8 I'). Si se eleva el parámetro del sistema operativo a 12 caracteres, los usuarios se encuentran físicamente impedidos de teclear su credencial completa en el búfer de entrada de la aplicación. Esto provocaría truncamiento involuntario, errores masivos de autenticación (CPF2204 / CPF22E2), inhabilitación inmediata de cuentas por intentos fallidos y la paralización total de la atención operativa." | Out-Null

    Add-Heading2 "2.2. Incompatibilidad de Enlace con Sistemas y Versiones Históricas (OS/400 del Año 2000 / V4R5 - V5R1)" | Out-Null
    Add-Paragraph -Text "La arquitectura de versiones de OS/400 de principios de la década de 2000 (V4R4, V4R5, V5R1) operaba rígidamente bajo niveles de contraseña QPWDLVL 0 y 1, los cuales tienen una limitación física de diseño de máximo 10 caracteres (cifrado DES clásico):" | Out-Null
    Add-Paragraph -Text "• Enlaces DDM y DRDA: La infraestructura bancaria mantiene canales de distribución de datos (Distributed Data Management) y enlaces transaccionales batch hacia servidores satélites legados. Si las cuentas de servicio asociadas utilizan contraseñas de 12 caracteres, el handshake de autenticación es rechazado de inmediato por el host destino con error de protocolo." | Out-Null
    Add-Paragraph -Text "• Replicación y Alta Disponibilidad: Herramientas de sincronización de perfiles de usuario (*USRPRF) hacia servidores secundarios con esquemas de autenticación legados generan fallas de paridad al no poder almacenar hashes de contraseñas de longitud mayor a 10." | Out-Null

    Add-Heading2 "2.3. Emuladores Terminales 5250 sin Negociación de Passphrase Extendida" | Out-Null
    Add-Paragraph -Text "Para admitir contraseñas mayores a 10 caracteres en el panel de inicio de sesión de IBM i (QDSIGNON), las estaciones de trabajo deben soportar la negociación del búfer extendido de contraseñas. Terminales de caja antiguos, emuladores cliente livianos (*thin clients*) y dispositivos heredados carecen de esta compatibilidad y descartan o truncan entradas superiores a 8-10 caracteres." | Out-Null

    # =========================================================================
    # 4. CERTIFICACIÓN DE COMPLEJIDAD ALFANUMÉRICA
    # =========================================================================
    Write-Host "[INFO] Certificando complejidad alfanumérica..." -ForegroundColor Cyan
    Add-Heading1 "3. Certificación de Complejidad Alfanumérica (Cumplimiento Req. 8.3.6)" | Out-Null

    Add-Paragraph -Text "El Requisito 8.3.6 exige certificar que las contraseñas contengan 'tanto caracteres numéricos como alfabéticos'. La entidad acredita el cumplimiento pleno de este control en sus plataformas centrales:" | Out-Null

    Add-Paragraph -Text "• Plataforma IBM i (AS/400 v7.5): El valor de sistema QPWDRQDDGT (Require digit in password) se encuentra estrictamente configurado en '1'. El sistema operativo rechaza cualquier intento de contraseña que no incorpore al menos un dígito numérico (0 al 9). Asimismo, el juego de caracteres de la plataforma exige caracteres alfabéticos, complementado por QPWDLMTAUT (*YES) para prohibir repeticiones consecutivas de caracteres idénticos y QPWDRQDDIF para exigir variación respecto a credenciales anteriores." | Out-Null

    Add-Paragraph -Text "• Plataforma IBM AIX: En el archivo /etc/security/user (stanza default), los parámetros minalpha = 1 (exige alfabéticos obligatorios) y minother = 1 o dcredit = -1 (exige caracteres numéricos o no alfabéticos) se encuentran plenamente habilitados." | Out-Null

    # =========================================================================
    # 5. MATRIZ DE CONTROLES COMPENSATORIOS
    # =========================================================================
    Write-Host "[INFO] Incorporando los 4 controles compensatorios requeridos..." -ForegroundColor Cyan
    Add-Heading1 "4. Matriz de Controles Compensatorios en Profundidad" | Out-Null

    Add-Paragraph -Text "Para neutralizar integralmente el riesgo residual derivado de mantener la longitud mínima de contraseñas en 8 caracteres bajo la excepción de PCI DSS, Banesco Banco Múltiple cuenta con una arquitectura de controles compensatorios en profundidad compuesta por los siguientes cuatro pilares:" | Out-Null

    # Tabla de Controles Compensatorios Solicitados
    $rCtrl = Get-DocEndRange
    $ctrlTable = $Doc.Tables.Add($rCtrl, 5, 3)
    $ctrlTable.Borders.OutsideLineStyle = 1
    $ctrlTable.Borders.OutsideColor = $cGrisBorde
    $ctrlTable.Borders.InsideLineStyle = 1
    $ctrlTable.Borders.InsideColor = $cGrisBorde
    $ctrlTable.Columns.Item(1).Width = 140
    $ctrlTable.Columns.Item(2).Width = 195
    $ctrlTable.Columns.Item(3).Width = 145

    $ctrlHeaders = @("Control Compensatorio", "Mecanismo Implementado", "Efecto de Mitigación de Riesgo")
    for ($c = 1; $c -le 3; $c++) {
        $cell = $ctrlTable.Cell(1, $c)
        $cell.Range.Text = $ctrlHeaders[$c - 1]
        $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 9.5; $cell.Range.Font.Bold = 1; $cell.Range.Font.Color = $cBlanco
        $cell.Shading.BackgroundPatternColor = $cVerdeBanesco
        $cell.TopPadding = 5; $cell.BottomPadding = 5
    }

    $ctrlData = @(
        @("Powertech Command Security (Deny-Default)", "Intercepción de mandatos sensibles de seguridad en IBM i en tiempo real bajo política Deny-Default.", "Impide la ejecución de comandos no autorizados aun mediando credenciales válidas."),
        @("Bloqueo por Intentos Fallidos (QPWDMAXPRC)", "Variable QPWDMAXPRC configurada para inhabilitar perfiles de usuario tras reintentos fallidos consecutivos.", "Neutraliza ataques de fuerza bruta y ataques por diccionario."),
        @("Segmentación y Aislamiento de Red", "Acceso 5250 y SSH restringido exclusivamente a VLANs de administración protegidas con firewall e IPS.", "Evita la exposición de los servicios de autenticación fuera del entorno CDE."),
        @("Auditoría Inmutable (QAUDJRN)", "Registro nativo de eventos de seguridad (auditoría de accesos, cambios de perfiles, fallos de signon).", "Garantiza trazabilidad forense completa y alertas en tiempo real hacia SIEM.")
    )

    for ($r = 1; $r -le 4; $r++) {
        for ($c = 1; $c -le 3; $c++) {
            $cell = $ctrlTable.Cell($r + 1, $c)
            $cell.Range.Text = $ctrlData[$r - 1][$c - 1]
            $cell.Range.Font.Name = "Arial"; $cell.Range.Font.Size = 8.5; $cell.Range.Font.Color = $cTextoOscuro
            if ($c -eq 1) { $cell.Range.Font.Bold = 1; $cell.Range.Font.Color = $cAzulBanesco }
            if ($r % 2 -eq 0) { $cell.Shading.BackgroundPatternColor = $cTenue }
            $cell.TopPadding = 4.5; $cell.BottomPadding = 4.5
        }
    }

    Add-TableBreak

    # =========================================================================
    # 6. CONCLUSIÓN Y SOLICITUD DE CIERRE
    # =========================================================================
    Write-Host "[INFO] Redactando Conclusión y Solicitud de Cierre..." -ForegroundColor Cyan
    Add-Heading1 "5. Conclusión y Solicitud Formal de Cierre de Hallazgo" | Out-Null

    Add-Paragraph -Text "Sobre la base del análisis técnico de arquitectura expuesto, se solicita al equipo auditor de PCI DSS:" | Out-Null
    Add-Paragraph -Text "1. Reconocer la imposibilidad técnica real y justificada de elevar a 12 caracteres la longitud de contraseña en IBM i y AIX, fundamentada en la preservación de la continuidad operativa de las aplicaciones de negocio (pantallas DDS 5250) y canales de comunicación histórica." | Out-Null
    Add-Paragraph -Text "2. Validar que la configuración actual de ocho (8) caracteres cumple taxativamente con la excepción normativa del Requisito 8.3.6 de PCI DSS v4.0.1 ('o SI el sistema no admite 12 caracteres, una longitud mínima de ocho caracteres')." | Out-Null
    Add-Paragraph -Text "3. Certificar la vigencia de la complejidad alfanumérica configurada en las plataformas (QPWDRQDDGT = 1 y minalpha/minother = 1)." | Out-Null
    Add-Paragraph -Text "4. Considerar plenamente efectiva la Matriz de Controles Compensatorios (Powertech Deny-Default, QPWDMAXPRC, Segmentación CDE y QAUDJRN) como mitigante robusto y suficiente del riesgo." | Out-Null
    Add-Paragraph -Text "En virtud de lo anterior, se solicita dar por atendida y subsanada la observación de auditoría." -Bold $true | Out-Null

    # Guardar en ambas ubicaciones
    Write-Host "[INFO] Guardando documento Word oficial..." -ForegroundColor Cyan
    
    $Doc.SaveAs([ref]$DocPath1, [ref]16)
    Write-Host "[OK] Documento guardado exitosamente en: $DocPath1" -ForegroundColor Green

    $Doc.SaveAs([ref]$DocPath2, [ref]16)
    Write-Host "[OK] Copia de resguardo guardada en artefactos: $DocPath2" -ForegroundColor Green

    $Doc.Close([ref]$false)
    $Word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Word) | Out-Null
    Write-Host "[OK] Proceso culminado con éxito." -ForegroundColor Green
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

