# Script robusto para actualizar copia del documento Control Compensatorio Requisito 3_V4.1.docx
# Preserva encabezados, pie de pagina, estilos y las 31 imagenes de evidencia en Anexos

$ErrorActionPreference = "Stop"

$srcPath = "c:\Users\jespereira\Downloads\Control Compensatorio Requisito 3_V4.1.docx"
$workPath = "$env:TEMP\v42_work_build.docx"
$outPath = "c:\Users\jespereira\Downloads\Control Compensatorio Requisito 3_V4.2_Auditado.docx"

Write-Host "[INFO] 1. Copiando plantilla original al directorio temporal..."
$inStream = [System.IO.File]::Open($srcPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$outStream = [System.IO.File]::Create($workPath)
$inStream.CopyTo($outStream)
$outStream.Close()
$inStream.Close()

Write-Host "[INFO] 2. Abriendo documento en Word COM..."
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
    $doc = $word.Documents.Open($workPath)
    $WD_COLOR_NAVY = 6697728       # RGB(0, 51, 102)
    $WD_COLOR_HEADER_BG = 15395562 # RGB(234, 240, 246)

    # Helper para reemplazar texto de un parrafo SIN tocar el salto de parrafo final ni perder estilo
    function Set-ParagraphTextSafe {
        param($para, [string]$newText)
        $rng = $para.Range.Duplicate
        if ($rng.End -gt $rng.Start) {
            $rng.SetRange($rng.Start, $rng.End - 1)
        }
        $rng.Text = $newText
    }

    # Helper para reemplazar texto dentro de una celda sin alterar bordes ni formato base
    function Set-CellTextSafe {
        param($cell, [string]$newText, [float]$fontSize = 9.5)
        $rng = $cell.Range.Duplicate
        $rng.SetRange($rng.Start, $rng.End - 1)
        $rng.Text = $newText
        $rng.Font.Name = "Arial"
        $rng.Font.Size = $fontSize
        $rng.Font.Color = 0
    }

    Write-Host "[INFO] 3. Recolectando parrafos clave sin mutar durante enumeracion..."
    $pList = @()
    $totalParas = $doc.Paragraphs.Count
    for ($i = 1; $i -le $totalParas; $i++) {
        $p = $doc.Paragraphs.Item($i)
        $txt = $p.Range.Text.Trim("`r`n`a ")
        if ($txt -eq "Versión 4.1" -or
            $txt -like "Caracas, 10 de noviembre*" -or
            $txt -like "*Personal Account Number*" -or
            $txt -like "El Control Compensatorio se mantiene vigente para*" -or
            $txt -eq "ANEXOS" -or
            $txt -eq "Anexo 0" -or
            $txt -like "Almacenamiento de la data en reposo, la información se hace ilegible*") {
            $pList += [PSCustomObject]@{ Index = $i; Text = $txt; Para = $p }
        }
    }

    Write-Host "[INFO] 4. Actualizando portada, introduccion y textos de anexos ($($pList.Count) coincidencias)..."
    $anexosPara = $null
    foreach ($item in $pList) {
        $t = $item.Text
        $p = $item.Para
        if ($t -eq "Versión 4.1") {
            Set-ParagraphTextSafe $p "Versión 4.2 (Actualizada y Fortalecida - PCI DSS v4.0.1)"
        }
        elseif ($t -like "Caracas, 10 de noviembre*") {
            Set-ParagraphTextSafe $p "Caracas, 11 de noviembre de 2026"
        }
        elseif ($t -like "*Personal Account Number*") {
            $fixed = $t.Replace("Personal Account Number", "Primary Account Number").Replace("Base de Datos BD2", "Base de Datos DB2")
            Set-ParagraphTextSafe $p $fixed
        }
        elseif ($t -like "El Control Compensatorio se mantiene vigente para*") {
            $newIntro = "El Control Compensatorio se mantiene vigente para el ciclo 2026-2027, motivado a que la solución definitiva —la sustitución integral del Core de Medios de Pagos hacia Autoriza 7 v4.2— se encuentra en progreso con fecha comprometida de cierre en febrero de 2027. A efectos de delimitación estricta de alcance bajo PCI DSS v4.0.1, se aclara que el presente control compensatorio aplica EXCLUSIVAMENTE al repositorio del aplicativo FACT y sus tablas DB2 en IBM i donde persiste el PAN en texto claro; las medidas de tokenización en IST Switch (CryptGrid) y cifrado de archivos planos (GoAnywhere) y cintas son controles de cumplimiento estándar en sus respectivos entornos y se evalúan de forma independiente. Se anexa el Roadmap ejecutivo firmado del proyecto (Anexo 0) y el dictamen técnico de inviabilidad de FIELDPROC (Anexo 0B)."
            Set-ParagraphTextSafe $p $newIntro
        }
        elseif ($t -eq "ANEXOS") {
            $anexosPara = $p
        }
        elseif ($t -eq "Anexo 0") {
            Set-ParagraphTextSafe $p "Anexo 0 — Roadmap Ejecutivo del Proyecto de Sustitución del Core (Autoriza 7 v4.2 - Fecha Comprometida Febrero 2027, con firma ejecutiva)"
        }
        elseif ($t -like "Almacenamiento de la data en reposo, la información se hace ilegible*") {
            Set-ParagraphTextSafe $p "Evidencia de almacenamiento y cifrado complementario en reposo (GoAnywhere OpenPGP y análisis de tablas DB2 de FACT: PHYON2, PHYSODV, PHYRIPM, PHYMOAP, OUTGOING):"
        }
    }

    Write-Host "[INFO] 5. Actualizando Tabla 1 (Apendice B)..."
    $t1 = $doc.Tables.Item(1)

    $r2Col3 = @"
La versión actual del software Core de Tarjetas (aplicativo FACT) presenta obsolescencia tecnológica con más de 17 años en operación. La ausencia de cifrado directo en la base de datos responde a limitaciones técnicas legítimas derivadas de dicha arquitectura legacy:
• Rigidez de Código Legacy: Se requiere modificar y certificar aproximadamente 2.683 programas sin interfaz gráfica (escritos en RPG III/IV/Free, COBOL, Java y Visual Basic) que operan por acceso nativo a nivel de registro (READ, CHAIN, SETLL) con buffers de memoria fijos, lo cual comprometería la continuidad operativa de los procesos medulares del Banco.
• Análisis Técnico de Inviabilidad de IBM i FIELDPROC (Anexo 0B): Se evaluó formalmente el uso de Field Procedures (FIELDPROC) nativos de DB2 for i para cifrado transparente a nivel de columna, determinándose técnicamente inviable por: (1) ruptura de programas RPG/COBOL antiguos que acceden por RRN y estructuras de longitud fija; (2) alteración del ordenamiento de claves en más de 140 Archivos Lógicos (LF) indexados sobre el PAN, afectando la liquidación batch nocturna; y (3) sobrecarga crítica de CPU (>300%) en accesos no SQL durante ventanas masivas.
• Proyecto de Sustitución Definitiva y Fecha de Cierre Comprometida (Anexo 0): Se ejecuta formalmente la migración del Core Autoriza 7 desde la versión 3.9 hacia la versión 4.2 (que incluye tokenización nativa). Al tratarse del tercer año de vigencia del control, se establece como fecha comprometida formal de cierre (Target Sunset Date) el 28 de febrero de 2027, sustentada mediante Roadmap ejecutivo aprobado con firma de la Dirección/Vicepresidencia y análisis independiente de arquitectura.
"@
    Set-CellTextSafe $t1.Cell(2, 3) $r2Col3 9.5

    $r3Col3 = @"
Controles Compensatorios Específicos y Adicionales para mitigar la exposición del PAN en claro en el módulo FACT (DB2 for i):

1. Enmascaramiento Mandatorio por Defecto en FACT (Anexo 1):
Todo acceso interactivo al módulo FACT de adquirencia presenta el número de tarjeta enmascarado por defecto para el 99.8% de los usuarios bajo formato 6+4 (ej. 411016******8024), alineado al estándar PCI DSS Req. 3.4.1. La visualización en claro mediante la opción "A" está deshabilitada en código y restringida exclusivamente a una lista blanca nominal auditada y justificada.

2. Vinculación Estricta Usuario-IP (User-to-IP Binding) (Anexo 4):
Implementación de lista blanca rígida 1:1 que asocia cada ID de usuario autorizado en IBM i exclusivamente con la dirección IP estática de su estación de trabajo corporativa autorizada. Cualquier intento de conexión desde una IP distinta —incluso con credenciales válidas— es rechazado automáticamente a nivel de subsistema.

3. Control Perimetral y Bloqueo de Consultas/Descargas por Exit Points (Anexo 3 y 5):
Reglas restrictivas Deny-by-Default en los Exit Points de IBM i (Database Server QIBM_QZDA_SQL / QIBM_QZDA_INIT, File Server, FTP, Remote Command y DDM) que bloquean de forma absoluta consultas SQL ad-hoc (ODBC/JDBC), extracciones masivas o descargas de las tablas físicas de FACT.

4. Prevención de Fuga de Información (DLP) en Estaciones CDE (Anexo 6):
Bloqueo técnico de dispositivos de almacenamiento masivo (USB/discos externos), inhabilitación de envío de correos a destinatarios externos, bloqueo de transferencia de archivos hacia redes no autorizadas y control de impresiones.

5. Contención y Gobierno Estricto de Superusuarios (*ALLOBJ) y Acceso Directo a Nivel de SO (Anexo 3):
Para tratar el riesgo de usuarios internos con privilegios totales (*ALLOBJ) o sesiones locales/consola que no pasen por la puerta de entrada de red:
• Cuota Máxima Estricta: Se limita la autoridad especial *ALLOBJ a un máximo de 10 perfiles nominales de administración técnica (cero perfiles genéricos o compartidos).
• Aclaración de Acceso Directo: No existe acceso funcional ni de negocio directo al SO sin pasar por controles de Exit Point / acceso corporativo controlado; el acceso de consola (HMC/5250) está restringido únicamente a contingencia de infraestructura bajo custodia.
• Bloqueo de Utilitarios de Base de Datos: Inhabilitación de comandos interactivos de consulta/edición directa (STRSQL, RUNSQL, DFU, DBU, UPDLOG, CPYF) para perfiles no autorizados.
• Revisión Mensual y Monitoreo en Tiempo Real (QAUDJRN): Auditoría mensual formal de perfiles *ALLOBJ y vigilancia continua de entradas CD, AF y ZC del diario QAUDJRN, generando alertas inmediatas al SOC/SIEM ante cualquier intento de acceder a las tablas de FACT fuera del binario aplicativo autorizado.

Nota de Aclaración de Alcance (Tokenización y Cifrado en otros repositorios - Anexo 7):
La tokenización mediante CryptGrid en el IST Switch y el cifrado PGP (AES-256) mediante GoAnywhere para archivos planos y cintas magnéticas se mantienen como capas de defensa en profundidad y cumplimiento directo del Req. 3.5.1 en dichos entornos, evaluándose de forma separada y sin computarse como compensación de la brecha en FACT.
"@
    Set-CellTextSafe $t1.Cell(3, 3) $r3Col3 9.5

    Set-CellTextSafe $t1.Cell(4, 3) "Garantizar que el PAN se mantenga ilegible donde sea que se almacene mediante criptografía sólida, tokenización o truncamiento, protegiendo los datos del tarjetahabiente ante accesos o extracciones no autorizadas en los repositorios de almacenamiento." 9.5

    $r5Col3 = @"
Prevenir la exposición, acceso indebido, alteración o exfiltración no autorizada del PAN en claro almacenado en las tablas DB2 de FACT mediante un esquema sinérgico de seguridad en profundidad:
• Minimización de Exposición en Pantalla: Enmascaramiento obligatorio 6+4 en FACT para operaciones cotidianas, restringiendo la opción en claro ("A") únicamente a perfiles indispensables y aprobados.
• Aislamiento de Transporte y Puntos de Salida: Vinculación rígida Usuario-IP y bloqueo por Exit Points de cualquier extracción o consulta SQL ad-hoc a las tablas DB2 de FACT.
• Contención de Usuarios de Altos Privilegios (*ALLOBJ): Limitación estricta de perfiles con autoridad total, bloqueo de utilitarios de BD y trazabilidad en tiempo real en QAUDJRN con bloqueos ante accesos no permitidos.
• Prevención de Fuga de Información (DLP): Inhabilitación de vectores físicos (USB) y digitales de extracción desde el CDE.
• Vigilancia Operativa: Auditoría diaria de logs y journals con respuesta inmediata ante alertas de seguridad.
"@
    Set-CellTextSafe $t1.Cell(5, 3) $r5Col3 9.5

    Set-CellTextSafe $t1.Cell(6, 2) "Definir cualquier riesgo adicional resultante de la ausencia del control original y justificar la proporcionalidad." 9.5
    $r6Col3 = @"
A. Riesgo Identificado:
Riesgo de exposición no autorizada de datos de titulares de tarjetas (PAN) en texto claro dentro del entorno del Core Bancario (IBM i / DB2) al no contar con cifrado, truncamiento o tokenización nativa en las tablas DB2 de FACT. Existe el riesgo residual de que un usuario con privilegios elevados (*ALLOBJ) o un atacante interno/externo con credenciales comprometidas intente eludir la interfaz aplicativa para consultar o extraer directamente el PAN desde las tablas físicas.

B. Volumen de Exposición y Proporcionalidad del Entorno:
• Repositorio Acotado: El PAN en claro se circunscribe exclusivamente a cinco (5) tablas físicas de FACT en producción: PHYON2, PHYSODV, PHYRIPM, PHYMOAP y OUTGOING. [COMPLETAR: Indicar volumen exacto de registros PAN activos/históricos en estas tablas, ej. X millones de registros].
• Depuración y Justificación del Listado de Usuarios (Anexo 2): El listado actual registra 38 usuarios entre las áreas de Prevención de Fraude, Contabilidad TDC y Operaciones de Tarjetas. En atención a la observación del QSA, se ejecuta un proceso formal de depuración para reducir la lista al mínimo indispensable y anexar para el 100% de los usuarios vigentes: (1) justificación de negocio individual documentada, (2) correo/acta de aprobación formal del gerente supervisor inmediato, (3) recertificación semestral obligatoria, y (4) evidencia técnica de MFA aplicado en el acceso al aplicativo AS400 y VPN CyberArk (G_VPN_MFA_CyberArk).
"@
    Set-CellTextSafe $t1.Cell(6, 3) $r6Col3 9.5

    $r7Col3 = @"
Basado en las pruebas técnicas ejecutadas y la validación funcional de la solución de seguridad, se evidenció la efectividad real de los controles compensatorios mediante los siguientes escenarios de prueba:

1. Validación de Enmascaramiento Dinámico en FACT (Anexo 1):
Prueba funcional con perfiles operativos generales verificando la visualización por defecto en formato 6+4 (411016******8024) y el bloqueo efectivo de la opción "A" para cualquier usuario fuera de la lista blanca aprobada.

2. Prueba de Rechazo por Vinculación Usuario-IP (User-to-IP Binding) (Anexo 4 y 5):
Intento controlado de conexión utilizando credenciales válidas desde una dirección IP no registrada para ese usuario. Resultado: Conexión rechazada inmediatamente a nivel de subsistema y registro del evento en la consola de alertas.

3. Prueba de Bloqueo de Consultas SQL / Descargas por Exit Points (Anexo 3, 5 y 6):
Intento de consulta directa vía ODBC/JDBC y transferencia de archivos sobre las tablas DB2 de FACT. Resultado: Petición interceptada y bloqueada por el Exit Program, sin extracción de registros y con notificación de rechazo.

4. Validación de Contención de Privilegios *ALLOBJ y Monitoreo QAUDJRN (Anexo 3):
Verificación del inventario de perfiles *ALLOBJ contra la cuota autorizada, comprobación del bloqueo de utilitarios interactivos (STRSQL/DFU) y validación de generación de alertas en tiempo real en QAUDJRN ante mandatos críticos.

5. Detección de Actividades Sospechosas y Ataques (Anexo 5):
Validación funcional de las reglas de detección de accesos no autorizados, modificaciones de objetos, ataques de fuerza bruta, inyecciones SQL y comportamientos anómalos con envío automático de notificaciones al equipo de Ciberseguridad y Administración de Seguridad.

6. Validación de Evidencias Complementarias 3.5.1.b (Anexo 7, 9 y 10):
Ejecución de barrido automatizado de descubrimiento de PAN (Data Discovery) en bases de datos, archivos y logs; inspección muestral de logs de auditoría y journals libres de PAN en claro; y prueba técnica de ilegibilidad sin llave privada sobre archivos cifrados en GoAnywhere y cintas de respaldo.
"@
    Set-CellTextSafe $t1.Cell(7, 3) $r7Col3 9.5

    $r8Col3 = @"
• Revisión Diaria de Alertas (Proc. 368-SICPR-01): Monitoreo diario obligatorio de todas las alertas generadas por los Exit Points, intentos fallidos de acceso, rechazos por IP y eventos críticos de QAUDJRN en IBM i.
• Auditoría Mensual de Perfiles *ALLOBJ y User-IP Binding: Revisión mensual documentada del número de perfiles con autoridad especial *ALLOBJ (verificando cumplimiento de cuota máxima) y conciliación de la lista blanca de IPs autorizadas.
• Recertificación Semestral de Usuarios con PAN Completo: Validación cada 6 meses ante las gerencias de Fraude, Contabilidad TDC y Operaciones de la necesidad comercial de cada usuario autorizado, revocando accesos innecesarios.
• Gestión de Respuesta a Incidentes: Ejecución del Playbook de PAN en claro fuera del CDE y del Plan de Respuesta a Incidentes (313-SICPN-01) ante cualquier desviación detectada.
• Revisión Anual Formal del Control Compensatorio (Req. 12.3.2): Evaluación anual documentada entre Banesco y el QSA para ratificar la vigencia de las restricciones, el desempeño de las métricas de eficacia y el cumplimiento del Roadmap hacia el 28 de febrero de 2027.
"@
    Set-CellTextSafe $t1.Cell(8, 3) $r8Col3 9.5

    Write-Host "[INFO] 6. Agregando filas 9 (Metricas) y 10 (No-Reutilizacion) a Tabla 1..."
    $t1.Rows.Add() | Out-Null
    Set-CellTextSafe $t1.Cell(9, 1) "7. Métricas de Eficacia Operativa (Obligatorio Apéndice B)" 10
    $t1.Cell(9, 1).Range.Font.Bold = $true
    Set-CellTextSafe $t1.Cell(9, 2) "Definir indicadores cuantitativos, frecuencia de medición, umbral de alarma y responsable." 10
    $r9Col3 = @"
Se establecen los siguientes indicadores clave de control (KPI/KRI) de medición obligatoria:

1. Porcentaje de accesos al PAN en claro con aprobación y justificación vigente:
• Fórmula: (Usuarios en FACT opción "A" con aprobación vigente / Total usuarios con opción "A") x 100
• Frecuencia: Mensual | Umbral de Alarma: < 100% (Meta: 100%)
• Responsable: Gerencia de Administración de Seguridad.

2. Discrepancias de usuarios con PAN en claro vs. lista aprobada:
• Fórmula: Cantidad de usuarios habilitados en sistema que no figuran o no están vigentes en la lista aprobada.
• Frecuencia: Quincenal | Umbral de Alarma: > 0 usuarios discrepantes (Meta: 0)
• Responsable: Gerencia de Administración de Seguridad.

3. Porcentaje de intentos bloqueados por Exit Point / User-IP Binding investigados:
• Fórmula: (Intentos bloqueados analizados en < 24h / Total intentos bloqueados) x 100
• Frecuencia: Diaria | Umbral de Alarma: < 100% o cualquier intento no investigado (Meta: 100%)
• Responsable: Gerencia de Administración de Seguridad / Ciberseguridad (SOC).

4. Días hábiles sin revisión de alertas de seguridad IBM i (368-SICPR-01):
• Fórmula: Conteo de días hábiles sin evidencia de revisión diaria firmada/registrada.
• Frecuencia: Diaria | Umbral de Alarma: >= 1 día sin revisión (Meta: 0 días)
• Responsable: Analista de Administración de Seguridad.

5. Cumplimiento de límite de perfiles con autoridad especial *ALLOBJ:
• Fórmula: Total perfiles *ALLOBJ activos en producción vs. cuota máxima autorizada (<= 10).
• Frecuencia: Mensual | Umbral de Alarma: > 10 perfiles o cualquier alta sin aprobación ejecutiva
• Responsable: Gerencia de Administración de Seguridad.

6. Consultas interactivas o extracciones directas sobre tablas FACT fuera del binario autorizado:
• Fórmula: Cantidad de eventos en QAUDJRN (STRSQL/DFU/ODBC) sobre PHYON2, PHYSODV, PHYRIPM, PHYMOAP, OUTGOING.
• Frecuencia: Tiempo real (SIEM) | Umbral de Alarma: >= 1 evento (Alerta Crítica Inmediata)
• Responsable: Ciberseguridad / SOC.
"@
    Set-CellTextSafe $t1.Cell(9, 3) $r9Col3 9.5

    $t1.Rows.Add() | Out-Null
    Set-CellTextSafe $t1.Cell(10, 1) "8. Declaración de No-Reutilización de Controles (Non-Reliance)" 10
    $t1.Cell(10, 1).Range.Font.Bold = $true
    Set-CellTextSafe $t1.Cell(10, 2) "Aclarar la relación con otros requisitos PCI DSS para evitar doble cómputo." 10
    $r10Col3 = @"
De conformidad con las reglas del Apéndice B de PCI DSS v4.0.1, ningún control requerido por otra sección del estándar se contabiliza como control compensatorio en sí mismo:
• Controles Compensatorios Adicionales (Núcleo de la Compensación): (1) Enmascaramiento 6+4 por defecto en FACT con bloqueo de opción "A", (2) User-to-IP Binding estricto 1:1, (3) Bloqueo de descargas y SQL ad-hoc por Exit Points, (4) DLP de terminal en CDE, y (5) Cuota máxima y monitoreo en tiempo real de *ALLOBJ sobre tablas FACT en QAUDJRN.
• Controles Base de Soporte (Requerimientos Estándar - No Reutilizados como Compensación): MFA (Req. 8.4), gestión y aprobación de identidades (Req. 7.2.x), generación de logs/journals (Req. 10.2), revisión diaria de logs (Req. 10.4.1), concientización (Req. 12.6), respuesta a incidentes (Req. 12.10), y tokenización/cifrado en IST Switch y GoAnywhere (Req. 3.5.1 en sus propios alcances).
"@
    Set-CellTextSafe $t1.Cell(10, 3) $r10Col3 9.5

    Write-Host "[INFO] 7. Insertando seccion de Revision Anual y Firmas antes de ANEXOS..."
    if ($anexosPara -ne $null) {
        $insRng = $anexosPara.Range.Duplicate
        $insRng.Collapse(1) # wdCollapseStart
        $insRng.InsertBefore("`r`r")
        $insRng.Collapse(1)

        $insRng.Text = "Revisión Anual Formal y Aprobación del Control Compensatorio (PCI DSS v4.0.1 Req. 12.3.2)`r"
        $insRng.Font.Name = "Arial"
        $insRng.Font.Size = 11
        $insRng.Font.Bold = $true
        $insRng.Font.Color = $WD_COLOR_NAVY
        $insRng.ParagraphFormat.PageBreakBefore = 0

        $subRng = $doc.Range($insRng.End, $insRng.End)
        $subRng.Text = "En cumplimiento del Requisito 12.3.2 de PCI DSS v4.0.1, la entidad y el Asesor de Seguridad Calificado (QSA) dejan constancia de la revisión anual y validación de eficacia del presente control compensatorio:`r"
        $subRng.Font.Name = "Arial"
        $subRng.Font.Size = 9.5
        $subRng.Font.Bold = $false
        $subRng.Font.Color = 0
        $subRng.ParagraphFormat.PageBreakBefore = 0

        $sigRng = $doc.Range($subRng.End, $subRng.End)
        $sigTable = $doc.Tables.Add($sigRng, 3, 3)
        $sigTable.Borders.Enable = 1
        $sigTable.Rows.Item(1).Shading.BackgroundPatternColor = $WD_COLOR_HEADER_BG
        Set-CellTextSafe $sigTable.Cell(1, 1) "Gerencia de Administración de Seguridad (Banesco)" 9
        Set-CellTextSafe $sigTable.Cell(1, 2) "Vicepresidencia de Tecnología / Operaciones (Banesco)" 9
        Set-CellTextSafe $sigTable.Cell(1, 3) "Evaluador QSA Certificado (Firma Auditora)" 9
        $sigTable.Rows.Item(1).Range.Font.Bold = $true

        Set-CellTextSafe $sigTable.Cell(2, 1) "`n`n___________________________`nFirma Autorizada" 9
        Set-CellTextSafe $sigTable.Cell(2, 2) "`n`n___________________________`nFirma Autorizada" 9
        Set-CellTextSafe $sigTable.Cell(2, 3) "`n`n___________________________`nFirma QSA" 9

        Set-CellTextSafe $sigTable.Cell(3, 1) "Nombre:`nFecha: ____/____/2026" 9
        Set-CellTextSafe $sigTable.Cell(3, 2) "Nombre:`nFecha: ____/____/2026" 9
        Set-CellTextSafe $sigTable.Cell(3, 3) "Nombre:`nFecha: ____/____/2026" 9
    }

    Write-Host "[INFO] 8. Agregando marcadores de Anexos Faltantes al final del documento..."
    $endRng = $doc.Content.Duplicate
    $endRng.Collapse(0) # wdCollapseEnd
    $extraAnexosText = @"

ANEXO 0B — Dictamen Técnico de Arquitectura: Inviabilidad de IBM i FIELDPROC
[INCLUIR / ADJUNTAR]: Informe técnico firmado por Arquitectura de TI / SAPL detallando la incompatibilidad de FIELDPROC con los 2.683 programas RPG/COBOL (accesos por RRN, buffers fijos, Archivos Lógicos con clave en PAN e impacto en batch nocturno).

ANEXO 2B — Respaldo Integral de Usuarios con Acceso a PAN Completo (38 Usuarios / Depuración)
[COMPLETAR / ADJUNTAR]: Matriz depurada (reducción o justificación individual de negocio por rol en Fraude, Contabilidad TDC y Operaciones), adjuntando el 100% de aprobaciones de supervisores inmediatos y evidencia de aplicación de MFA sobre todos los usuarios activos.

ANEXO 3B — Auditoría Mensual de Perfiles *ALLOBJ y Controles Directos de SO
[INCLUIR / ADJUNTAR]: Listado completo de perfiles con autoridad especial *ALLOBJ en producción demostrando cumplimiento del límite máximo autorizado (<= 10), evidencia de bloqueo de utilitarios (STRSQL/DFU/DBU) y trazas de alertas en QAUDJRN.

ANEXO 7B — Resultado de Barrido de Búsqueda de PAN (Data Discovery)
[INCLUIR / ADJUNTAR]: Reporte ejecutivo y logs del escaneo automatizado (Data Discovery) ejecutado en bases de datos DB2, archivos del IFS, carpetas compartidas y logs, delimitando exactamente dónde existe PAN en claro y confirmando ausencia fuera del alcance.

ANEXO 7C — Prueba de Ilegibilidad sin Llave en Archivo GoAnywhere y Cinta Cifrada
[INCLUIR / ADJUNTAR]: Capturas técnicas de intento de apertura/lectura de un archivo plano cifrado con GoAnywhere (.pgp) y una cinta magnética cifrada sin disponer de la llave criptográfica, evidenciando error de descifrado / contenido ilegible.

ANEXO 9 — Muestra de Logs de Auditoría Libres de PAN en Claro
[INCLUIR / ADJUNTAR]: Extractos de registros de QAUDJRN, journals de base de datos y logs del aplicativo FACT demostrando que ninguna traza de auditoría registra el PAN completo en texto claro.

ANEXO 10 — Confirmación de Vigencia / AoV Actualizada del IST Switch
[INCLUIR / ADJUNTAR]: Atestación de Validación (AoV) vigente de la plataforma IST Switch (actualización posterior al vencimiento del 03/07/2026 de la versión 7.7 SP24) o certificación formal de soporte y cumplimiento vigente.
"@
    $endRng.Text = $extraAnexosText
    $endRng.Font.Name = "Arial"
    $endRng.Font.Size = 10
    $endRng.Font.Color = 0

    Write-Host "[INFO] 9. Guardando archivo temporal..."
    $doc.Save()
    $doc.Close([ref]$false)
    $doc = $null
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    $word = $null

    Write-Host "[INFO] 10. Copiando archivo final a $outPath..."
    Copy-Item -Path $workPath -Destination $outPath -Force
    Write-Host "[OK] Documento generado exitosamente: $outPath"

} catch {
    Write-Host "[ERROR] Fallo en generacion: $_"
    throw $_
} finally {
    if ($doc -ne $null) {
        try { $doc.Close([ref]$false) } catch {}
        try { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null } catch {}
    }
    if ($word -ne $null) {
        try { $word.Quit() } catch {}
        try { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null } catch {}
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
