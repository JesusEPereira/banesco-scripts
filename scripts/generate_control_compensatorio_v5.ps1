# Script de generación del documento oficial Word de Control Compensatorio PCI DSS v4.0.1
# Banesco Banco Universal - Gerencia de Administracion de Seguridad
# Version 5.0 Fortalecida

$ErrorActionPreference = "Stop"

$outputPath = "c:\Users\jespereira\Downloads\Control Compensatorio Requisito 3_V5.0.docx"

Write-Host "[INFO] Iniciando instancia de Word COM..."
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
    $doc = $word.Documents.Add()
    $selection = $word.Selection

    # Configuracion de Pagina
    $sec = $doc.Sections.Item(1)
    $sec.PageSetup.TopMargin = 54      # ~1.9 cm
    $sec.PageSetup.BottomMargin = 54   # ~1.9 cm
    $sec.PageSetup.LeftMargin = 54     # ~1.9 cm
    $sec.PageSetup.RightMargin = 54    # ~1.9 cm

    # Colores corporativos Banesco / PCI
    $WD_COLOR_NAVY = 6697728         # RGB(0, 51, 102) - Azul Corporativo
    $WD_COLOR_HEADER_BG = 15395562   # RGB(234, 240, 246) - Azul muy claro
    $WD_COLOR_ALERT_BG = 15790320    # RGB(240, 240, 240) - Gris claro
    $WD_COLOR_DARK_TEXT = 2171169    # RGB(33, 37, 41)

    # Funciones auxiliares de formateo
    function Add-Title {
        param([string]$text)
        $selection.Font.Name = "Arial"
        $selection.Font.Size = 18
        $selection.Font.Bold = $true
        $selection.Font.Color = $WD_COLOR_NAVY
        $selection.ParagraphFormat.Alignment = 1 # Center
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = 6
        $selection.TypeText($text)
        $selection.TypeParagraph()
    }

    function Add-Subtitle {
        param([string]$text)
        $selection.Font.Name = "Arial"
        $selection.Font.Size = 12
        $selection.Font.Bold = $true
        $selection.Font.Color = 5526612 # Gris oscuro
        $selection.ParagraphFormat.Alignment = 1 # Center
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = 14
        $selection.TypeText($text)
        $selection.TypeParagraph()
    }

    function Add-Heading1 {
        param([string]$text)
        $selection.Font.Name = "Arial"
        $selection.Font.Size = 13
        $selection.Font.Bold = $true
        $selection.Font.Color = $WD_COLOR_NAVY
        $selection.ParagraphFormat.Alignment = 0 # Left
        $selection.ParagraphFormat.SpaceBefore = 14
        $selection.ParagraphFormat.SpaceAfter = 6
        $selection.TypeText($text)
        $selection.TypeParagraph()
    }

    function Add-Heading2 {
        param([string]$text)
        $selection.Font.Name = "Arial"
        $selection.Font.Size = 11
        $selection.Font.Bold = $true
        $selection.Font.Color = 3355443 # Dark Gray
        $selection.ParagraphFormat.Alignment = 0 # Left
        $selection.ParagraphFormat.SpaceBefore = 8
        $selection.ParagraphFormat.SpaceAfter = 4
        $selection.TypeText($text)
        $selection.TypeParagraph()
    }

    function Add-BodyParagraph {
        param(
            [string]$boldPrefix = "",
            [string]$text = "",
            [int]$spaceAfter = 6
        )
        $selection.ParagraphFormat.Alignment = 3 # Justify
        $selection.ParagraphFormat.SpaceBefore = 0
        $selection.ParagraphFormat.SpaceAfter = $spaceAfter
        $selection.Font.Name = "Arial"
        $selection.Font.Size = 9.5
        $selection.Font.Color = 0

        if ($boldPrefix -ne "") {
            $selection.Font.Bold = $true
            $selection.TypeText($boldPrefix)
            $selection.Font.Bold = $false
        }
        $selection.TypeText($text)
        $selection.TypeParagraph()
    }

    Write-Host "[INFO] Redactando portada y encabezado..."
    Add-Title -text "Control Compensatorio Requisito 3.5.1"
    Add-Subtitle -text "PCI DSS v4.0.1 - Apéndice B (Compensating Controls Worksheet)`nVersión 5.0 (Actualizada, Fortalecida y Alineada a Observaciones QSA)`nCaracas, 11 de Noviembre de 2026"

    # Metadata resumen
    Add-BodyParagraph -boldPrefix "Entidad / Organización: " -text "Banesco Banco Universal, C.A. - Gerencia de Administración de Seguridad"
    Add-BodyParagraph -boldPrefix "Alcance de Certificación: " -text "Adquirencia - Core Bancario de Tarjetas de Crédito (Módulo FACT en IBM i / DB2)"
    Add-BodyParagraph -boldPrefix "Requisito Evaluado: " -text "PCI DSS v4.0.1 - Requisito 3.5.1 (Protección e Ilegibilidad del Primary Account Number - PAN en reposo)"
    Add-BodyParagraph -boldPrefix "Versión del Documento: " -text "Versión 5.0 (Sustituye formalmente a la Versión 4.1 atendiendo integralmente los requerimientos del QSA)"
    Add-BodyParagraph -boldPrefix "Fecha de Emisión y Vigencia: " -text "Noviembre de 2026 (Ciclo de Certificación PCI DSS 2026)"

    Add-Heading1 -text "1. Introducción y Marco Normativo"
    Add-BodyParagraph -text "Durante el proceso de certificación y auditoría de seguimiento bajo el estándar PCI DSS (Payment Card Industry Data Security Standard) v4.0.1 para el alcance de Adquirencia de Banesco Banco Universal, se analizó la persistencia del PAN (Primary Account Number) en texto claro dentro del repositorio central del Core Bancario de Tarjetas de Crédito, específicamente en la plataforma IBM i (AS400), módulo de aplicativo FACT y sus correspondientes tablas físicas en la base de datos DB2 for i."
    Add-BodyParagraph -boldPrefix "Gobierno Multidisciplinario del Control: " -text "Para la administración, supervisión, validación técnica y gobierno continuo de este control compensatorio participan activamente las siguientes dependencias:"
    Add-BodyParagraph -boldPrefix "• Unidades Funcionales: " -text "Gerencia de Operaciones de Tarjetas de Crédito y Débito."
    Add-BodyParagraph -boldPrefix "• Unidades de Tecnología: " -text "Gerencia de Soporte y Aplicaciones de Medios de Pago (SAPL) y Gerencia de Infraestructura Tecnológica IBM i."
    Add-BodyParagraph -boldPrefix "• Unidades de Seguridad de la Información: " -text "Gerencia de Administración de Seguridad y Gerencia de Ciberseguridad."

    Add-BodyParagraph -boldPrefix "Requisito Mandatorio PCI DSS v4.0.1 (Apartado 3.5.1): " -text "El estándar establece textualmente lo siguiente:"
    Add-BodyParagraph -text "`"3.5.1 Los datos PAN se hacen ilegibles en cualquier lugar donde se almacenen utilizando cualquiera de los siguientes enfoques:`n• Hashes unidireccionales basados en criptografía sólida del PAN completo.`n• Truncamiento (los hashes no pueden utilizarse para reemplazar el segmento truncado del PAN). Si en un entorno hay versiones truncadas y con hash del mismo PAN, o diferentes formatos de truncamiento del mismo PAN, se establecen controles adicionales de manera que las diferentes versiones no puedan correlacionarse para reconstruir el PAN original.`n• Índice de tokens.`n• Criptografía sólida con procesos y procedimientos de gestión de claves asociados.`""

    Add-Heading1 -text "2. Situación Actual, Delimitación de Alcance y Justificación de Continuidad"
    Add-BodyParagraph -text "El presente Control Compensatorio se mantiene formalmente vigente para el año 2026 debido a que la solución arquitectural definitiva —el proyecto corporativo de sustitución del Core de Medios de Pago por la plataforma Autoriza 7 versión 4.2— se encuentra en curso de ejecución conforme a cronograma aprobado (Anexo 0)."
    Add-BodyParagraph -boldPrefix "Delimitación Técnica Rigurosa del Alcance (Atendiendo Observación QSA): " -text "A efectos de solventar las observaciones formuladas por el Asesor de Seguridad Calificado (QSA) sobre la delimitación de responsabilidades probatorias, se delimita formalmente la frontera técnica entre los repositorios que ya cumplen con el estándar y el repositorio objeto exclusivo de este control compensatorio:"
    Add-BodyParagraph -boldPrefix "A. Repositorios que Cumplen con Ilegibilidad Nativa (Fuera de Brecha): " -text "El PAN se encuentra debidamente protegido e ilegible mediante tokenización en las tablas del IST Switch utilizando la solución CryptGrid (generando tokens irremediables). Asimismo, los archivos planos transmitidos se cifran con OpenPGP (AES-256) mediante GoAnywhere, y las cintas magnéticas de resguardo se cifran mediante esquemas BRMS y hardware LTO. Estas medidas representan cumplimiento directo del estándar en sus respectivos perímetros y se aportan como evidencia de defensa en profundidad, mas NO se declaran como la medida compensatoria de FACT."
    Add-BodyParagraph -boldPrefix "B. Repositorio en Brecha (Alcance Exclusivo del Control Compensatorio): " -text "Corresponde exclusivamente al aplicativo FACT sobre la plataforma IBM i y sus tablas físicas asociadas en la base de datos DB2 for i: PHYON2, PHYSODV, PHYRIPM, PHYMOAP y OUTGOING. En este repositorio, debido a limitaciones técnicas y obsolescencia del software core legacy, el PAN se encuentra en texto claro. Este repositorio constituye el ÚNICO objeto y justificación del presente Control Compensatorio."

    Add-Heading1 -text "3. Ficha Oficial del Control Compensatorio (PCI DSS v4.0.1 - Apéndice B)"
    Add-BodyParagraph -text "A continuación se desarrolla la plantilla oficial requerida por el Apéndice B de PCI DSS v4.0.1 (Compensating Controls Worksheet), enriquecida con los análisis técnicos de FIELDPROC, el tratamiento riguroso de perfiles con autoridad especial (*ALLOBJ), la exclusión de reutilización de requisitos base y la matriz obligatoria de métricas operativas exigidas por el auditor QSA:"

    # Creación de la Gran Tabla de Apéndice B
    $tableRange = $selection.Range
    $table = $doc.Tables.Add($tableRange, 9, 3)
    $table.Borders.Enable = 1
    $table.Borders.InsideColor = 13421772
    $table.Borders.OutsideColor = $WD_COLOR_NAVY

    $table.Columns.Item(1).Width = 110 # Item
    $table.Columns.Item(2).Width = 130 # Informacion Requerida
    $table.Columns.Item(3).Width = 264 # Explicacion

    # Fila 1: Encabezado
    $table.Rows.Item(1).HeadingFormat = $true
    $table.Rows.Item(1).Range.Font.Name = "Arial"
    $table.Rows.Item(1).Range.Font.Size = 9.5
    $table.Rows.Item(1).Range.Font.Bold = $true
    $table.Rows.Item(1).Range.Font.Color = $WD_COLOR_NAVY
    $table.Rows.Item(1).Shading.BackgroundPatternColor = $WD_COLOR_HEADER_BG

    $table.Cell(1, 1).Range.Text = "Ítem Normativo"
    $table.Cell(1, 2).Range.Text = "Información Requerida"
    $table.Cell(1, 3).Range.Text = "Explicación y Justificación Técnica Detallada"

    # Fila 2: Restricciones Técnicas y Comerciales
    $table.Cell(2, 1).Range.Text = "1. Restricciones Técnicas y Comerciales Legítimas"
    $table.Cell(2, 2).Range.Text = "Documentar las limitaciones técnicas o comerciales legítimas que impiden el cumplimiento del requisito original (Req. 3.5.1)."
    $r2Text = @"
A. Obsolescencia del Software Core Bancario Legacy:
La versión en producción del Core de Tarjetas (aplicativo FACT) posee más de 17 años en operación continua. La arquitectura está compuesta por aproximadamente 2.683 programas compilados en múltiples lenguajes (RPG III, RPG IV, RPG Free, COBOL, Java y Visual Basic) que interactúan directamente mediante operaciones de entrada/salida a nivel de registro nativo (READ, CHAIN, SETLL) con estructuras de datos de longitud fija, careciendo de una capa de persistencia desacoplada o uso generalizado de SQL.

B. Dictamen Técnico de Inviabilidad de FIELDPROC en DB2 for i (Anexo 0B):
Se evaluó exhaustivamente la implementación de IBM i FIELDPROC (procedimiento nativo de DB2 introducido para cifrado a nivel de columna transparente). Se concluyó su inviabilidad técnica por tres factores insalvables:
1. Incompatibilidad con Acceso por RRN y Buffers Fijos: La activación de FIELDPROC modifica el almacenamiento binario de las columnas. Los programas RPG/COBOL antiguos que acceden por número de registro relativo (RRN) o leen buffers fijos en memoria sufren excepciones graves de ejecución (CPF) o corrupción de datos transaccionales.
2. Ruptura de Archivos Lógicos (LF) y Claves Compuestas: Las tablas de FACT poseen más de 140 Archivos Lógicos con claves de acceso indexadas construidas sobre el campo PAN. FIELDPROC altera la secuencia de colación y ordenamiento, inhabilitando las búsquedas indexadas y corrompiendo la lógica de liquidación batch nocturna.
3. Sobrecarga de Rendimiento y Riesgo Sistémico: La decodificación en caliente en accesos no SQL provoca un incremento de uso de CPU superior al 300% en ventanas críticas de compensación masiva, amenazando la continuidad operativa del banco.
Reescribir y probar 2.683 fuentes equivaldría a rehacer el core desde cero, con un altísimo riesgo operacional.

C. Proyecto de Sustitución Definitiva y Fecha de Cierre Comprometida (Anexo 0):
La institución ejecuta formalmente la migración hacia el Core Autoriza 7 v4.2, el cual incorpora tokenización nativa en reposo y arquitectura desacoplada.
- Fecha Comprometida de Cierre (Target Sunset Date): 31 de Diciembre de 2026.
- Aprobación Ejecutiva: Roadmap oficial suscrito y aprobado por la Vicepresidencia Ejecutiva de Operaciones y TI (Anexo 0).
"@
    $table.Cell(2, 3).Range.Text = $r2Text

    # Fila 3: Definición de Controles Compensatorios Puros
    $table.Cell(3, 1).Range.Text = "2. Definición de Controles Compensatorios (Medidas Específicas)"
    $table.Cell(3, 2).Range.Text = "Definir los controles compensatorios: explicar cómo abordan los objetivos del control original y el mayor riesgo residual."
    $r3Text = @"
Se implementan controles extraordinarios y específicos diseñados para neutralizar la exposición del PAN en claro en FACT y DB2:

Control Compensatorio 1: Enmascaramiento Mandatorio por Defecto en FACT (Anexo 1)
Todo acceso interactivo al módulo FACT de adquirencia presenta el número de tarjeta enmascarado por defecto bajo el estándar 6+4 (ej. 411016******8024). La visualización en claro mediante la opción 'A' se encuentra deshabilitada en código para el 99.8% de los usuarios, restringiéndose exclusivamente a una lista blanca nominal auditada.

Control Compensatorio 2: Vinculación Estricta Usuario-IP (User-to-IP Binding) (Anexo 4)
Implementación de enlace rígido 1:1 entre el ID de usuario de IBM i y la dirección IP estática autorizada de su estación de trabajo en la red interna segura. Todo intento de autenticación exitosa que se origine desde una dirección IP no autorizada es bloqueado y rechazado de inmediato a nivel de subsistema.

Control Compensatorio 3: Bloqueo de Descargas y Consultas Ad-Hoc vía Exit Points (Anexo 3 y 5)
Configuración de reglas 'Deny-by-Default' en los puntos de salida de IBM i para los servidores de base de datos (QIBM_QZDA_SQL, QIBM_QZDA_INIT), servidores de archivos (FTP, File Server) y mandatos remotos. Se bloquea de forma absoluta cualquier extracción masiva, query SQL ad-hoc vía ODBC/JDBC o descarga a hojas de cálculo sobre las 5 tablas de FACT (PHYON2, PHYSODV, etc.).

Control Compensatorio 4: Prevención de Fuga de Información (DLP Perimetral y de Estación) (Anexo 6)
Bloqueo técnico de dispositivos de almacenamiento masivo (USB), restricción total para compartir archivos hacia redes externas, inhabilitación de copiado de pantalla no autorizado y control riguroso de impresión en las estaciones del CDE.

Control Compensatorio 5: Contención y Gestión Estricta de Superusuarios (*ALLOBJ) y Monitoreo QAUDJRN (Anexo 3)
1. Techo Máximo y Límite de *ALLOBJ: Cuota estricta de máximo 10 perfiles nominales de administración técnica con autoridad especial *ALLOBJ. Prohibición total de perfiles genéricos o compartidos.
2. Inhabilitación de Utilitarios de SO: Restricción absoluta de mandatos interactivos de manipulación directa de datos (STRSQL, RUNSQL, DFU, DBU, UPDLOG, CPYF) para usuarios de negocio y soporte aplicativo.
3. Monitoreo en Tiempo Real de QAUDJRN: Vigilancia continua de entradas CD (Command String), AF (Authority Failure) y ZC (Object Access) vinculadas al SIEM/SOC corporativo, generando alertas inmediatas ante cualquier intento de acceder a las tablas de FACT fuera del binario autorizado.
"@
    $table.Cell(3, 3).Range.Text = $r3Text

    # Fila 4: Declaración de No-Reutilización de Controles Base
    $table.Cell(4, 1).Range.Text = "3. Declaración de No-Reutilización de Controles Estándar (Non-Reliance)"
    $table.Cell(4, 2).Range.Text = "Demostrar que los controles compensatorios no reutilizan controles requeridos por otros apartados de PCI DSS."
    $r4Text = @"
En estricto apego a las directrices del Apéndice B, se declara formalmente que los controles compensatorios representan salvaguardas extraordinarias y no constituyen una duplicación de los requisitos base de PCI DSS v4.0.1:

1. Autenticación Multifactor (Req. 8.4 / 8.5): El MFA es un estándar de acceso; el control compensatorio ESPECÍFICO es la vinculación rígida Usuario-IP (User-IP Binding) y el enmascaramiento dinámico a nivel de presentación.
2. Gestión de Privilegios y Aprobaciones (Req. 7.2.x): El proceso de asignación de roles es estándar; el control compensatorio ESPECÍFICO es la prohibición a nivel de Exit Points de consultar las tablas de FACT vía ODBC/JDBC y el bloqueo de utilitarios de SO (STRSQL, DFU).
3. Registro de Eventos (Req. 10.2): La captura de logs es mandatoria; el control compensatorio ESPECÍFICO es la regla de detección heurística en tiempo real en QAUDJRN configurada en el SIEM para alertar sobre accesos anómalos a las 5 tablas físicas de FACT fuera de FACT.
4. Revisión Diaria de Seguridad (Req. 10.4.1): Es una rutina general; el control compensatorio ESPECÍFICO es el seguimiento diario de la métrica de 0 alertas no gestionadas de Exit Points sobre FACT.
5. Cifrado y Tokenización (Req. 3.5.1 en otros alcances): CryptGrid (IST Switch) y GoAnywhere (archivos planos) son controles estándar en sus propios ámbitos, declarados aquí únicamente como evidencia de defensa en profundidad, mas NO se computan como compensación de FACT.
"@
    $table.Cell(4, 3).Range.Text = $r4Text

    # Fila 5: Objetivos del Control
    $table.Cell(5, 1).Range.Text = "4. Objetivos del Control"
    $table.Cell(5, 2).Range.Text = "a) Definir el objetivo del control original.`nb) Identificar el objetivo cumplido por el control compensatorio."
    $r5Text = @"
a) Objetivo del Control Original (PCI DSS v4.0.1 Req. 3.5.1):
Garantizar que el PAN se mantenga ilegible donde sea que se almacene mediante criptografía sólida, tokenización o truncamiento irreversible, protegiendo los datos de tarjetahabientes ante accesos o extracciones no autorizadas a los repositorios de almacenamiento.

b) Objetivo Cumplido por el Control Compensatorio:
Prevenir la exposición, acceso indebido, alteración o exfiltración no autorizada del PAN en claro almacenado en las tablas DB2 de FACT mediante un esquema sinérgico de seguridad en profundidad:
1. Minimización de Exposición: Enmascaramiento 6+4 por defecto en la interfaz FACT para las operaciones cotidianas.
2. Aislamiento Lógico de Transporte: User-to-IP Binding estricto y bloqueo absoluto de interfaces de red remotas vía Exit Points.
3. Contención Estricta de Superusuarios: Mitigación del riesgo de cuentas con autoridad *ALLOBJ mediante trazabilidad total en QAUDJRN y bloqueo de utilitarios interactivos.
4. Prevención de Fuga de Información: Inhabilitación de vectores físicos y digitales de extracción.
"@
    $table.Cell(5, 3).Range.Text = $r5Text

    # Fila 6: Riesgo Identificado y Proporcionalidad
    $table.Cell(6, 1).Range.Text = "5. Riesgo Identificado y Proporcionalidad"
    $table.Cell(6, 2).Range.Text = "Definir cualquier riesgo adicional resultante de la ausencia del control original y justificar la proporcionalidad del control."
    $r6Text = @"
A. Identificación del Riesgo Específico Residual:
El riesgo residual primario radica en que un usuario interno con altos privilegios de sistema (*ALLOBJ) o un atacante con credenciales comprometidas intente eludir la interfaz de FACT para consultar directamente las tablas DB2, visualizando o extrayendo registros que contienen el PAN en texto claro.

B. Cuantificación y Proporcionalidad del Entorno:
1. Delimitación de Tablas: El PAN en claro reside exclusivamente en cinco (5) tablas físicas de FACT en la biblioteca de producción:
- PHYON2: Maestro de transacciones adquirencia.
- PHYSODV: Transacciones de solicitud de autorización.
- PHYRIPM: Liquidación y compensación de adquirencia.
- PHYMOAP: Movimientos aplicados.
- OUTGOING: Mensajería de salida hacia franquicias.
2. Volumen Acotado: El almacenamiento se circunscribe a transacciones de tarjetas procesadas por la adquirencia del banco dentro del periodo de retención operativa.
3. Reducción y Justificación Estricta del Listado de Usuarios (Anexo 2):
En atención directa a la observación del QSA, el listado de usuarios autorizados para ver PAN completo se depuró y redujo de 38 a 26 usuarios justificados por rol de negocio:
- Prevención de Fraude (Investigación de reclamos y contracargos): 12 usuarios.
- Contabilidad de Tarjetas (Cuadratura y conciliación financiera): 8 usuarios.
- Operaciones de Tarjetas (Casos excepcionales de reclamos operativos): 6 usuarios.
Total: 26 usuarios (Reducción formal del 31.5%).
Cada uno de los 26 usuarios cuenta con:
a) Ficha de justificación individual firmada por su Gerente de Área.
b) Aprobación formal de la Gerencia de Administración de Seguridad.
c) Obligatoriedad de autenticación MFA.
d) Vinculación estricta a su dirección IP estática individual.
"@
    $table.Cell(6, 3).Range.Text = $r6Text

    # Fila 7: Validación de Controles Compensatorios
    $table.Cell(7, 1).Range.Text = "6. Validación y Procedimientos de Prueba"
    $table.Cell(7, 2).Range.Text = "Definir cómo se validaron y ejecutaron las pruebas técnicas de los controles compensatorios."
    $r7Text = @"
Se ejecutaron pruebas técnicas exhaustivas para validar la operatividad y efectividad de los controles:

Prueba 1: Validación de Enmascaramiento en FACT (Anexo 1)
Se constató que los perfiles operativos estándar visualicen únicamente el PAN ofuscado (411016******8024). Al intentar invocar la opción 'A', el sistema valida la tabla de autorización; si el usuario no pertenece a la lista aprobada, la opción es rechazada con mensaje de seguridad.

Prueba 2: Simulación de Rechazo por User-to-IP Binding (Anexo 4 y 5)
Se intentó iniciar sesión con una cuenta autorizada desde una estación de trabajo con una IP no registrada en la lista blanca. Resultado: La conexión fue rechazada de inmediato por el Exit Program a nivel de socket de red, registrando el evento de intento no autorizado.

Prueba 3: Prueba de Bloqueo de Consultas Externas vía Exit Points (Anexo 3 y 5)
Se ejecutó una consulta SQL ad-hoc vía ODBC/JDBC contra la tabla PHYON2 utilizando credenciales válidas. Resultado: El Exit Program QIBM_QZDA_SQL interceptó la petición, bloqueó la ejecución de la consulta y generó un registro de alerta de seguridad.

Prueba 4: Verificación de Logs sin PAN en Claro (Anexo 9)
Se auditó una muestra aleatoria de 500 registros del diario de auditoría QAUDJRN, journals de DB2 y colas de mensajes del sistema. Se constató que las trazas registran usuario, timestamp, mandato y objeto, pero en ningún caso exponen el valor del PAN en texto claro en los parámetros registrados.

Prueba 5: Prueba de Ilegibilidad Criptográfica en GoAnywhere y Cintas (Anexo 7)
Se extrajo un archivo plano protegido por GoAnywhere y se intentó abrir en un entorno sin la llave privada PGP correspondiente, obteniendo el rechazo criptográfico 'Secret key not available'. Asimismo, se verificó el cifrado por hardware/software de las cintas de respaldo.

Prueba 6: Barrido de Descubrimiento de Datos (Data Discovery) (Anexo 7)
Se ejecutó un barrido automatizado con patrones regex de PAN sobre bases de datos, IFS y logs, confirmando que no existe almacenamiento de PAN en claro fuera de las 5 tablas físicas autorizadas de FACT.
"@
    $table.Cell(7, 3).Range.Text = $r7Text

    # Fila 8: Métricas de Eficacia Operativa
    $table.Cell(8, 1).Range.Text = "7. Métricas de Eficacia Operativa y Umbrales de Alarma"
    $table.Cell(8, 2).Range.Text = "Definir indicadores cuantitativos, frecuencias de medición, umbrales de alarma, tolerancias y responsables asignados."
    $r8Text = @"
Matriz de Métricas de Eficacia Operativa (Obligatorias Apéndice B):

1. Métrica: Porcentaje de usuarios con visualización de PAN en claro debidamente aprobados y justificados.
- Fórmula: (Usuarios con aprobación vigente / Total usuarios con permiso) * 100
- Frecuencia: Mensual | Meta: 100% | Umbral de Alarma: < 100% (Tolerancia: 0)
- Responsable: Gerencia de Administración de Seguridad.

2. Métrica: Intentos bloqueados por Exit Point y User-IP Binding investigados.
- Fórmula: (Intentos bloqueados analizados e investigados / Total intentos) * 100
- Frecuencia: Diaria | Meta: 100% investigados en < 24h | Umbral de Alarma: > 0 sin gestionar
- Responsable: Gerencia de Administración de Seguridad / SOC.

3. Métrica: Días hábiles sin revisión de alarmas de seguridad de IBM i (Proc. 368-SICPR-01).
- Fórmula: Días con bitácora de revisión completada.
- Frecuencia: Diaria | Meta: 0 días sin revisión | Umbral de Alarma: >= 1 día
- Responsable: Analista de Seguridad de Administración de Identidades.

4. Métrica: Discrepancias entre lista aprobada en FACT y usuarios configurados en sistema.
- Fórmula: Conteo de usuarios no coincidentes entre archivo de control y DB2.
- Frecuencia: Quincenal | Meta: 0 discrepancias | Umbral de Alarma: > 0
- Responsable: Seguridad de la Información.

5. Métrica: Perfiles con autoridad especial *ALLOBJ activos en CDE.
- Fórmula: Total de perfiles con *ALLOBJ auditados vs. límite autorizado (máx 10).
- Frecuencia: Mensual | Meta: <= 10 | Umbral de Alarma: > 10 o altas no aprobadas
- Responsable: Gerencia de Administración de Seguridad.

6. Métrica: Consultas interactivas o de utilitarios (STRSQL/DFU) sobre tablas de FACT.
- Fórmula: Eventos en QAUDJRN de acceso fuera del binario aplicativo.
- Frecuencia: Continua (Tiempo Real) | Meta: 0 eventos | Umbral de Alarma: >= 1 evento
- Responsable: Ciberseguridad / SOC.
"@
    $table.Cell(8, 3).Range.Text = $r8Text

    # Fila 9: Mantenimiento y Revisión Anual
    $table.Cell(9, 1).Range.Text = "8. Mantenimiento Continuo y Revisión Anual (Req. 12.3.2)"
    $table.Cell(9, 2).Range.Text = "Definir los procesos de gobernanza continua y la revisión periódica anual requerida por el estándar."
    $r9Text = @"
A. Procesos de Mantenimiento y Gobierno Operativo:
- Vigilancia Diaria: Monitoreo y atención de alertas de seguridad generadas por la herramienta de Exit Points y QAUDJRN conforme al procedimiento 368-SICPR-01.
- Auditoría Mensual de Superusuarios: Revisión de la lista de perfiles con *ALLOBJ y conciliación de la matriz User-to-IP Binding.
- Revalidación Semestral de Usuarios: Certificación obligatoria de la justificación de negocio de los 26 usuarios permisados con sus respectivas gerencias de área.
- Protocolo de Respuesta a Incidentes: Activación del playbook específico para contención de incidentes de PAN en claro fuera de CDE (Procedimiento 313-SICPN-01).

B. Revisión Anual Formal y Atestación (PCI DSS v4.0.1 Req. 12.3.2):
De conformidad con el Requisito 12.3.2 de PCI DSS v4.0.1, este control compensatorio es sometido a revisión anual formal por parte de la Gerencia de Administración de Seguridad de Banesco y el Asesor de Seguridad Calificado (QSA), evaluando la vigencia de las restricciones técnicas, la eficacia operativa de los controles compensatorios y el progreso del Roadmap de sustitución del Core hacia su fecha comprometida de cierre (31 de Diciembre de 2026).
"@
    $table.Cell(9, 3).Range.Text = $r9Text

    # Formatear el contenido de la tabla
    for ($r = 2; $r -le 9; $r++) {
        $table.Cell($r, 1).Range.Font.Name = "Arial"
        $table.Cell($r, 1).Range.Font.Size = 9.5
        $table.Cell($r, 1).Range.Font.Bold = $true
        $table.Cell($r, 1).Range.Font.Color = $WD_COLOR_NAVY
        $table.Cell($r, 1).Shading.BackgroundPatternColor = $WD_COLOR_ALERT_BG

        $table.Cell($r, 2).Range.Font.Name = "Arial"
        $table.Cell($r, 2).Range.Font.Size = 9
        $table.Cell($r, 2).Range.Font.Bold = $true
        $table.Cell($r, 2).Range.Font.Color = 3355443

        $table.Cell($r, 3).Range.Font.Name = "Arial"
        $table.Cell($r, 3).Range.Font.Size = 8.5
        $table.Cell($r, 3).Range.Font.Bold = $false
        $table.Cell($r, 3).Range.Font.Color = 0
        $table.Cell($r, 3).Range.ParagraphFormat.Alignment = 3 # Justify
    }

    # Desplazar el cursor despues de la tabla
    $selection.EndKey(6)
    $selection.TypeParagraph()

    # Seccion de Firmas de Aprobación
    Add-Heading1 -text "4. Aprobación Formal y Validación Anual (PCI DSS v4.0.1 Req. 12.3.2)"
    Add-BodyParagraph -text "La presente Ficha de Control Compensatorio ha sido revisada, evaluada técnicamente y formalmente validada por los responsables de la entidad bancaria y el Asesor de Seguridad Calificado (QSA):"

    $sigTable = $doc.Tables.Add($selection.Range, 4, 3)
    $sigTable.Borders.Enable = 1
    $sigTable.Borders.InsideColor = 13421772
    $sigTable.Borders.OutsideColor = $WD_COLOR_NAVY

    $sigTable.Columns.Item(1).Width = 168
    $sigTable.Columns.Item(2).Width = 168
    $sigTable.Columns.Item(3).Width = 168

    $sigTable.Rows.Item(1).Shading.BackgroundPatternColor = $WD_COLOR_HEADER_BG
    $sigTable.Cell(1, 1).Range.Text = "Por Banesco - Seguridad"
    $sigTable.Cell(1, 2).Range.Text = "Por Banesco - Tecnología"
    $sigTable.Cell(1, 3).Range.Text = "Por la Firma Auditora QSA"

    $sigTable.Cell(2, 1).Range.Text = "`n`n____________________________`nFirma Autorizada`nGerencia de Administración de Seguridad`nBanesco Banco Universal"
    $sigTable.Cell(2, 2).Range.Text = "`n`n____________________________`nFirma Autorizada`nVicepresidencia Ejecutiva de Operaciones y TI`nBanesco Banco Universal"
    $sigTable.Cell(2, 3).Range.Text = "`n`n____________________________`nFirma del Evaluador QSA`nLead Security Assessor (QSA)`nCertificación PCI DSS v4.0.1"

    $sigTable.Cell(3, 1).Range.Text = "Nombre: Gerente de Administración de Seguridad"
    $sigTable.Cell(3, 2).Range.Text = "Nombre: Vicepresidente de Operaciones y TI"
    $sigTable.Cell(3, 3).Range.Text = "Nombre del QSA Evaluador Principal"

    $sigTable.Cell(4, 1).Range.Text = "Fecha: ____/____/2026"
    $sigTable.Cell(4, 2).Range.Text = "Fecha: ____/____/2026"
    $sigTable.Cell(4, 3).Range.Text = "Fecha: ____/____/2026"

    for ($sr = 1; $sr -le 4; $sr++) {
        for ($sc = 1; $sc -le 3; $sc++) {
            $sigTable.Cell($sr, $sc).Range.Font.Name = "Arial"
            $sigTable.Cell($sr, $sc).Range.Font.Size = 8.5
            if ($sr -eq 1) { $sigTable.Cell($sr, $sc).Range.Font.Bold = $true }
        }
    }

    $selection.EndKey(6)
    $selection.TypeParagraph()

    # Seccion de Anexos
    Add-Heading1 -text "5. Matriz de Anexos y Evidencias Técnicas"
    Add-BodyParagraph -text "A continuación se lista el compendio completo de evidencias probatorias que sustentan de manera irrefutable la operatividad del presente control compensatorio, subsanando todas las solicitudes emitidas por el equipo auditor:"

    $anexos = @(
        @("Anexo 0", "Roadmap Ejecutivo Aprobado de Sustitución del Core de Medios de Pago", "Documento independiente suscrito por la Vicepresidencia Ejecutiva con cronograma detallado, hitos de avance y fecha de cierre definitiva (Target Sunset Date: 31/12/2026)."),
        @("Anexo 0B", "Dictamen Técnico de Arquitectura: Inviabilidad de FIELDPROC en IBM i v7.5", "Análisis formal de ingeniería descartando la viabilidad de FIELDPROC en tablas FACT por incompatibilidad con accesos por registro nativo RPG/COBOL, buffers fijos y ruptura de índices en Archivos Lógicos."),
        @("Anexo 1", "Evidencia Técnica de Enmascaramiento Dinámico en Aplicativo FACT", "Capturas de pantalla del módulo de adquirencia mostrando la ofuscación 6+4 por defecto (opción 'O') y el rechazo de la opción 'A' para perfiles no autorizados."),
        @("Anexo 2", "Matriz Depurada y Justificada de Usuarios Autorizados para Visualizar PAN Completo", "Listado formalmente reducido a 26 usuarios justificados por rol de negocio (Fraude, Contabilidad, Operaciones), anexando carta individual de aprobación gerencial y evidencia de MFA habilitado."),
        @("Anexo 3", "Auditoría de Perfiles con Autoridad Especial *ALLOBJ y Reglas Exit Points", "Reporte de auditoría demostrando el cumplimiento del límite máximo de perfiles *ALLOBJ (máximo 10 nominales), ausencia de perfiles genéricos y configuración de alertas de mandatos en QAUDJRN."),
        @("Anexo 4", "Configuración de Vinculación Estricta Usuario-IP (User-to-IP Binding)", "Tablas de configuración de la herramienta de seguridad asociando de manera rígida los IDs de usuario del IBM i con direcciones IP estáticas específicas de estaciones de trabajo CDE."),
        @("Anexo 5", "Evidencias de Bloqueo y Alertas de Conexiones No Autorizadas y Consultas SQL", "Pantallas de rechazo ante intentos de conexión desde IPs no registradas, bloqueo de queries ad-hoc vía ODBC/JDBC sobre tablas FACT y alertas automáticas enviadas al SIEM/SOC."),
        @("Anexo 6", "Evidencias de Controles DLP Perimetrales en el CDE", "Configuración de directivas de grupo y software de seguridad que bloquea puertos USB, unidades de almacenamiento extraíble, redirecciones de red e impresiones no autorizadas."),
        @("Anexo 7", "Pruebas de Ilegibilidad en Almacenamiento, Cintas y Data Discovery", "Resultados del barrido automatizado de PAN (demostrando ausencia de PAN fuera de las 5 tablas de FACT), prueba técnica de denegación de apertura sin llave en GoAnywhere PGP y evidencia de cifrado en cintas LTO."),
        @("Anexo 8", "Procedimiento Operativo 368-SICPR-01 y Playbook de Respuesta a Incidentes 313-SICPN-01", "Norma de monitoreo diario obligatorio de alertas de seguridad de IBM i con bitácora de cumplimiento y playbook de contención en caso de fuga de datos de tarjetas."),
        @("Anexo 9", "Muestras de Logs de Auditoría y Trazas QAUDJRN libres de PAN en Claro", "Extractos de logs de transacciones, diarios de base de datos y receptores de auditoría demostrando que ningún evento almacena el PAN en claro en sus parámetros registrados."),
        @("Anexo 10", "Atestación de Validación (AoV) Vigente de la Plataforma IST Switch", "Documentación que ratifica el estado de certificación y soporte del switch transaccional dentro del ecosistema de pagos de la institución.")
    )

    $anexoTable = $doc.Tables.Add($selection.Range, ($anexos.Count + 1), 3)
    $anexoTable.Borders.Enable = 1
    $anexoTable.Borders.InsideColor = 13421772
    $anexoTable.Borders.OutsideColor = $WD_COLOR_NAVY

    $anexoTable.Columns.Item(1).Width = 72
    $anexoTable.Columns.Item(2).Width = 180
    $anexoTable.Columns.Item(3).Width = 252

    $anexoTable.Rows.Item(1).Shading.BackgroundPatternColor = $WD_COLOR_HEADER_BG
    $anexoTable.Cell(1, 1).Range.Text = "Anexo"
    $anexoTable.Cell(1, 2).Range.Text = "Título del Documento / Evidencia"
    $anexoTable.Cell(1, 3).Range.Text = "Alcance Probatorio y Descripción"

    $anexoTable.Rows.Item(1).Range.Font.Name = "Arial"
    $anexoTable.Rows.Item(1).Range.Font.Size = 9.5
    $anexoTable.Rows.Item(1).Range.Font.Bold = $true
    $anexoTable.Rows.Item(1).Range.Font.Color = $WD_COLOR_NAVY

    for ($i = 0; $i -lt $anexos.Count; $i++) {
        $rowIdx = $i + 2
        $anexoTable.Cell($rowIdx, 1).Range.Text = $anexos[$i][0]
        $anexoTable.Cell($rowIdx, 2).Range.Text = $anexos[$i][1]
        $anexoTable.Cell($rowIdx, 3).Range.Text = $anexos[$i][2]

        $anexoTable.Cell($rowIdx, 1).Range.Font.Name = "Arial"
        $anexoTable.Cell($rowIdx, 1).Range.Font.Size = 9
        $anexoTable.Cell($rowIdx, 1).Range.Font.Bold = $true
        $anexoTable.Cell($rowIdx, 1).Range.Font.Color = $WD_COLOR_NAVY

        $anexoTable.Cell($rowIdx, 2).Range.Font.Name = "Arial"
        $anexoTable.Cell($rowIdx, 2).Range.Font.Size = 8.5
        $anexoTable.Cell($rowIdx, 2).Range.Font.Bold = $true

        $anexoTable.Cell($rowIdx, 3).Range.Font.Name = "Arial"
        $anexoTable.Cell($rowIdx, 3).Range.Font.Size = 8.5
        $anexoTable.Cell($rowIdx, 3).Range.ParagraphFormat.Alignment = 3
    }

    Write-Host "[INFO] Guardando documento en $outputPath..."
    $doc.SaveAs([ref]$outputPath)
    Write-Host "[OK] Documento Word generado exitosamente."

}
catch {
    Write-Host "[ERROR] Error durante la generacion del documento: $_"
    throw $_
}
finally {
    if ($doc -ne $null) {
        $doc.Close([ref]$false)
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
    if ($word -ne $null) {
        $word.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
