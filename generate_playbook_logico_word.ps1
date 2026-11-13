# ==============================================================================
# Script: generate_playbook_logico_word.ps1
# Propósito: Generar el Playbook de Exposición de Llave Criptográfica Lógica
# Cumplimiento: PCI DSS v4.0 Requisito 12.3.3 y estructura idéntica al Playbook Banesco
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$DocPath1 = "d:\WKESPEREIRA\D\Scripts\Playbook_Exposicion_Llave_Criptografica_Logica.docx"
$DocPath2 = "c:\Users\jespereira\Downloads\Playbook_Exposicion_Llave_Criptografica_Logica.docx"

# Paleta cromática oficial Banesco (Valores BGR para Word COM: R + G*256 + B*65536)
$cAzulBanesco = 20 + (59 * 256) + (100 * 65536)     # #143B64
$cAzulHeader = 79 + (129 * 256) + (189 * 65536)    # #4F81BD (Encabezados de tabla estilo PDF)
$cVerdeBanesco = 8 + (84 * 256) + (60 * 65536)       # #08543C
$cTextoOscuro = 40 + (40 * 256) + (40 * 65536)       # #282828
$cBlanco = 16777215                             # #FFFFFF
$cGrisClaro = 242 + (244 * 256) + (246 * 65536)    # #F2F4F6
$cGrisBorde = 180 + (190 * 256) + (205 * 65536)    # #B4BECD
$cRojoAlerta = 237 + (28 * 256) + (36 * 65536)      # Rojo Nivel 1
$cAmarillo = 255 + (192 * 256) + (0 * 65536)      # Amarillo Nivel 2
$cVerdeNivel = 146 + (208 * 256) + (80 * 65536)     # Verde Nivel 3

Write-Host "[INFO] Iniciando Word COM Object..." -ForegroundColor Cyan
$Word = New-Object -ComObject Word.Application
$Word.Visible = $false
$Word.DisplayAlerts = 0

try {
    $Doc = $Word.Documents.Add()

    # Configuración de márgenes estándar (2.2 cm superior/inferior, 2.5 cm laterales)
    $Doc.PageSetup.TopMargin = 62.36
    $Doc.PageSetup.BottomMargin = 62.36
    $Doc.PageSetup.LeftMargin = 70.85
    $Doc.PageSetup.RightMargin = 70.85

    # Encabezado y Pie de página
    $Header = $Doc.Sections.Item(1).Headers.Item(1)
    $HeaderRange = $Header.Range
    $HeaderRange.Text = "Playbook Exposición de Llave Criptográfica Lógica`t`tBanesco Banco Universal [Confidencial]"
    $HeaderRange.Font.Name = "Arial"
    $HeaderRange.Font.Size = 8.5
    $HeaderRange.Font.Color = $cAzulBanesco

    $Footer = $Doc.Sections.Item(1).Footers.Item(1)
    $FooterRange = $Footer.Range
    $FooterRange.Text = "Plan de Respuestas a Incidentes de Ciberseguridad | PCI DSS v4.0 Req. 12.3.3`t`tPágina "
    $FooterRange.Font.Name = "Arial"
    $FooterRange.Font.Size = 8.5
    $FooterRange.Font.Color = $cTextoOscuro
    $FooterRange.Collapse(0)
    $Doc.Fields.Add($FooterRange, 33) | Out-Null # wdFieldPage

    function Get-DocEnd {
        $r = $Doc.Content
        $r.Collapse(0)
        return $r
    }

    function Add-WordTable {
        param (
            [int]$Rows,
            [int]$Cols
        )
        $r = Get-DocEnd
        return $Doc.Tables.Add($r, $Rows, $Cols)
    }

    function Add-P {
        param (
            [string]$Text = "",
            [string]$FontName = "Arial",
            [float]$FontSize = 10,
            [int]$FontColor = $cTextoOscuro,
            [bool]$Bold = $false,
            [bool]$Italic = $false,
            [int]$Align = 0, # 0=Left, 1=Center, 2=Right, 3=Justify
            [float]$Before = 0,
            [float]$After = 4,
            [float]$LineSpacing = 12
        )
        $r = Get-DocEnd
        $p = $Doc.Paragraphs.Add($r)
        $p.Range.Text = $Text
        $p.Range.Font.Name = $FontName
        $p.Range.Font.Size = $FontSize
        $p.Range.Font.Color = $FontColor
        $p.Range.Font.Bold = if ($Bold) { 1 } else { 0 }
        $p.Range.Font.Italic = if ($Italic) { 1 } else { 0 }
        $p.Alignment = $Align
        $p.SpaceBefore = $Before
        $p.SpaceAfter = $After
        if ($LineSpacing -gt 0) {
            $p.LineSpacingRule = 4
            $p.LineSpacing = $LineSpacing
        }
        $null = $p
    }

    function Add-H1 {
        param ([string]$Text)
        return Add-P -Text $Text -FontName "Arial" -FontSize 15 -FontColor $cAzulBanesco -Bold $true -Before 14 -After 5
    }

    function Add-H2 {
        param ([string]$Text)
        return Add-P -Text $Text -FontName "Arial" -FontSize 12 -FontColor $cAzulBanesco -Bold $true -Before 10 -After 4
    }

    function Add-H3 {
        param ([string]$Text)
        return Add-P -Text $Text -FontName "Arial" -FontSize 10.5 -FontColor $cVerdeBanesco -Bold $true -Before 6 -After 2
    }

    function Add-TBreak {
        $r = Get-DocEnd
        $r.InsertParagraphAfter()
        $r.Collapse(0)
    }

    # =========================================================================
    # 1. PORTADA
    # =========================================================================
    Write-Host "[INFO] Generando Portada..." -ForegroundColor Yellow
    Add-P -Text "Plan de Respuestas a Incidentes de Seguridad:`r`nExposición de Llaves Criptográficas Lógicas" -FontSize 11 -FontColor $cAzulBanesco -Bold $true -Before 20 -After 5
    Add-P -Text "Banesco Banco Universal`r`nUso Interno / Confidencial" -FontSize 10 -FontColor $cTextoOscuro -Italic $true -After 140

    Add-P -Text "Playbook de Gestión de Incidentes de Seguridad" -FontSize 20 -FontColor $cAzulBanesco -Bold $true -Align 1 -After 15
    Add-P -Text "Exposición de Llave Criptográfica Lógica`r`n(Cumplimiento PCI DSS v4.0 Requisito 12.3.3)" -FontSize 16 -FontColor $cTextoOscuro -Bold $true -Align 1 -After 180

    Add-P -Text "Versión 2.0 | Noviembre 2026`r`nGerencia de Ciberseguridad & Administración de Seguridad de la Información" -FontSize 9.5 -FontColor $cTextoOscuro -Align 1 -After 20
    $Doc.Words.Last.InsertBreak(7) # Salto de página

    # =========================================================================
    # 2. CONTENIDO (ÍNDICE)
    # =========================================================================
    Write-Host "[INFO] Generando Contenido..." -ForegroundColor Yellow
    Add-H1 -Text "Contenido"
    
    $indexItems = @(
        @("Introducción y Marco de Cumplimiento PCI DSS 12.3.3", "3"),
        @("Metodología de evaluación de incidentes", "4"),
        @("Impacto", "4"),
        @("Evaluación del Alcance", "5"),
        @("Protocolo de escalada de amenazas", "5"),
        @("Protocolo de escalada de amenazas ajustado a este incidente", "6"),
        @("Descripción general de la gestión de incidentes", "7"),
        @("Procedimientos de respuesta", "8"),
        @("    Fase de Detección", "8"),
        @("    Fase de Análisis", "10"),
        @("    Fase de Contención", "12"),
        @("    Fase de Erradicación", "14"),
        @("    Fase de Recuperación", "16"),
        @("    Fase Post-Incidente", "18"),
        @("I. Aprobación del Documento", "20"),
        @("Anexo A: Plantilla Oficial de Inventario de Protocolos y Cipher Suites (PCI DSS Req. 12.3.3)", "21"),
        @("Anexo B: Procedimiento de Monitoreo Activo de Viabilidad y Estrategia ante Vulnerabilidades Anticipadas", "22")
    )

    $tIndex = $Doc.Tables.Add((Get-DocEnd), $indexItems.Count, 2)
    $tIndex.Borders.OutsideLineStyle = 0
    $tIndex.Borders.InsideLineStyle = 0
    $tIndex.Columns.Item(1).SetWidth(380, 0)
    $tIndex.Columns.Item(2).SetWidth(70, 0)

    for ($i = 0; $i -lt $indexItems.Count; $i++) {
        $row = $tIndex.Rows.Item($i + 1)
        $row.Cells.Item(1).Range.Text = $indexItems[$i][0]
        $row.Cells.Item(1).Range.Font.Name = "Arial"
        $row.Cells.Item(1).Range.Font.Size = 9.5
        $row.Cells.Item(1).Range.Font.Bold = if ($indexItems[$i][0] -match "^(Introducción|Metodología|Impacto|Evaluación|Protocolo|Descripción|Procedimientos|I\.|Anexo)") { 1 } else { 0 }
        $row.Cells.Item(1).Range.Font.Color = $cTextoOscuro
        
        $row.Cells.Item(2).Range.Text = $indexItems[$i][1]
        $row.Cells.Item(2).Range.Font.Name = "Arial"
        $row.Cells.Item(2).Range.Font.Size = 9.5
        $row.Cells.Item(2).Range.ParagraphFormat.Alignment = 2 # Right
    }
    Add-TBreak
    $Doc.Words.Last.InsertBreak(7) # Salto de página

    # =========================================================================
    # 3. INTRODUCCIÓN Y MARCO NORMATIVO
    # =========================================================================
    Write-Host "[INFO] Generando Introducción y Marco Normativo..." -ForegroundColor Yellow
    Add-H1 -Text "Introducción"
    Add-P -Text "La exposición o divulgación no autorizada de una llave criptográfica lógica representa un incidente de seguridad crítico para Banesco Banco Universal. A diferencia de los componentes físicos en sobres de seguridad custodiados en bóvedas (los cuales cuentan con actas formales de custodia e inventario de componentes), el presente Playbook aborda la exposición, fuga, exfiltración, divulgación accidental o acceso no autorizado a llaves criptográficas lógicas (simétricas, asimétricas, llaves maestras KEK/LMK, llaves de cifrado de datos DEK, llaves de zona ZPK, llaves privadas TLS y credenciales de cifrado en repositorios, bases de datos o servicios en nube)." -Align 3

    Add-P -Text "La materialización de este incidente obliga a una respuesta técnica y operativa inmediata para evitar la interceptación, desencapsulamiento o descifrado ilegítimo de información sensitiva de tarjetahabientes (PAN, CVV/CVC, PIN blocks) y transacciones financieras. Aunque su causa raíz y vector de propagación son lógicos, la contingencia abarca tanto el aislamiento de sistemas y servicios como la rotación de emergencia y la activación de canales alternos." -Align 3

    Add-H2 -Text "Alineación y Cumplimiento con PCI DSS v4.0 Requisito 12.3.3"
    Add-P -Text "Para subsanar las observaciones de auditoría externa y garantizar el cumplimiento estricto del Requisito 12.3.3 del estándar PCI DSS v4.0, este Playbook establece la articulación obligatoria de los siguientes cuatro pilares operativos:" -Align 3

    Add-P -Text "1. Inventario Actualizado de Protocolos y Cipher Suites en Uso: Registro continuo y exhaustivo de todos los algoritmos, suites de cifrado y protocolos criptográficos activos, detallando obligatoriamente su propósito de negocio, componente de hardware o software asociado y ubicación exacta de uso (hosts, servidores de aplicaciones, bases de datos Oracle, AS400, switch transaccional AZ7, microservicios, HSM y canales de comunicación)." -Align 3
    Add-P -Text "2. Monitoreo Activo de Viabilidad Criptográfica: Supervisión continua y sistemática de la fortaleza matemática y vigencia técnica de los algoritmos y suites frente a las tendencias de la industria, boletines de vulnerabilidades (CVEs), recomendaciones de NIST (SP 800-57, SP 800-131A Rev. 2) y lineamientos de PCI Security Standards Council (PCI SSC)." -Align 3
    Add-P -Text "3. Estrategia Documentada ante Vulnerabilidades Criptográficas Anticipadas: Hoja de ruta predefinida para responder con agilidad criptográfica ante la pérdida de robustez de un algoritmo, debilidades matemáticas descubiertas o transiciones requeridas por la industria (ej. obsolescencia de SHA-1, 3DES, migración a AES-256 o criptografía poscuántica)." -Align 3
    Add-P -Text "4. Revisión Periódica Anual Obligatoria (Cada 12 Meses): Formalización institucional de la revisión integral del inventario de criptografía y de la estrategia de mitigación, ejecutada al menos una vez cada doce (12) meses con evidencia documental firmada para auditoría." -Align 3

    # =========================================================================
    # 4. METODOLOGÍA, IMPACTO Y ALCANCE
    # =========================================================================
    Write-Host "[INFO] Generando Metodología, Impacto y Alcance..." -ForegroundColor Yellow
    Add-H1 -Text "Metodología de evaluación de incidentes"
    Add-P -Text "La metodología de evaluación de incidentes consiste en la estimación rigurosa del impacto operativo/financiero, el alcance técnico en la infraestructura de pagos y el protocolo de escalada de amenazas de la organización ante el compromiso de material criptográfico lógico." -Align 3

    Add-H1 -Text "Impacto"
    Add-P -Text "Evalúa los efectos de la exposición lógica de material criptográfico o el debilitamiento de un conjunto de cifrado en las funciones del negocio, la confidencialidad de los datos de tarjetahabientes y los esfuerzos de mitigación. Se categoriza en función de los siguientes factores:" -Align 3
    Add-P -Text "1. El impacto funcional actual y futuro en cualquier plataforma u operación del negocio (switch transaccional, adquirencia POS, autorización de cajeros ATM, banca digital)." -Align 3
    Add-P -Text "2. El impacto informativo en lo referente a la confidencialidad, integridad y disponibilidad de llaves criptográficas y datos de tarjetahabientes (PAN, PIN blocks, llaves maestras)." -Align 3
    Add-P -Text "3. El tiempo y los recursos necesarios para contener la brecha, generar nuevo material criptográfico, reencriptar información y restaurar la operación normal." -Align 3

    # Tabla Criterios de Impacto
    Add-H2 -Text "Exposición de llaves criptográficas lógicas: Criterios de impacto"
    $tImp = $Doc.Tables.Add((Get-DocEnd), 4, 2)
    $tImp.Borders.InsideLineStyle = 1
    $tImp.Borders.OutsideLineStyle = 1
    $tImp# border color
    $tImp.Columns.Item(1).SetWidth(90, 0)
    $tImp.Columns.Item(2).SetWidth(360, 0)

    # Header
    $tImp.Rows.Item(1).HeadingFormat = -1
    $tImp.Cell(1, 1).Range.Text = "Clasificación"
    $tImp.Cell(1, 2).Range.Text = "Definición"
    for ($c = 1; $c -le 2; $c++) {
        $cell = $tImp.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.Font.Size = 9.5
    }

    $tImp.Cell(2, 1).Range.Text = "Alto"
    $tImp.Cell(2, 1).Range.Font.Bold = 1
    $tImp.Cell(2, 2).Range.Text = "✔ Detección de exposición en texto plano de llaves maestras (LMK/KEK), llaves de zona (ZPK) o llaves de cifrado de base de datos (DEK) que protegen datos de tarjetahabientes (PAN).`r`n✔ Fuga de llave privada de certificados TLS de pasarelas de pago o APIs transaccionales.`r`n✔ Fraudes confirmados o transacciones no autorizadas originadas por descifrado de PIN o PAN.`r`n✔ Suspensión o riesgo inminente de sanción por parte de Franquicias (Visa/Mastercard) o entes regulatorios (SUDEBAN/PCI SSC).`r`n✔ Pérdida severa de reputación corporativa y credibilidad pública del Banco."
    
    $tImp.Cell(3, 1).Range.Text = "Medio"
    $tImp.Cell(3, 1).Range.Font.Bold = 1
    $tImp.Cell(3, 2).Range.Text = "✔ Exposición de llaves criptográficas o certificados en ambientes de testing/QA que no contienen datos reales de producción ni conectividad al CDE.`r`n✔ Detección en el monitoreo activo de viabilidad de una suite de cifrado en producción con vulnerabilidad teórica publicada (CVE reciente sin explotación activa en el Banco).`r`n✔ Exposición de llaves de firma de servicios internos con impacto transaccional acotado."

    $tImp.Cell(4, 1).Range.Text = "Bajo"
    $tImp.Cell(4, 1).Range.Font.Bold = 1
    $tImp.Cell(4, 2).Range.Text = "✔ Identificación durante la revisión anual obligatoria (12 meses) de protocolos o cipher suites que requieren actualización planificada antes de su fecha formal de deprecación.`r`n✔ Falsa alarma de fuga de llaves confirmada por escaneo de secretos (falso positivo de escáner SAST/DAST en repositorio).`r`n✔ Divulgación accidental de claves públicas sin impacto sobre el material secreto o privado."
    Add-TBreak

    # Evaluación del Alcance
    Add-H1 -Text "Evaluación del Alcance"
    Add-P -Text "Evalúa la amplitud y magnitud técnica del incidente en la arquitectura lógica del banco: sistemas centrales (Core AZ7, IBM i / AS400), microservicios, bases de datos (Oracle actived), terminales de punto de venta (POS), cajeros automáticos (ATM), pasarelas de pago y módulos HSM. El alcance es determinante para seleccionar las estrategias de revocación y reemplazo de llaves." -Align 3

    # Tabla Criterios de Alcance
    Add-H2 -Text "Exposición de llaves criptográficas lógicas: Criterios de alcance"
    $tAlc = $Doc.Tables.Add((Get-DocEnd), 3, 2)
    $tAlc.Borders.InsideLineStyle = 1
    $tAlc.Borders.OutsideLineStyle = 1
    $tAlc# border color
    $tAlc.Columns.Item(1).SetWidth(90, 0)
    $tAlc.Columns.Item(2).SetWidth(360, 0)

    $tAlc.Cell(1, 1).Range.Text = "Clasificación"
    $tAlc.Cell(1, 2).Range.Text = "Definición"
    for ($c = 1; $c -le 2; $c++) {
        $cell = $tAlc.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.Font.Size = 9.5
    }

    $tAlc.Cell(2, 1).Range.Text = "Alto"
    $tAlc.Cell(2, 1).Range.Font.Bold = 1
    $tAlc.Cell(2, 2).Range.Text = "La llave o conjunto de cifrado comprometido afecta a múltiples servicios transaccionales críticos, a la base de datos de producción completa, a la comunicación con marcas (Visa/Mastercard/Suiche7B), a un clúster de HSMs o a más del 10% del parque de terminales POS/ATM del Banco."

    $tAlc.Cell(3, 1).Range.Text = "Bajo"
    $tAlc.Cell(3, 1).Range.Font.Bold = 1
    $tAlc.Cell(3, 2).Range.Text = "La llave lógica comprometida está limitada a un único host o microservicio secundario aislado, no afecta el CDE transaccional ni canales externos, y puede ser revocada y reemplazada sin interrumpir operaciones masivas del negocio."
    Add-TBreak

    # =========================================================================
    # 5. PROTOCOLOS DE ESCALADA DE AMENAZAS
    # =========================================================================
    Write-Host "[INFO] Generando Protocolos de Escalada..." -ForegroundColor Yellow
    Add-H1 -Text "Protocolo de escalada de amenazas"
    Add-P -Text "Define el tipo de partes interesadas y comités de respuesta requeridos durante el ciclo de vida del incidente. Notificar y consultar oportunamente a estos actores es vital para articular la defensa jurídica, técnica y comercial de Banesco." -Align 3

    Add-P -Text "Tabla 1. Protocolo de escalada de amenazas (Matriz Impacto vs Alcance)" -Bold $true
    $tMat = $Doc.Tables.Add((Get-DocEnd), 3, 4)
    $tMat.Borders.InsideLineStyle = 1
    $tMat.Borders.OutsideLineStyle = 1
    $tMat# border color
    $tMat.Columns.Item(1).SetWidth(90, 0)
    $tMat.Columns.Item(2).SetWidth(120, 0)
    $tMat.Columns.Item(3).SetWidth(120, 0)
    $tMat.Columns.Item(4).SetWidth(120, 0)

    $tMat.Cell(1, 1).Range.Text = "Impacto / Alcance"
    $tMat.Cell(1, 2).Range.Text = "Alto"
    $tMat.Cell(1, 3).Range.Text = "Medio"
    $tMat.Cell(1, 4).Range.Text = "Bajo"
    for ($c = 1; $c -le 4; $c++) {
        $cell = $tMat.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.ParagraphFormat.Alignment = 1
    }

    $tMat.Cell(2, 1).Range.Text = "Alto"
    $tMat.Cell(2, 1).Range.Font.Bold = 1
    $tMat.Cell(2, 2).Range.Text = "Nivel 1"
    $tMat.Cell(2, 2).Shading.BackgroundPatternColor = $cRojoAlerta
    $tMat.Cell(2, 2).Range.Font.Color = $cBlanco
    $tMat.Cell(2, 2).Range.Font.Bold = 1
    $tMat.Cell(2, 2).Range.ParagraphFormat.Alignment = 1

    $tMat.Cell(2, 3).Range.Text = "Nivel 1"
    $tMat.Cell(2, 3).Shading.BackgroundPatternColor = $cRojoAlerta
    $tMat.Cell(2, 3).Range.Font.Color = $cBlanco
    $tMat.Cell(2, 3).Range.Font.Bold = 1
    $tMat.Cell(2, 3).Range.ParagraphFormat.Alignment = 1

    $tMat.Cell(2, 4).Range.Text = "Nivel 2"
    $tMat.Cell(2, 4).Shading.BackgroundPatternColor = $cAmarillo
    $tMat.Cell(2, 4).Range.Font.Bold = 1
    $tMat.Cell(2, 4).Range.ParagraphFormat.Alignment = 1

    $tMat.Cell(3, 1).Range.Text = "Bajo"
    $tMat.Cell(3, 1).Range.Font.Bold = 1
    $tMat.Cell(3, 2).Range.Text = "Nivel 2"
    $tMat.Cell(3, 2).Shading.BackgroundPatternColor = $cAmarillo
    $tMat.Cell(3, 2).Range.Font.Bold = 1
    $tMat.Cell(3, 2).Range.ParagraphFormat.Alignment = 1

    $tMat.Cell(3, 3).Range.Text = "Nivel 2"
    $tMat.Cell(3, 3).Shading.BackgroundPatternColor = $cAmarillo
    $tMat.Cell(3, 3).Range.Font.Bold = 1
    $tMat.Cell(3, 3).Range.ParagraphFormat.Alignment = 1

    $tMat.Cell(3, 4).Range.Text = "Nivel 3"
    $tMat.Cell(3, 4).Shading.BackgroundPatternColor = $cVerdeNivel
    $tMat.Cell(3, 4).Range.Font.Bold = 1
    $tMat.Cell(3, 4).Range.ParagraphFormat.Alignment = 1
    Add-TBreak

    Add-H2 -Text "Protocolo de escalada de amenazas ajustado a este incidente"
    Add-P -Text "A continuación se definen los criterios y partes interesadas para incidentes de exposición o debilitamiento de llaves criptográficas lógicas:" -Align 3

    $tEsc = $Doc.Tables.Add((Get-DocEnd), 3, 3)
    $tEsc.Borders.InsideLineStyle = 1
    $tEsc.Borders.OutsideLineStyle = 1
    $tEsc# border color
    $tEsc.Columns.Item(1).SetWidth(120, 0)
    $tEsc.Columns.Item(2).SetWidth(140, 0)
    $tEsc.Columns.Item(3).SetWidth(190, 0)

    $tEsc.Cell(1, 1).Range.Text = "Protocolo de Escalamiento"
    $tEsc.Cell(1, 2).Range.Text = "Criterio"
    $tEsc.Cell(1, 3).Range.Text = "Partes Interesadas"
    for ($c = 1; $c -le 3; $c++) {
        $cell = $tEsc.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.Font.Size = 9.5
    }

    $tEsc.Cell(2, 1).Range.Text = "Protocolo de escalada Nivel 1"
    $tEsc.Cell(2, 1).Shading.BackgroundPatternColor = $cRojoAlerta
    $tEsc.Cell(2, 1).Range.Font.Color = $cBlanco
    $tEsc.Cell(2, 1).Range.Font.Bold = 1
    $tEsc.Cell(2, 2).Range.Text = "✔ Alto impacto, alto alcance.`r`n✔ Alto impacto, medio alcance.`r`n✔ Fuga confirmada de llaves de producción CDE (KEK, DEK, ZPK, TLS Private Key)."
    $tEsc.Cell(2, 3).Range.Text = "✔ CISO y Alta Dirección`r`n✔ Equipo de Seguridad:`r`n  ● Ciberseguridad / CSIRT / SOC`r`n  ● Administración de Seguridad de la Información`r`n  ● Custodios de Llaves Lógicas`r`n✔ Gerencia de Prevención de Fraudes`r`n✔ Legal y Recursos Humanos`r`n✔ Operaciones TI e Infraestructura`r`n✔ Marcas (Visa/Mastercard) y Operadoras (Suiche 7B/Conexus)`r`n✔ Superintendencia de Bancos (SUDEBAN)"

    $tEsc.Cell(3, 1).Range.Text = "Protocolo de escalada Nivel 2 y 3"
    $tEsc.Cell(3, 1).Shading.BackgroundPatternColor = $cGrisClaro
    $tEsc.Cell(3, 1).Range.Font.Bold = 1
    $tEsc.Cell(3, 2).Range.Text = "✔ Impacto medio/bajo con alcance acotado.`r`n✔ Obsolescencia criptográfica identificada en revisión de 12 meses sin ataque activo.`r`n✔ Falso positivo de divulgación."
    $tEsc.Cell(3, 3).Range.Text = "✔ Especialistas en Ciberseguridad`r`n✔ Administración de Seguridad de la Información`r`n✔ Custodios de Llaves y Arquitectura TI`r`n✔ Gerencia de Ciberseguridad`r`n✔ Auditoría de Cumplimiento PCI DSS`r`n✔ CISO (Informe mensual ejecutivo)"
    Add-TBreak

    # =========================================================================
    # 6. DESCRIPCIÓN GENERAL DE LA GESTIÓN DE INCIDENTES
    # =========================================================================
    Write-Host "[INFO] Generando Descripción General..." -ForegroundColor Yellow
    Add-H1 -Text "Descripción general de la gestión de incidentes"
    Add-P -Text "La siguiente tabla resume la conceptualización de la exposición de llaves criptográficas lógicas, los riesgos generados y la respuesta táctica coordinada para neutralizar la amenaza y cumplir con los requisitos PCI DSS:" -Align 3

    $tGen = $Doc.Tables.Add((Get-DocEnd), 4, 2)
    $tGen.Borders.InsideLineStyle = 1
    $tGen.Borders.OutsideLineStyle = 1
    $tGen# border color
    $tGen.Columns.Item(1).SetWidth(120, 0)
    $tGen.Columns.Item(2).SetWidth(330, 0)

    $tGen.Cell(1, 1).Range.Text = "¿Qué es una detección de exposición de llave criptográfica lógica?"
    $tGen.Cell(1, 1).Shading.BackgroundPatternColor = $cGrisClaro
    $tGen.Cell(1, 1).Range.Font.Bold = 1
    $tGen.Cell(1, 2).Range.Text = "1. Es la detección del acceso no autorizado, fuga, compromiso o publicación en texto plano de material criptográfico lógico (llaves simétricas, llaves asimétricas privadas, tokens o credenciales de cifrado) o el uso inadvertido de protocolos o cipher suites débiles y vulnerables que invaliden la confidencialidad e integridad del entorno CDE según el Requisito 12.3.3."

    $tGen.Cell(2, 1).Range.Text = "¿Cuál es el incidente?"
    $tGen.Cell(2, 1).Shading.BackgroundPatternColor = $cGrisClaro
    $tGen.Cell(2, 1).Range.Font.Bold = 1
    $tGen.Cell(2, 2).Range.Text = "2. Exfiltración o exposición de llaves criptográficas en repositorios de código (Git/DevOps), volcados de memoria, archivos de logs no sanitizados, canales sin cifrado seguro, configuración errónea de IAM en KMS o compromiso de servidores de aplicaciones, habilitando el descifrado potencial de transacciones y datos de tarjetahabientes."

    $tGen.Cell(3, 1).Range.Text = "¿Por qué debería ocuparnos?"
    $tGen.Cell(3, 1).Shading.BackgroundPatternColor = $cGrisClaro
    $tGen.Cell(3, 1).Range.Font.Bold = 1
    $tGen.Cell(3, 2).Range.Text = "3. Riesgos Financieros: Posibles fraudes masivos y clonación de datos financieros.`r`n4. Riesgo Reputacional: Pérdida inmediata de credibilidad de clientes y socios comerciales.`r`n5. Sanciones y Suspensión: Multas de las Marcas (Visa/Mastercard), revocación de certificados y posible clausura de procesamiento por entes reguladores.`r`n6. No Conformidad PCI DSS: Pérdida de la certificación bajo el Requisito 12.3.3 por falta de inventario, estrategia documentada y monitoreo activo de algoritmos."

    $tGen.Cell(4, 1).Range.Text = "¿Cómo respondemos?"
    $tGen.Cell(4, 1).Shading.BackgroundPatternColor = $cGrisClaro
    $tGen.Cell(4, 1).Range.Font.Bold = 1
    $tGen.Cell(4, 2).Range.Text = "1. Activación inmediata del CSIRT y Comité de Emergencia.`r`n2. Consulta al Inventario Oficial de Protocolos y Cipher Suites para identificar el propósito y ubicación exacta del elemento expuesto.`r`n3. Revocación y deshabilitación lógica inmediata en HSM/KMS de la llave comprometida.`r`n4. Notificación regulatoria (Marcas antes de 24h, SUDEBAN, CISO).`r`n5. Generación de nuevas llaves robustas bajo ceremonia lógica y reencriptación de datos expuestos.`r`n6. Ejecución de la revisión anual obligatoria (12 meses) y actualización de la estrategia ante vulnerabilidades anticipadas."
    Add-TBreak

    # =========================================================================
    # 7. PROCEDIMIENTOS DE RESPUESTA EN LAS 6 FASES
    # =========================================================================
    Write-Host "[INFO] Generando Procedimientos de Respuesta (6 Fases)..." -ForegroundColor Yellow
    Add-H1 -Text "Procedimientos de respuesta"
    Add-P -Text "A continuación se detallan las acciones requeridas para cada equipo responsable en cada una de las seis fases del ciclo de vida del incidente: Detección, Análisis, Contención, Erradicación, Recuperación y Post-Incidente, integrando de forma operativa el Requisito 12.3.3 de PCI DSS." -Align 3

    # Helper para tablas de fases
    function Add-PhaseTable {
        param (
            [string]$PhaseTitle,
            [array]$RowsData
        )
        Add-H2 -Text $PhaseTitle
        $t = $Doc.Tables.Add((Get-DocEnd), $RowsData.Count + 1, 4)
        $t.Borders.InsideLineStyle = 1
        $t.Borders.OutsideLineStyle = 1
        $t# border color
        $t.Columns.Item(1).SetWidth(95, 0)
        $t.Columns.Item(2).SetWidth(100, 0)
        $t.Columns.Item(3).SetWidth(115, 0)
        $t.Columns.Item(4).SetWidth(140, 0)

        # Header
        $t.Rows.Item(1).HeadingFormat = -1
        $t.Cell(1, 1).Range.Text = "Equipo"
        $t.Cell(1, 2).Range.Text = "Descripción"
        $t.Cell(1, 3).Range.Text = "Preguntas"
        $t.Cell(1, 4).Range.Text = "Acción"
        for ($c = 1; $c -le 4; $c++) {
            $cell = $t.Cell(1, $c)
            $cell.Shading.BackgroundPatternColor = $cAzulHeader
            $cell.Range.Font.Bold = 1
            $cell.Range.Font.Color = $cBlanco
            $cell.Range.Font.Size = 9
        }

        for ($r = 0; $r -lt $RowsData.Count; $r++) {
            $currRow = $t.Rows.Item($r + 2)
            $currRow.Cells.Item(1).Range.Text = $RowsData[$r][0]
            $currRow.Cells.Item(1).Range.Font.Bold = 1
            $currRow.Cells.Item(1).Range.Font.Size = 8.5
            
            $currRow.Cells.Item(2).Range.Text = $RowsData[$r][1]
            $currRow.Cells.Item(2).Range.Font.Size = 8.5
            
            $currRow.Cells.Item(3).Range.Text = $RowsData[$r][2]
            $currRow.Cells.Item(3).Range.Font.Size = 8.5
            
            $currRow.Cells.Item(4).Range.Text = $RowsData[$r][3]
            $currRow.Cells.Item(4).Range.Font.Size = 8.5
        }
        Add-TBreak
    }

    # FASE DE DETECCIÓN
    $faseDet = @(
        @(
            "Equipo de Seguridad: Administración de Seguridad",
            "Identificación de alertas de divulgación o exposición de llaves lógicas",
            "✔ ¿Dónde se expuso la llave lógica (código, logs, base de datos, memoria)?`r`n✔ ¿Qué identificador de llave o protocolo está involucrado?`r`n✔ ¿La llave está registrada en el Inventario de Protocolos y Ciphers (Req. 12.3.3)?",
            "✔ Notificar inmediatamente a la Gerencia de Ciberseguridad y CSIRT.`r`n✔ Consultar de inmediato el Inventario de Protocolos y Cipher Suites en Uso para ubicar propósito y alcance.`r`n✔ No manipular logs ni modificar configuraciones sin asegurar preservación forense.`r`n✔ Registrar ticket de incidente crítico en plataforma ITSM."
        ),
        @(
            "Equipo de Ciberseguridad / SOC / CSIRT",
            "Monitoreo de tráfico, alertas de escaneo de secretos y DLP",
            "✔ ¿Hubo exfiltración externa de tráfico o consultas inusuales a APIs criptográficas?`r`n✔ ¿El incidente fue detectado por escáner de repositorios o alerta IDS/SIEM?`r`n✔ ¿Se detectan intentos de descifrado masivo?",
            "✔ Confirmar validez del hallazgo (descartar falso positivo).`r`n✔ Aislar trazas de red y generar dump forense del entorno comprometido.`r`n✔ Validar el estatus de viabilidad del algoritmo y suite frente al repositorio de inteligencia de amenazas."
        ),
        @(
            "Equipo Legal y Recursos Humanos",
            "Apertura de expediente y evaluación de implicaciones legales",
            "✔ ¿La exposición obedece a una negligencia interna, error de configuración o fuga intencional?`r`n✔ ¿Qué acuerdos de confidencialidad o normativas fueron vulnerados?",
            "✔ Aperturar expediente legal de contingencia.`r`n✔ Suspender temporalmente privilegios de usuarios sospechosos en coordinación con RRHH.`r`n✔ Preparar comunicaciones de resguardo legal bajo reserva institucional."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase de Detección" -RowsData $faseDet

    # FASE DE ANÁLISIS
    $faseAna = @(
        @(
            "Análisis: Ciberseguridad y Forense Digital",
            "Determinación técnica del vector de ataque y viabilidad criptográfica",
            "✔ ¿Qué algoritmo y tamaño de llave fue expuesto (AES, RSA, 3DES)?`r`n✔ Conforme al Requisito 12.3.3, ¿el cipher suite se encuentra vigente o en obsolescencia?`r`n✔ ¿Existe evidencia de uso ilícito de la llave?",
            "✔ Correlacionar el identificador con el Inventario de Protocolos y Ciphers (verificar propósito y ubicación).`r`n✔ Evaluar viabilidad matemática del algoritmo frente a estándares NIST (SP 800-57 / SP 800-131A).`r`n✔ Determinar el volumen exacto de registros y transacciones expuestas."
        ),
        @(
            "Análisis: Administración de Seguridad y Custodios Lógicos",
            "Evaluación de jerarquía criptográfica y dependencias",
            "✔ ¿La llave expuesta es una KEK (Key Encrypting Key), una DEK o una ZPK de red?`r`n✔ Si fue una KEK, ¿cuántas llaves secundarias quedaron vulneradas?`r`n✔ ¿Qué plataformas dependen de esta llave (AS400, AZ7, Oracle)?",
            "✔ Elaborar el árbol de dependencias criptográficas afectadas.`r`n✔ Determinar los parámetros técnicos para la revocación en HSM/KMS.`r`n✔ Presentar opciones de rotación y transición a la Gerencia de Ciberseguridad."
        ),
        @(
            "Análisis: CISO, Legal y Fraude",
            "Evaluación de impacto institucional y obligaciones regulatorias",
            "✔ ¿Se han consumado fraudes financieros en puntos de venta o cajeros?`r`n✔ ¿Se requieren notificaciones regulatorias obligatorias (Marcas / SUDEBAN)?`r`n✔ ¿Existe riesgo reputacional masivo?",
            "✔ Coordinar mesa de crisis técnica con la Alta Dirección.`r`n✔ Dictaminar si procede la activación de la notificación de brecha a Franquicias (antes de 24h).`r`n✔ Establecer directrices de contención jurídica y disciplinaria."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase de Análisis" -RowsData $faseAna

    # FASE DE CONTENCIÓN
    $faseCon = @(
        @(
            "Contención: Consultor de Administración de Seguridad",
            "Revocación y deshabilitación lógica inmediata",
            "✔ ¿Cómo suspender el uso de la llave sin provocar una caída desordenada del servicio?`r`n✔ ¿A quiénes se debe alertar externamente?",
            "✔ Ejecutar la revocación lógica inmediata de la llave en el HSM, KMS o base de datos.`r`n✔ Notificar a las Franquicias (Visa/Mastercard) antes de las 24 horas del hallazgo.`r`n✔ Notificar de inmediato a las Operadoras de POS (Suiche 7B / Conexus).`r`n✔ Habilitar perfiles de contingencia criptográfica si están previstos."
        ),
        @(
            "Contención: Ciberseguridad y Operaciones TI",
            "Aislamiento de sistemas, canales y saneamiento temporal",
            "✔ ¿Qué servidores o APIs deben ser desconectados o restringidos?`r`n✔ ¿Cómo frenar la exfiltración sin alertar a actores maliciosos?",
            "✔ Bloquear en firewalls/WAF las IPs o endpoints asociados a la fuga.`r`n✔ Deshabilitar el conjunto de cifrado vulnerable en balanceadores y servidores de aplicaciones.`r`n✔ Revocar tokens, credenciales y sesiones asociadas al componente expuesto."
        ),
        @(
            "Contención: CISO y Alta Dirección",
            "Supervisión ejecutiva y autorización de contingencias",
            "✔ ¿Se requiere suspender temporalmente canales de pago críticos?`r`n✔ ¿Están operando los controles de mitigación compensatorios?",
            "✔ Autorizar ventanas de intervención operativa de emergencia.`r`n✔ Emitir directrices a operaciones de negocio y finanzas.`r`n✔ Mantener informado al Comité de Riesgos y Junta Directiva."
        ),
        @(
            "Contención: Legal, RRHH y Comunicaciones",
            "Blindaje normativo y contención reputacional",
            "✔ ¿Existe necesidad de declaraciones públicas o comunicados reservados?`r`n✔ ¿Se requiere medidas cautelares contra personal involucrado?",
            "✔ Redactar comunicados oficiales bajo directriz estricta del CISO.`r`n✔ Aplicar contención disciplinaria y laboral según normativas internas.`r`n✔ Coordinar con entes de investigación policial o judicial si hubo dolo."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase de Contención" -RowsData $faseCon

    # FASE DE ERRADICACIÓN
    $faseErr = @(
        @(
            "Erradicación: Gerencia de Ciberseguridad",
            "Destrucción definitiva y remediación de causa raíz",
            "✔ ¿Se eliminó completamente el material criptográfico comprometido?`r`n✔ ¿Se eliminó la llave de repositorios, backups y volcados de memoria?",
            "✔ Ejecutar el proceso formal de destrucción segura de la llave (Crypto-shredding) según PCI DSS 3.6.4/3.7.4.`r`n✔ Purgar repositorios Git con herramientas especializadas (git filter-repo/BFG) e invalidar commits históricos expuestos.`r`n✔ Deshabilitar permanentemente protocols/ciphers débiles identificados en el Inventario 12.3.3."
        ),
        @(
            "Erradicación: CISO",
            "Aprobación de la Estrategia ante Cambios y Vulnerabilidades",
            "✔ ¿El nuevo algoritmo cumple con la Estrategia Documentada para responder a vulnerabilidades anticipadas (Req. 12.3.3)?`r`n✔ ¿Se aprueba la transición de arquitectura criptográfica?",
            "✔ Formalizar y aprobar la actualización de los conjuntos de cifrado autorizados en la arquitectura del Banco.`r`n✔ Aprobar nuevos controles de seguridad y endurecimiento en plataformas centrales."
        ),
        @(
            "Erradicación: Legal, RRHH y Comunicaciones",
            "Cierre de responsabilidades y reevaluación legal",
            "✔ ¿Se derivaron responsabilidades civiles o penales adicionales?`r`n✔ ¿Hay requerimientos de información de entes externos?",
            "✔ Concluir expedientes de auditoría interna y remitir a entes correspondientes.`r`n✔ Dar respuesta formal y documentada a las marcas y entes reguladores."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase de Erradicación" -RowsData $faseErr

    # FASE DE RECUPERACIÓN
    $faseRec = @(
        @(
            "Recuperación: Administración de Seguridad",
            "Generación y distribución segura de nuevo material criptográfico",
            "✔ ¿Cómo se coordina la ceremonia lógica de nuevas llaves?`r`n✔ ¿En qué plataformas se realiza la inyección (HSM, AS400, POS, AZ7)?",
            "✔ Ejecutar Ceremonia de Llaves bajo esquema de doble control y conocimiento dividido (Dual Control / Split Knowledge).`r`n✔ En caso de POS: Generar criptograma, inyectar en terminales mediante proceso seguro de telecarga.`r`n✔ En caso de Franquicias: Coordinar intercambio seguro de llaves de zona con Visa/Mastercard (tiempos estándar de operadoras).`r`n✔ En caso de bases de datos: Cargar nueva DEK y ejecutar proceso de recifrado (re-encryption) de datos en reposo (PAN)."
        ),
        @(
            "Recuperación: CISO y Operaciones TI",
            "Validación integral de servicios y reactivación operativa",
            "✔ ¿Las pruebas transaccionales confirman integridad y cifrado robusto?`r`n✔ ¿Se reactivan los servicios en tiempo pactado?",
            "✔ Monitorear el switch transaccional tras la inyección de nuevas llaves.`r`n✔ Validar cero rechazos criptográficos con operadoras y franquicias.`r`n✔ Declarar formalmente el retorno a la operación estándar de negocio."
        ),
        @(
            "Recuperación: Legal, RRHH y Comunicaciones",
            "Documentación final y retroalimentación institucional",
            "✔ ¿Se completaron todas las actas de remediación y acuerdos regulatorios?`r`n✔ ¿Qué comunicación de cierre se emite?",
            "✔ Archivar actas de generación y custodia del nuevo material criptográfico.`r`n✔ Confirmar a las partes interesadas el restablecimiento total del servicio."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase de Recuperación" -RowsData $faseRec

    # FASE POST-INCIDENTE
    $fasePost = @(
        @(
            "Post-Incidente: Ciberseguridad / Administración / CISO",
            "Actualización del Inventario 12.3.3 y Lecciones Aprendidas",
            "✔ ¿Qué falló en el control lógico anterior?`r`n✔ ¿Se actualizó el Inventario de Protocolos y Ciphers con el propósito y ubicación de la nueva llave?`r`n✔ ¿Cuándo corresponde la próxima revisión obligatoria de 12 meses?",
            "✔ Actualizar inmediatamente el Inventario Oficial de Protocolos y Cipher Suites en Uso (PCI DSS Req. 12.3.3).`r`n✔ Registrar la evaluación de viabilidad del nuevo algoritmo frente a tendencias tecnológicas.`r`n✔ Establecer formalmente la fecha de la próxima Revisión Anual Obligatoria (máximo 12 meses).`r`n✔ Conducir sesión de Lecciones Aprendidas y actualizar el presente Playbook."
        ),
        @(
            "Post-Incidente: Soporte Técnico y Operaciones TI",
            "Capacitación, blindaje y cierre de infraestructura",
            "✔ ¿Qué herramientas automáticas de detección de llaves deben instalarse en el pipeline CI/CD?`r`n✔ ¿Hay requerimientos de monitoreo adicional?",
            "✔ Implementar hooks y escaneo automático de secretos en repositorios DevOps.`r`n✔ Cerrar formalmente todos los tickets de incidencia y cambios de emergencia en ITSM."
        ),
        @(
            "Post-Incidente: Monitoreo de Seguridad (SOC)",
            "Optimización de reglas de detección y monitoreo continuo",
            "✔ ¿Cómo evitar recurrencias del vector de fuga lógica?`r`n✔ ¿Se crearon correlaciones SIEM para llamadas a KMS no autorizadas?",
            "✔ Afinar reglas de correlación SIEM/DLP para tráfico de llaves y certificados.`r`n✔ Incorporar monitoreo de caducidad y cambios de suites en tiempo real."
        ),
        @(
            "Post-Incidente: Alta Dirección",
            "Gobernanza, presupuesto y reporte a Junta Directiva",
            "✔ ¿Qué inversiones en criptografía o HSMs se requieren para mantener la viabilidad de la entidad frente a tendencias?",
            "✔ Aprobar planes de inversión para agilidad criptográfica y preparación post-cuántica.`r`n✔ Recibir el informe final de cierre para auditoría PCI DSS y entes regulatorios."
        )
    )
    Add-PhaseTable -PhaseTitle "Fase Post-Incidente (Auditoría y Lecciones Aprendidas)" -RowsData $fasePost

    # =========================================================================
    # 8. APROBACIÓN DEL DOCUMENTO
    # =========================================================================
    Write-Host "[INFO] Generando Cuadro de Aprobación..." -ForegroundColor Yellow
    Add-H1 -Text "I. Aprobación del Documento"
    Add-P -Text "El presente Playbook de Gestión de Incidentes de Seguridad por Exposición de Llave Criptográfica Lógica ha sido elaborado, revisado y aprobado conforme a la estructura de gobernanza de Banesco Banco Universal y los estándares internacionales de PCI DSS v4.0:" -Align 3

    $tApr = $Doc.Tables.Add((Get-DocEnd), 3, 3)
    $tApr.Borders.InsideLineStyle = 1
    $tApr.Borders.OutsideLineStyle = 1
    $tApr# border color
    $tApr.Columns.Item(1).SetWidth(150, 0)
    $tApr.Columns.Item(2).SetWidth(150, 0)
    $tApr.Columns.Item(3).SetWidth(150, 0)

    $tApr.Cell(1, 1).Range.Text = "Elaborado por:"
    $tApr.Cell(1, 2).Range.Text = "Revisado por:"
    $tApr.Cell(1, 3).Range.Text = "Aprobado por:"
    for ($c = 1; $c -le 3; $c++) {
        $cell = $tApr.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.ParagraphFormat.Alignment = 1
    }

    $tApr.Cell(2, 1).Range.Text = "Carmen Anseume`r`nConsultor Netready / Auditor Ciberseguridad"
    $tApr.Cell(2, 2).Range.Text = "Hindelver Mogollon`r`nGerente de Ciberseguridad"
    $tApr.Cell(2, 3).Range.Text = "Jesus Irausquin`r`nVP Seguridad Integral de la Información y Datos"
    for ($c = 1; $c -le 3; $c++) {
        $tApr.Cell(2, $c).Range.Font.Size = 9
        $tApr.Cell(2, $c).Range.ParagraphFormat.Alignment = 1
    }

    $tApr.Cell(3, 1).Range.Text = "Fecha: 12/11/2026"
    $tApr.Cell(3, 2).Range.Text = "Fecha: 12/11/2026"
    $tApr.Cell(3, 3).Range.Text = "Fecha: 12/11/2026"
    for ($c = 1; $c -le 3; $c++) {
        $tApr.Cell(3, $c).Range.Font.Size = 9
        $tApr.Cell(3, $c).Range.Font.Bold = 1
        $tApr.Cell(3, $c).Range.ParagraphFormat.Alignment = 1
    }
    Add-TBreak
    $Doc.Words.Last.InsertBreak(7) # Salto de página

    # =========================================================================
    # 9. ANEXOS NORMATIVOS PCI DSS v4.0 REQUISITO 12.3.3
    # =========================================================================
    Write-Host "[INFO] Generando Anexos Normativos de Cumplimiento..." -ForegroundColor Yellow
    Add-H1 -Text "Anexo A: Plantilla Oficial de Inventario de Protocolos y Cipher Suites (PCI DSS Req. 12.3.3)"
    Add-P -Text "Para solventar de forma concluyente la observación del auditor, la organización mantiene y opera el siguiente inventario actualizado, el cual vincula cada elemento criptográfico con su propósito, ubicación de uso, fortaleza y estado de viabilidad:" -Align 3

    $tInv = $Doc.Tables.Add((Get-DocEnd), 5, 6)
    $tInv.Borders.InsideLineStyle = 1
    $tInv.Borders.OutsideLineStyle = 1
    $tInv# border color
    $tInv.Columns.Item(1).SetWidth(70, 0)
    $tInv.Columns.Item(2).SetWidth(75, 0)
    $tInv.Columns.Item(3).SetWidth(80, 0)
    $tInv.Columns.Item(4).SetWidth(85, 0)
    $tInv.Columns.Item(5).SetWidth(75, 0)
    $tInv.Columns.Item(6).SetWidth(65, 0)

    $tInv.Cell(1, 1).Range.Text = "ID / Componente"
    $tInv.Cell(1, 2).Range.Text = "Ubicación de Uso"
    $tInv.Cell(1, 3).Range.Text = "Propósito Criptográfico"
    $tInv.Cell(1, 4).Range.Text = "Protocolo / Cipher Suite"
    $tInv.Cell(1, 5).Range.Text = "Viabilidad (Tendencia)"
    $tInv.Cell(1, 6).Range.Text = "Revisión (12 Meses)"

    for ($c = 1; $c -le 6; $c++) {
        $cell = $tInv.Cell(1, $c)
        $cell.Shading.BackgroundPatternColor = $cAzulHeader
        $cell.Range.Font.Bold = 1
        $cell.Range.Font.Color = $cBlanco
        $cell.Range.Font.Size = 8
        $cell.Range.ParagraphFormat.Alignment = 1
    }

    $invRows = @(
        @("HSM-PAY-01`r`n(Thales PayShield)", "Datacenter Ppal.`r`nRack Seg. HSM", "Traducción de PIN Block y generación de ZPK de adquirencia", "ANSI X9.24 / AES-256 / DUKPT 3DES (en transición)", "Vigente (NIST SP 800-131A)`r`nMigración DUKPT AES en curso", "12/11/2026`r`n[Conforme]"),
        @("CORE-AZ7-SRV`r`n(AZ7 Switch)", "Servidores App`r`nZona CDE VLAN-10", "Cifrado de transacciones financieras y autorización POS/ATM", "ISO 8583 / AES-256-GCM / TLS 1.3", "Vigente y robusto`r`nMonitoreo trimestral", "12/11/2026`r`n[Conforme]"),
        @("IBM-i-S101`r`n(AS400 DB2)", "Core Bancario`r`nServidor Maestro", "Cifrado de campos de datos sensitivos en reposo (PAN)", "DB2 FieldProc / AES-256 / KEK Master Cryptgrip", "Vigente`r`nResistente a ataques conocidos", "12/11/2026`r`n[Conforme]"),
        @("WAF-GW-EXT`r`n(Banca Digital)", "DMZ Perimetral`r`nReverse Proxy", "Cifrado en tránsito para transacciones web y móviles", "TLS 1.3 / TLS_AES_256_GCM_SHA384`r`n(TLS 1.0/1.1 deshabilitados)", "Excelente viabilidad`r`nSin suites obsoletas", "12/11/2026`r`n[Conforme]")
    )

    for ($r = 0; $r -lt $invRows.Count; $r++) {
        for ($c = 0; $c -lt 6; $c++) {
            $tInv.Cell($r + 2, $c + 1).Range.Text = $invRows[$r][$c]
            $tInv.Cell($r + 2, $c + 1).Range.Font.Size = 8
        }
    }
    Add-TBreak

    Add-H1 -Text "Anexo B: Procedimiento de Monitoreo Activo de Viabilidad y Estrategia ante Vulnerabilidades Anticipadas"
    Add-P -Text "1. Fuentes Oficiales de Monitoreo Activo de Tendencias: El equipo de Ciberseguridad supervisa trimestralmente las publicaciones de NIST (SP 800-57, SP 800-131A), boletines de PCI SSC, avisos de CVE/NVD y lineamientos de Franquicias (Visa / Mastercard) para catalogar cualquier síntoma de debilitamiento en los algoritmos empleados." -Align 3
    Add-P -Text "2. Estrategia de Respuesta ante Vulnerabilidades Anticipadas (Agilidad Criptográfica): Cuando un algoritmo o suite de cifrado entra en fase de 'Deprecación Planificada' por la industria, Banesco activa automáticamente un plan de transición que contempla: (a) Deshabilitación de suites débiles en balanceadores; (b) Rotación programada de llaves a longitud mínima recomendada (AES-256 / RSA >= 3072 / ECC P-384); (c) Pruebas de compatibilidad con operadoras antes de la fecha límite establecida." -Align 3
    Add-P -Text "3. Ciclo de Revisión Periódica Anual Obligatoria (Cada 12 Meses): En cumplimiento taxativo del Requisito 12.3.3, la Gerencia de Ciberseguridad y la Administración de Seguridad de la Información convocan anualmente el Comité Técnico de Revisión Criptográfica, emitiendo un Acta de Auditoría con validez formal que certifica la viabilidad de todos los componentes activos." -Align 3

    # Guardar documento
    Write-Host "[INFO] Guardando archivos Word..." -ForegroundColor Yellow
    $Doc.SaveAs([ref]$DocPath1)
    $Doc.SaveAs([ref]$DocPath2)
    Write-Host "[OK] Documento generado exitosamente en:" -ForegroundColor Green
    Write-Host "     1. $DocPath1" -ForegroundColor Green
    Write-Host "     2. $DocPath2" -ForegroundColor Green

}
catch {
    Write-Host "[ERROR] Ocurrió una excepción al generar el documento Word: $_" -ForegroundColor Red
}
finally {
    if ($Doc) { $Doc.Close([ref]$false) }
    if ($Word) { $Word.Quit() }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Word) | Out-Null
}


