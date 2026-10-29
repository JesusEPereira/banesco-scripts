# Script PowerShell para la creación 100% legible y formateada de Documentos Word (.docx)

$destDir = "D:\Cerebro Digital\06_Antivirus_StandGuard\01_Documentacion_y_Diagramas"

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

function Fix-Text ($t) {
    if ([string]::IsNullOrEmpty($t)) { return $t }
    $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($t)
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

# Helper functions for Selection-based writing (Guarantees zero overlap and 100% legible formatting)

function Write-Title ($selection, $text) {
    $selection.Font.Name = "Arial"
    $selection.Font.Size = 22
    $selection.Font.Bold = 1
    $selection.Font.ColorIndex = 2 # Dark Blue
    $selection.ParagraphFormat.Alignment = 1 # Center
    $selection.ParagraphFormat.SpaceAfter = 12
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
}

function Write-Subtitle ($selection, $text) {
    $selection.Font.Name = "Arial"
    $selection.Font.Size = 12
    $selection.Font.Bold = 0
    $selection.Font.Italic = 1
    $selection.Font.ColorIndex = 6 # Dark Gray
    $selection.ParagraphFormat.Alignment = 1 # Center
    $selection.ParagraphFormat.SpaceAfter = 24
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
}

function Write-Heading1 ($selection, $text) {
    $selection.Font.Name = "Arial"
    $selection.Font.Size = 16
    $selection.Font.Bold = 1
    $selection.Font.Italic = 0
    $selection.Font.ColorIndex = 2 # Dark Blue
    $selection.ParagraphFormat.Alignment = 0 # Left
    $selection.ParagraphFormat.SpaceBefore = 14
    $selection.ParagraphFormat.SpaceAfter = 6
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
}

function Write-Heading2 ($selection, $text) {
    $selection.Font.Name = "Arial"
    $selection.Font.Size = 13
    $selection.Font.Bold = 1
    $selection.Font.Italic = 0
    $selection.Font.ColorIndex = 1 # Black
    $selection.ParagraphFormat.Alignment = 0
    $selection.ParagraphFormat.SpaceBefore = 10
    $selection.ParagraphFormat.SpaceAfter = 4
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
}

function Write-Paragraph ($selection, $text) {
    $selection.Font.Name = "Calibri"
    $selection.Font.Size = 11
    $selection.Font.Bold = 0
    $selection.Font.Italic = 0
    $selection.Font.ColorIndex = 1 # Black
    $selection.ParagraphFormat.Alignment = 0
    $selection.ParagraphFormat.SpaceBefore = 0
    $selection.ParagraphFormat.SpaceAfter = 6
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
}

function Write-Bullet ($selection, $text) {
    $selection.Font.Name = "Calibri"
    $selection.Font.Size = 11
    $selection.Font.Bold = 0
    $selection.Font.Italic = 0
    $selection.Font.ColorIndex = 1
    $selection.ParagraphFormat.Alignment = 0
    $selection.ParagraphFormat.LeftIndent = 18
    $selection.ParagraphFormat.SpaceAfter = 3
    $selection.TypeText("• " + (Fix-Text $text))
    $selection.TypeParagraph()
    $selection.ParagraphFormat.LeftIndent = 0
}

function Write-CodeSnippet ($selection, $text) {
    $selection.Font.Name = "Consolas"
    $selection.Font.Size = 10
    $selection.Font.Bold = 0
    $selection.Font.ColorIndex = 1
    $selection.ParagraphFormat.Alignment = 0
    $selection.ParagraphFormat.LeftIndent = 12
    $selection.ParagraphFormat.SpaceBefore = 4
    $selection.ParagraphFormat.SpaceAfter = 6
    $selection.TypeText((Fix-Text $text))
    $selection.TypeParagraph()
    $selection.ParagraphFormat.LeftIndent = 0
}

# ==========================================
# 1. CREACIÓN DEL INFORME EJECUTIVO Y TÉCNICO
# ==========================================
Write-Host "Iniciando creación del Informe Ejecutivo..."
$doc1 = $word.Documents.Add()
$sel1 = $word.Selection

Write-Title $sel1 "INFORME EJECUTIVO Y TÉCNICO`nPOWERTECH ANTIVIRUS FOR IBM i"
Write-Subtitle $sel1 "Evaluación de Ciberseguridad, Protección Anti-Ransomware en IFS e Integración Tecnológica`nCerebro Digital / Infraestructura IBM i (AS/400)`nFecha: Agosto 2026"

Write-Heading1 $sel1 "1. Resumen Ejecutivo e Identificación de la Solución"
Write-Paragraph $sel1 "Powertech Antivirus for IBM i (desarrollado por Fortra / HelpSystems en alianza estratégica con McAfee) es la única solución comercial de ciberseguridad diseñada de forma nativa para proteger entornos IBM i (AS/400), AIX (UNIX) y Linux en servidores Power."
Write-Paragraph $sel1 "A diferencia de las soluciones de escaneo remoto basadas en clientes Windows o unidades compartidas por red, Powertech Antivirus se ejecuta directamente sobre el Kernel y el Sistema de Archivos Integrado (IFS) de IBM i, utilizando el motor de búsqueda heurística y las firmas de virus de McAfee de alto rendimiento."

Write-Heading1 $sel1 "2. Evaluación Comparativa: Antivirus Nativo vs. Escaneo Remoto"
Write-Paragraph $sel1 "A continuación se presenta el análisis comparativo entre la protección nativa en IBM i y las alternativas no nativas por red:"

# Tabla Comparativa 1
$table1 = $doc1.Tables.Add($sel1.Range, 6, 3)
$table1.Borders.Enable = 1
$headers1 = @("Criterio de Evaluación", "Solución Nativa (Powertech Antivirus)", "Escaneo Remoto (No Nativo)")

for ($c=1; $c -le 3; $c++) {
    $cell = $table1.Cell(1, $c).Range
    $cell.Text = Fix-Text $headers1[$c-1]
    $cell.Font.Name = "Arial"
    $cell.Font.Bold = 1
    $cell.Font.Size = 10
    $cell.Font.ColorIndex = 6 # White
    $table1.Cell(1, $c).Shading.BackgroundPatternColor = 12615680 # Blue Header
}

$matrix1 = @(
    @("Velocidad de Detección", "Inmediata al crear o abrir el archivo en el IFS (On-Access)", "Retardada (horas o inexistente hasta el escaneo programado)"),
    @("Impacto en Red y Servidor", "Cero uso de ancho de banda de red; escaneo único por hash", "Alto tráfico de red (descarga constante de todos los bytes del IFS)"),
    @("Gestión de Alertas", "Notificación instantánea a colas de mensajes (AVMSGQ)", "Sin alertas nativas en IBM i; no puede tomar acciones defensivas"),
    @("Protección Anti-Ransomware", "Supervisión activa del servicio NetServer en tiempo real", "Incapaz de prevenir la encriptación masiva de archivos en curso"),
    @("Seguridad de Credenciales", "Sin compartir directorios ni usar súper-usuarios remotos", "Requiere credenciales elevadas compartidas en la red local")
)

for ($r=2; $r -le 6; $r++) {
    for ($c=1; $c -le 3; $c++) {
        $cell = $table1.Cell($r, $c).Range
        $cell.Text = Fix-Text $matrix1[$r-2][$c-1]
        $cell.Font.Name = "Calibri"
        $cell.Font.Size = 10
        if ($r % 2 -eq 0) {
            $table1.Cell($r, $c).Shading.BackgroundPatternColor = 15790320 # Alternate Row Light Gray
        }
    }
}

# Move selection past table
$sel1.SetRange($table1.Range.End, $table1.Range.End)
$sel1.TypeParagraph()

Write-Heading1 $sel1 "3. Protección Anti-Ransomware en el IFS (Servicio NetServer)"
Write-Paragraph $sel1 "Con la funcionalidad avanzada de protección contra Ransomware (disponible desde abril de 2022), Powertech Antivirus incorpora una barrera activa para prevenir ataques originados desde estaciones de trabajo o servidores Windows infectados."
Write-Bullet $sel1 "Supervisión de NetServer: Monitorea de forma continua los patrones de modificación y escritura masiva en las carpetas compartidas del IFS."
Write-Bullet $sel1 "Bloqueo Preventivo Inmediato: Si detecta un intento de cifrado masivo, el antivirus interrumpe el acceso de red y deshabilita automáticamente la sesión del usuario comprometido."
Write-Bullet $sel1 "Aviso Operativo: Registra de inmediato la incidencia en la cola de mensajes de auditoría para la acción del equipo de Ciberseguridad."

Write-Heading1 $sel1 "4. Arquitectura de Actualizaciones y Gestión Centralizada Insite"
Write-Paragraph $sel1 "La solución se conecta de manera segura con los servidores oficiales de McAfee (http://update.nai.com/products/commonupdater/) para mantener actualizadas las definiciones de virus DATs (archivos oem.ini, gdeltaavv.ini y paquetes avvdat-*.zip)."
Write-Paragraph $sel1 "Asimismo, se integra plenamente con la consola web Powertech Insite, proporcionando cuadros de mando centralizados que muestran el estado de los endpoints, las conexiones activas, los archivos en cuarentena y las alertas de seguridad."

Write-Heading1 $sel1 "5. Alineación con Estándares y Cumplimiento Normativo"
Write-Paragraph $sel1 "La implementación de Powertech Antivirus en IBM i permite dar cumplimiento directo a:"
Write-Bullet $sel1 "PCI DSS Requerimiento 5: Mantener programas antivirus actualizados en todos los sistemas afectados para proteger contra malware."
Write-Bullet $sel1 "ISO 27001 Control A.12.2: Implementar controles de detección, prevención y recuperación contra código malicioso en la infraestructura crítica."

$fileDoc1 = Join-Path $destDir "Informe_Ejecutivo_Powertech_Antivirus_IBM_i.docx"
$doc1.SaveAs2("$fileDoc1", 16)
$doc1.Close()
Write-Host "Informe Ejecutivo guardado correctamente en: $fileDoc1"

# ==========================================
# 2. CREACIÓN DEL MANUAL DE PROCEDIMIENTOS
# ==========================================
Write-Host "Iniciando creación del Manual de Procedimientos..."
$doc2 = $word.Documents.Add()
$sel2 = $word.Selection

Write-Title $sel2 "MANUAL DE PROCEDIMIENTOS OPERATIVOS`nPOWERTECH ANTIVIRUS FOR IBM i"
Write-Subtitle $sel2 "Guía de Configuración, Escaneo en Tiempo Real, Gestión de Cuarentenas y Actualización de Firmas`nBiblioteca Principal: STANDGUARD / PTCSLIB`nFecha: Agosto 2026"

Write-Heading1 $sel2 "Capítulo 1. Navegación del Menú Principal (AVMENU)"
Write-Paragraph $sel2 "Para ingresar a la consola de administración interactiva de Powertech Antivirus en IBM i, ejecute el siguiente comando desde la línea de comandos:"
Write-CodeSnippet $sel2 "AVMENU"
Write-Paragraph $sel2 "Estructura y Opciones del Menú Principal AVMENU:"
Write-Bullet $sel2 "Opción 1 (Submit a virus scan task): Inicia una tarea de escaneo de virus a petición."
Write-Bullet $sel2 "Opción 2 (Submit an object integrity scan task): Ejecuta un escaneo de integridad de objetos."
Write-Bullet $sel2 "Opción 3 (Work with scan jobs): Gestionar y monitorear los trabajos de escaneo activos."
Write-Bullet $sel2 "Opción 4 (Work with job schedule entries): Administrar entradas en el planificador de trabajos."
Write-Bullet $sel2 "Opción 10 (Work with logs): Inspeccionar los archivos de historial y registros de escaneo."
Write-Bullet $sel2 "Opción 11 (Display messages): Visualizar los mensajes de alertas de seguridad."
Write-Bullet $sel2 "Opción 12 (Work with quarantined files): Administrar y revisar archivos en cuarentena."
Write-Bullet $sel2 "Opción 20 (Download latest virus definitions - DATs): Descargar firmas de virus McAfee."
Write-Bullet $sel2 "Opción 21 (Download latest program updates - PTFs): Descargar parches y actualizaciones."
Write-Bullet $sel2 "Opciones 50, 51, 52: Menús de Configuración (Setup), Soporte (Support) y Licenciamiento (License)."

Write-Heading1 $sel2 "Capítulo 2. Configuración de Escaneo en Tiempo Real (AVCHGA)"
Write-Paragraph $sel2 "El comando AVCHGA (Change AV On-Access Attributes) establece los parámetros operativos de la protección en tiempo real (On-Access) sobre el IFS:"
Write-CodeSnippet $sel2 "AVCHGA ONACC(*OPNCLO) CLEAN(*YES) FAILED(*QRN) HEURISTIC(*YES) MACRO(*YES) SCANARCH(*YES) EXCLDIR('/avtestdir2')"

Write-Heading2 $sel2 "Descripción de Parámetros de Configuración:"
Write-Bullet $sel2 "On-Access type (*OPNCLO): Inspecciona los archivos automáticamente en las operaciones de Apertura y Cierre (*OPEN, *OPNCLO, *NONE)."
Write-Bullet $sel2 "Clean infected files (*YES): Habilita la desinfección automática del archivo si el motor lo permite."
Write-Bullet $sel2 "Action if not cleaned (*QRN): Mueve los archivos no desinfectados al directorio seguro de cuarentena (*QRN, *DELETE, *NONE)."
Write-Bullet $sel2 "Heuristic analysis (*YES): Activa el motor de detección por comportamiento heurístico de variantes no registradas."
Write-Bullet $sel2 "Exclude directories: Permite definir rutas excluidas del escaneo en tiempo real (ejemplo: '/avtestdir2')."

Write-Heading1 $sel2 "Capítulo 3. Ejecución de Escaneos Bajo Demanda (AVSCAN)"
Write-Paragraph $sel2 "Para ejecutar un análisis a petición sobre un directorio específico o archivo del IFS, utilice el comando AVSCAN:"
Write-CodeSnippet $sel2 "AVSCAN OBJ('/avtestdir2') SUBTREE(*ALL) HEURISTIC(*YES) CLEAN(*NO) FAILED(*QRN) LOGLVL(*DETAILED)"

Write-Heading1 $sel2 "Capítulo 4. Gestión de Alertas y Tratamiento de Cuarentenas"
Write-Heading2 $sel2 "4.1 Visualización de Alertas de Seguridad:"
Write-Paragraph $sel2 "Para revisar los mensajes de virus detectados en la cola de mensajes oficial del sistema:"
Write-CodeSnippet $sel2 "DSPMSG STANDGUARD/AVMSGQ"

Write-Heading2 $sel2 "4.2 Tratamiento de Archivos en Cuarentena y Reversión:"
Write-Paragraph $sel2 "Los archivos detectados son trasladados al directorio /Quarantined/ y marcados con el estado 'Object marked as a scan failure'. Si se analiza y confirma que el archivo es un falso positivo, ejecute el comando CHGATR para resetear la marca de escaneo y restaurar el acceso normal:"
Write-CodeSnippet $sel2 "CHGATR OBJ('/Quarantined/avtestdir1/archivo.xls') ATR(*SCAN) VALUE(*NO)"

Write-Heading1 $sel2 "Capítulo 5. Procedimiento Automatizado de Descarga e Importación de Firmas"
Write-Heading2 $sel2 "5.1 Script de Descarga de Firmas McAfee desde Windows (PowerShell):"
Write-CodeSnippet $sel2 "`$url = 'http://update.nai.com/products/commonupdater/'`nInvoke-WebRequest (`$url + 'oem.ini') -OutFile 'oem.ini'`nInvoke-WebRequest (`$url + 'gdeltaavv.ini') -OutFile 'gdeltaavv.ini'`n`$site = Invoke-WebRequest -UseBasicParsing -Uri `$url`n`$table = `$site.links | ?{ `$_.href.ToLower().Contains('avvdat-') } | sort href -desc | select -first 1`n`$filename = `$table.href.ToString()`nInvoke-WebRequest (`$url + `$filename) -OutFile `$filename`nExpand-Archive -Force `$filename ."

Write-Heading2 $sel2 "5.2 Procedimiento de Carga vía FTP a IBM i:"
Write-Paragraph $sel2 "Transfiera los archivos de firmas descargados al directorio del IFS /standguard/firmas utilizando el formato de nombres de archivo 1:"
Write-CodeSnippet $sel2 "ftp 10.229.1.6`nUsuario: banasia029`nbin`nquote site namefmt 1`ncd /standguard/firmas`nmput *.ini`nput avvdat-XXXXX.zip"

Write-Heading1 $sel2 "Capítulo 6. Prueba de Verificación con Archivo Test EICAR"
Write-Paragraph $sel2 "Para validar el funcionamiento del antivirus sin riesgo operacional, cree un archivo de texto en una carpeta de prueba del IFS conteniendo la cadena estandarizada EICAR:"
Write-CodeSnippet $sel2 "X5O!P%@AP[4\PZX54(P^)7CC)7}`$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!`$H+H*"
Write-Paragraph $sel2 "Al guardar el archivo, Powertech Antivirus lo aislará inmediatamente en el directorio de cuarentena y registrará la alerta en la cola AVMSGQ."

$fileDoc2 = Join-Path $destDir "Manual_de_Procedimientos_Powertech_Antivirus_IBM_i.docx"
$doc2.SaveAs2("$fileDoc2", 16)
$doc2.Close()
Write-Host "Manual de Procedimientos guardado correctamente en: $fileDoc2"

$word.Quit()
Write-Host "Generación de documentos finalizada con éxito."
