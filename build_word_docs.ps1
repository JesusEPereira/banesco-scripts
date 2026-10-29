# Script PowerShell para la generación de Documentos Word (.docx) de Powertech Antivirus
$destDir = "D:\Cerebro Digital\06_Antivirus_StandGuard\01_Documentacion_y_Diagramas"

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

# Helper function to style headings
function Add-Header ($doc, $text, $level) {
    $p = $doc.Paragraphs.Add()
    $p.Range.Text = $text
    $p.Range.Font.Name = "Segoe UI"
    $p.Range.Font.Bold = 1
    if ($level -eq 1) {
        $p.Range.Font.Size = 18
        $p.Range.Font.Color = 12615680 # Primary Blue
        $p.SpaceBefore = 14
        $p.SpaceAfter = 6
    } elseif ($level -eq 2) {
        $p.Range.Font.Size = 14
        $p.Range.Font.Color = 4210752 # Dark Slate
        $p.SpaceBefore = 10
        $p.SpaceAfter = 4
    } else {
        $p.Range.Font.Size = 12
        $p.Range.Font.Color = 0
        $p.SpaceBefore = 6
        $p.SpaceAfter = 2
    }
    $p.Range.InsertParagraphAfter()
}

function Add-Text ($doc, $text, $bold=$false, $italic=$false) {
    $p = $doc.Paragraphs.Add()
    $p.Range.Text = $text
    $p.Range.Font.Name = "Calibri"
    $p.Range.Font.Size = 11
    $p.Range.Font.Color = 0
    $p.Range.Font.Bold = [int]$bold
    $p.Range.Font.Italic = [int]$italic
    $p.SpaceBefore = 0
    $p.SpaceAfter = 4
    $p.Range.InsertParagraphAfter()
}

function Add-CodeBlock ($doc, $text) {
    $p = $doc.Paragraphs.Add()
    $p.Range.Text = $text
    $p.Range.Font.Name = "Consolas"
    $p.Range.Font.Size = 10
    $p.Range.Font.Color = 2631720 # Dark Gray Code
    $p.Range.Shading.BackgroundPatternColor = 15790320 # Light Gray shading
    $p.SpaceBefore = 4
    $p.SpaceAfter = 6
    $p.Range.InsertParagraphAfter()
}

# ==========================================
# 1. GENERACIÓN DEL INFORME EJECUTIVO
# ==========================================
Write-Host "Generando Informe Ejecutivo en Word..."
$doc1 = $word.Documents.Add()

# Title & Subtitle
$pTitle = $doc1.Paragraphs.Add()
$pTitle.Range.Text = "INFORME EJECUTIVO Y TÉCNICO`nPOWERTECH ANTIVIRUS FOR IBM i (STANDGUARD)"
$pTitle.Range.Font.Name = "Segoe UI"
$pTitle.Range.Font.Size = 22
$pTitle.Range.Font.Bold = 1
$pTitle.Range.Font.Color = 12615680
$pTitle.Alignment = 1 # Center
$pTitle.SpaceAfter = 8
$pTitle.Range.InsertParagraphAfter()

$pSub = $doc1.Paragraphs.Add()
$pSub.Range.Text = "Evaluación de Seguridad, Protección Anti-Ransomware en IFS e Integración Tecnológica`nOrganización: Cerebro Digital / Infraestructura IBM i`nFecha: Agosto 2026"
$pSub.Range.Font.Name = "Segoe UI"
$pSub.Range.Font.Size = 12
$pSub.Range.Font.Italic = 1
$pSub.Range.Font.Color = 5263440
$pSub.Alignment = 1 # Center
$pSub.SpaceAfter = 24
$pSub.Range.InsertParagraphAfter()

Add-Header $doc1 "1. Resumen Ejecutivo e Identificación de Solución" 1
Add-Text $doc1 "Powertech Antivirus for IBM i (desarrollado por Fortra / HelpSystems en alianza estratégica con McAfee) es la única solución de ciberseguridad comercial diseñada de forma nativa para proteger entornos IBM i (AS/400), AIX (UNIX) y Linux en servidores Power."
Add-Text $doc1 "A diferencia de las arquitecturas de escaneo remoto basadas en clientes Windows o recursos de red compartidos, Powertech Antivirus se ejecuta directamente sobre el Kernel y el Sistema de Archivos Integrado (IFS) de IBM i, aprovechando el motor de análisis heurístico y las firmas de virus de alto rendimiento de McAfee."

Add-Header $doc1 "2. Evaluación Comparativa: Antivirus Nativo vs. Escaneo Remoto" 1
Add-Text $doc1 "La siguiente tabla detalla la evaluación técnica y las ventajas de contar con una solución de protección nativa frente a escaneos remotos por red:"

# Table 1
$table1 = $doc1.Tables.Add($doc1.Paragraphs.Add().Range, 6, 3)
$table1.Borders.Enable = 1
$headers = @("Criterio de Evaluación", "Solución Nativa (Powertech Antivirus)", "Escaneo Remoto (No Nativo)")
for ($c=1; $c -le 3; $c++) {
    $cell = $table1.Cell(1, $c).Range
    $cell.Text = $headers[$c-1]
    $cell.Font.Bold = 1
    $cell.Font.Name = "Segoe UI"
    $cell.Font.Size = 10
    $cell.Font.Color = 16777215
    $table1.Cell(1, $c).Shading.BackgroundPatternColor = 12615680
}

$matrix = @(
    @("Velocidad de Detección", "Inmediata al crear/abrir el archivo en el IFS", "Retardada (horas o inexistente hasta el escaneo programado)"),
    @("Impacto en Red y CPU", "Cero consumo de red; escaneo único por hash", "Alto tráfico de red (descarga constante de bytes del IFS)"),
    @("Gestión de Alertas", "Notificación instantánea a colas de mensajes (AVMSGQ)", "Sin alertas nativas; no puede tomar acciones defensivas"),
    @("Protección Anti-Ransomware", "Supervisión activa del servicio NetServer en tiempo real", "Incapaz de prevenir la encriptación masiva en curso"),
    @("Riesgos de Privilegios", "Sin compartir directorios ni usar súper-usuarios remotos", "Requiere credenciales elevadas compartidas en red")
)

for ($r=2; $r -le 6; $r++) {
    for ($c=1; $c -le 3; $c++) {
        $cell = $table1.Cell($r, $c).Range
        $cell.Text = $matrix[$r-2][$c-1]
        $cell.Font.Name = "Calibri"
        $cell.Font.Size = 10
    }
}
$doc1.Paragraphs.Add().Range.InsertParagraphAfter()

Add-Header $doc1 "3. Protección Anti-Ransomware en el IFS (Servicio NetServer)" 1
Add-Text $doc1 "A partir de la actualización de abril de 2022, Powertech Antivirus incluye una capa especializada de protección contra ataques de Ransomware originados en estaciones de trabajo externas."
Add-Text $doc1 "Mecanismo de Acción:" -bold $true
Add-Text $doc1 "• Supervisión Continua de NetServer: Monitorea las operaciones de escritura y modificación masiva en las carpetas compartidas del IFS."
Add-Text $doc1 "• Bloqueo Preventivo de Usuarios: Si una estación de trabajo infectada intenta encriptar archivos del IFS, el sistema detiene inmediatamente el proceso y deshabilita la sesión del usuario atacante."
Add-Text $doc1 "• Notificación de Incidencia: Emite una alerta de alta prioridad en la cola de mensajes del sistema para intervención del equipo de SOC."

Add-Header $doc1 "4. Arquitectura de Actualización de Firmas y Gestión Insite" 1
Add-Text $doc1 "Powertech Antivirus se conecta con los servidores oficiales de McAfee (http://update.nai.com/products/commonupdater/) para la descarga automatizada de archivos de firmas DATs (oem.ini, gdeltaavv.ini, avvdat-*.zip)."
Add-Text $doc1 "Toda la infraestructura se integra con la consola centralizada Powertech Insite, permitiendo visualizar cuadros de mando en tiempo real con el estado de endpoints, dispositivos en cuarentena y alertas de seguridad."

Add-Header $doc1 "5. Cumplimiento Normativo (PCI DSS, ISO 27001)" 1
Add-Text $doc1 "La implementación de Powertech Antivirus garantiza el cumplimiento del requerimiento 5 de PCI DSS (Mantener programas antivirus actualizados en todos los sistemas afectados) y los controles de protección contra código malicioso de ISO 27001 (A.12.2)."

$fileDoc1 = Join-Path $destDir "Informe_Ejecutivo_Powertech_Antivirus_IBM_i.docx"
$doc1.SaveAs2("$fileDoc1", 16)
$doc1.Close()
Write-Host "Informe Ejecutivo guardado exitosamente en $fileDoc1"

# ==========================================
# 2. GENERACIÓN DEL MANUAL DE PROCEDIMIENTOS
# ==========================================
Write-Host "Generando Manual de Procedimientos en Word..."
$doc2 = $word.Documents.Add()

# Title & Subtitle
$pTitle2 = $doc2.Paragraphs.Add()
$pTitle2.Range.Text = "MANUAL DE PROCEDIMIENTOS OPERATIVOS`nPOWERTECH ANTIVIRUS FOR IBM i"
$pTitle2.Range.Font.Name = "Segoe UI"
$pTitle2.Range.Font.Size = 22
$pTitle2.Range.Font.Bold = 1
$pTitle2.Range.Font.Color = 12615680
$pTitle2.Alignment = 1
$pTitle2.SpaceAfter = 8
$pTitle2.Range.InsertParagraphAfter()

$pSub2 = $doc2.Paragraphs.Add()
$pSub2.Range.Text = "Guía de Configuración, Escaneo en Tiempo Real, Gestión de Cuarentenas y Actualización de Firmas`nBiblioteca Principal: STANDGUARD / PTCSLIB`nFecha: Agosto 2026"
$pSub2.Range.Font.Name = "Segoe UI"
$pSub2.Range.Font.Size = 12
$pSub2.Range.Font.Italic = 1
$pSub2.Range.Font.Color = 5263440
$pSub2.Alignment = 1
$pSub2.SpaceAfter = 24
$pSub2.Range.InsertParagraphAfter()

Add-Header $doc2 "Capítulo 1. Navegación del Menú Principal (AVMENU)" 1
Add-Text $doc2 "Para acceder al entorno de gestión interactivo de Powertech Antivirus en IBM i, ejecute el comando AVMENU desde la línea de comandos:"
Add-CodeBlock $doc2 "AVMENU"
Add-Text $doc2 "Estructura del Menú AVMENU:" -bold $true
Add-Text $doc2 "  1. Submit a virus scan task (Iniciar tarea de escaneo de virus)"
Add-Text $doc2 "  2. Submit an object integrity scan task (Tarea de integridad de objetos)"
Add-Text $doc2 "  3. Work with scan jobs (Trabajar con trabajos de escaneo)"
Add-Text $doc2 "  4. Work with job schedule entries (Trabajar con planificador de trabajos)"
Add-Text $doc2 " 10. Work with logs (Inspeccionar archivos de registro)"
Add-Text $doc2 " 11. Display messages (Visualizar mensajes de alertas)"
Add-Text $doc2 " 12. Work with quarantined files (Trabajar con archivos en cuarentena)"
Add-Text $doc2 " 20. Download latest virus definitions - DATs (Descargar firmas de virus)"
Add-Text $doc2 " 21. Download latest program updates - PTFs (Descargar actualizaciones de programa)"
Add-Text $doc2 " 50. Setup Menu | 51. Support Menu | 52. License Menu"

Add-Header $doc2 "Capítulo 2. Configuración de Escaneo en Tiempo Real (AVCHGA)" 1
Add-Text $doc2 "El comando AVCHGA (Change AV On-Access Attributes) permite configurar el comportamiento de la protección en tiempo real (On-Access) sobre el sistema de archivos IFS:"
Add-CodeBlock $doc2 "AVCHGA ONACC(*OPNCLO) CLEAN(*YES) FAILED(*QRN) HEURISTIC(*YES) MACRO(*YES) SCANARCH(*YES) EXCLDIR('/avtestdir2')"

Add-Text $doc2 "Parámetros Principales de Configuración:" -bold $true
Add-Text $doc2 "• On-Access type (*OPNCLO): Analiza los archivos al ser abiertos y cerrados por cualquier proceso."
Add-Text $doc2 "• Clean infected files (*YES): Intenta la desinfección automática del archivo."
Add-Text $doc2 "• Action if not cleaned (*QRN): Mueve los archivos no desinfectados al directorio de cuarentena."
Add-Text $doc2 "• Heuristic analysis (*YES): Activa la detección por comportamiento heurístico de malware no registrado."
Add-Text $doc2 "• Exclude directories: Permite definir rutas excluidas del escaneo en tiempo real (ej. '/avtestdir2')."

Add-Header $doc2 "Capítulo 3. Ejecución de Escaneos Bajo Demanda (AVSCAN)" 1
Add-Text $doc2 "Para ejecutar un análisis a petición sobre un directorio o archivo específico del IFS, utilice el comando AVSCAN:"
Add-CodeBlock $doc2 "AVSCAN OBJ('/avtestdir2') SUBTREE(*ALL) HEURISTIC(*YES) CLEAN(*NO) FAILED(*QRN) LOGLVL(*DETAILED)"

Add-Header $doc2 "Capítulo 4. Gestión de Alertas y Tratamiento de Cuarentenas" 1
Add-Text $doc2 "4.1 Visualización de Alertas:" -bold $true
Add-Text $doc2 "Para revisar los mensajes de virus detectados en la cola de mensajes oficial:"
Add-CodeBlock $doc2 "DSPMSG STANDGUARD/AVMSGQ"

Add-Text $doc2 "4.2 Tratamiento de Cuarentena y Reversión:" -bold $true
Add-Text $doc2 "Los archivos bloqueados son aislados en la ruta /Quarantined/ y marcados con estado 'Object marked as a scan failure'. Si se confirma que se trata de un falso positivo, utilice el comando CHGATR para resetear el atributo de escaneo y permitir su uso normal:"
Add-CodeBlock $doc2 "CHGATR OBJ('/Quarantined/avtestdir1/archivo.xls') ATR(*SCAN) VALUE(*NO)"

Add-Header $doc2 "Capítulo 5. Procedimiento Automatizado de Descarga e Importación de Firmas" 1
Add-Text $doc2 "5.1 Descarga de Firmas McAfee desde Windows (PowerShell):" -bold $true
Add-CodeBlock $doc2 "`$url = 'http://update.nai.com/products/commonupdater/'`nInvoke-WebRequest (`$url + 'oem.ini') -OutFile 'oem.ini'`nInvoke-WebRequest (`$url + 'gdeltaavv.ini') -OutFile 'gdeltaavv.ini'`n`$site = Invoke-WebRequest -UseBasicParsing -Uri `$url`n`$table = `$site.links | ?{ `$_.href.ToLower().Contains('avvdat-') } | sort href -desc | select -first 1`n`$filename = `$table.href.ToString()`nInvoke-WebRequest (`$url + `$filename) -OutFile `$filename`nExpand-Archive -Force `$filename ."

Add-Text $doc2 "5.2 Carga de Archivos de Firmas vía FTP a IBM i:" -bold $true
Add-Text $doc2 "Transfiera los archivos descargados a la ruta del IFS /standguard/firmas utilizando el formato de nombres tipo 1:"
Add-CodeBlock $doc2 "ftp 10.229.1.6`nUsuario: banasia029`nbin`nquote site namefmt 1`ncd /standguard/firmas`nmput *.ini`nput avvdat-XXXXX.zip"

Add-Header $doc2 "Capítulo 6. Prueba de Verificación con Archivo Test EICAR" 1
Add-Text $doc2 "Para validar de forma segura que el motor antivirus está interceptando archivos en tiempo real sin riesgo operacional, cree un archivo de texto en el IFS conteniendo la cadena estandarizada EICAR:"
Add-CodeBlock $doc2 "X5O!P%@AP[4\PZX54(P^)7CC)7}`$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!`$H+H*"
Add-Text $doc2 "Al intentar guardar o acceder al archivo, Powertech Antivirus lo aislará inmediatamente y emitirá el aviso de seguridad en la cola AVMSGQ."

$fileDoc2 = Join-Path $destDir "Manual_de_Procedimientos_Powertech_Antivirus_IBM_i.docx"
$doc2.SaveAs2("$fileDoc2", 16)
$doc2.Close()
Write-Host "Manual de Procedimientos guardado exitosamente en $fileDoc2"

$word.Quit()
Write-Host "Proceso finalizado con éxito."
