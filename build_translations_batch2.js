const fs = require('fs');
const path = require('path');

const targetDir = 'D:\\Cerebro Digital';

// 1. GUIA INSTALACION SIEM AGENT 4.10
const siemInstalacion = `# Guía de Instalación - Powertech SIEM Agent for IBM i 4.10
**Versión del Producto:** 4.10  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Antes de Comenzar
Lea esta sección antes de instalar, actualizar o migrar Powertech SIEM Agent for IBM i.

### Licenciamiento
SIEM Agent para IBM i requiere una clave de licencia válida por partición/serie. Contacte a \`keys@fortra.com\` para solicitar o renovar licencias.

### Requisitos del Sistema
* IBM i versión 7.3 o superior.
* En V7R3: PTF SI62950 instalada.
* Biblioteca \`QHTTPSVR\` (IBM HTTP Server for i) instalada bajo el programa bajo licencia 5770-DG1.
* Java 8 y Kafka 2.5 o superior (únicamente si se van a enviar eventos hacia Apache Kafka).
* Puerto FTP estándar (21) o FTPS (990) abierto y a la escucha en el IBM i para permitir la conexión del asistente de instalación.

---

## 2. Valores del Sistema (System Values)
Configuración requerida previa a la instalación:
* **\`QALWOBJRST\`:** Establecer en \`*ALWPGMADP\` (mínimo) o temporalmente \`*ALL\`.
* **\`QALWUSRDMN\`:** Debe incluir las bibliotecas de instalación de SIEM Agent: **\`PTSALIB\`** y **\`PTPLLIB\`**, o configurarse en \`*ALL\`.
* **\`QVFYOBJRST\`:** Establecer en 1, 2 o 3.
* **\`QFRCCVNRST\`:** Establecer en 0 (*Do not convert anything*).

---

## 3. Actualización desde Interact 3 a SIEM Agent versión 4
* En SIEM Agent versión 4, el producto se instala en una nueva biblioteca: **\`PTSALIB\`**.
* La biblioteca anterior \`PTINTERACT\` no se altera y puede coexistir.
* Antes de actualizar, detenga los monitores de Interact 3:
  \`\`\`cl
  PTINTERACT/ENDPLIAMON
  \`\`\`
* Para convertir las configuraciones anteriores a SIEM Agent 4:
  \`\`\`cl
  PTSALIB/PSACVTINT OPTION(*CONVERT)
  \`\`\`
* Luego de la conversión, ejecute la opción 10 (**Commit configuration changes**) desde \`WRKPTSA\`.
* **Nota importante sobre Syslog:** En SIEM Agent 4, el valor del campo \`app-name\` en los mensajes Syslog cambió de \`"Interact"\` a \`"SIEM Agent"\`.

---

## 4. Proceso de Instalación

1. Descargue \`setupSIEMAgent.exe\` y ejecútelo en su PC con Windows.
2. Seleccione instalar Manuales y Software para IBM i.
   - *Manuales locales:* \`C:\\Program Files\\PowerTech\\SIEM Agent for IBM i\\manuals\`
3. Ingrese los datos de conexión del IBM i con un perfil \`*SECOFR\` con autoridades \`*ALLOBJ\`, \`*SECADM\`, \`*JOBCTL\`, \`*IOSYSCFG\`, \`*SERVICE\`, \`*SPLCTL\` y \`*AUDIT\`, con \`LMTCPB(*NO)\`.
4. Elija **Immediate Load** (Carga Inmediata) o **Staged Load** (vía \`HSLOADMGR/HSWRKLOAD\`).
5. Al finalizar, ejecute la opción 10 (**Commit configuration changes**) en \`WRKPTSA\` para inicializar los monitores.

---

## 5. Recursos Instalados en el IBM i

| Objeto / Recurso | Tipo / Ubicación | Descripción |
| :--- | :--- | :--- |
| **Bibliotecas** | \`PTSALIB\`<br>\`PTPLLIB\`<br>\`PTWRKMGT\` | Biblioteca principal de SIEM Agent.<br>Biblioteca de comunicaciones y productos Powertech.<br>Subsistema de gestión de trabajos en segundo plano. |
| **Perfiles** | \`PTADMIN\` / \`PTUSER\` | Administrador del producto y ejecutor de procesos (Password = \`*NONE\`). |
| **Lista Autorización**| \`PTADMIN\` | Lista de usuarios autorizados a gestionar SIEM Agent. |
| **Comando Principal** | \`QGPL/WRKPTSA\` | Acceso al menú general de configuración del SIEM Agent. |
| **Cola de Trabajos** | \`PSAJOBQ\` | Ubicada en \`PTSALIB\` (Max Active: 1000). |
| **Directorio IFS** | \`/Powertech/SIEMAgent\` | Aloja conectores Java Kafka (\`kafka-clients-2.5.0.jar\`, \`slf4j-api-1.7.30.jar\`). |
`;

// 2. GUIA IMPLEMENTACION SIEM AGENT 4.10
const siemImplementacion = `# Guía de Implementación y Mejores Prácticas - Powertech SIEM Agent 4.10
**Versión del Producto:** 4.10  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Arquitectura y Principio de Operación
Powertech SIEM Agent extrae datos relevantes de seguridad desde **Fuentes de Eventos (*Event Sources*)**, los reestructura según un **Formato (*Format*)** y los transmite a través de un **Destino de Salida (*Output Target*)** hacia consolas SIEM como Event Manager, IBM QRadar, Splunk, Microsoft Sentinel o servidores Syslog.

\`\`\`mermaid
flowchart LR
    A["Event Sources (QAUDJRN, PCSLOG, MSGQ)"] --> B["Monitores (PSAMGRMON en PTWRKMGT)"]
    B --> C["Motor de Reglas y Filtros"]
    C --> D["Formateador (Syslog, CEF, LEEF, JSON)"]
    D --> E["Output Target (UDP/TCP/TLS 514 / Kafka)"]
    E --> F["Event Manager / SIEM Corporativo"]
\`\`\`

---

## 2. Configuración de Salidas (Outputs)

1. En el menú principal \`WRKPTSA\`, elija la opción **3. Work with Outputs**.
2. Presione **F6=Create**.
3. Parámetros clave:
   * **Name:** Nombre del destino (ejemplo: \`EVENTMAN\`).
   * **Active:** \`1\` (Habilitado).
   * **Format:** Formato de salida (\`SYSLOG\`, \`CEF\`, \`LEEF\`, etc.).
   * **Type:** Tipo de destino:
     - \`*NETWORK\`: Dirección IP o DNS del servidor SIEM (ej. \`10.132.211.29\`).
     - \`*MSGQ\`: Cola de mensajes en IBM i.
     - \`*STREAM\`: Archivo stream en IFS.
     - \`*KAFKA\`: Servidor Apache Kafka.
   * **Port:** Puerto de escucha del SIEM (normalmente \`514\` para Syslog).
   * **Protocol:** \`*UDP\`, \`*TCP\` o \`*TLS\`.
   * **Event Manager Server / ArcSight Compatibility:**
     - Establezca en \`0\` para estándar Event Manager. (*Si se marca 1 para ArcSight, se invierten los atributos src y dst*).

---

## 3. Fuentes de Eventos (Event Sources)
En la opción **1. Work with Event Sources** de \`WRKPTSA\`:

| Fuente | Tipo | Diario / Cola | Propósito |
| :--- | :--- | :--- | :--- |
| **\`*AUDIT\`** | Diario | \`QSYS/QAUDJRN\` | Auditoría nativa del sistema operativo IBM i (entradas TAF, TCD, TCP, etc.). |
| **\`*CMDSEC\`** | Diario | \`PTCSLIB/PCSLOG\` | Intercepciones y auditoría de Powertech Command Security. |
| **\`*NETSEC\`** | Diario | Servidor de red | Registros de transacciones de Powertech Network Security / EPM. |
| **\`*AUTBRK\`** | Diario | \`PTABLIB/ABLOG\` | Elevaciones de privilegios de Powertech Authority Broker. |
| **\`*MSGQ\`** | Cola | \`QSYSOPR\` | Mensajes críticos de la cola del operador del sistema. |

---

## 4. Mapeo de Eventos de Command Security (*CMDSEC)
Para Command Security, los identificadores de mensaje (*MSG ID*) se componen de 3 caracteres:
* **Primera letra:** \`U\` (Entradas de diario definidas por usuario de Powertech desde \`PCSLOG\`).
* **Segunda y tercera letra:**
  * **\`UMI\`**: *Monitored Command Initiation* (Inicio del comando).
  * **\`UMA\`**: *Monitored Command Termination - Allowed* (Comando permitido).
  * **\`UMR\`**: *Monitored Command Termination - Rejected* (Comando rechazado por regla).
  * **\`UAE\`**: *Action Executed* (Acción ejecutada, ej. envío de alerta o modificación de parámetros).
  * **\`UAF\`**: *Action Failed* (Fallo en la ejecución de la acción).
  * **\`UMM\`**: *Could not and rejected*.
  * **\`UMN\`**: *Could not and allowed*.

> **Paso Crítico:** En \`WRKPTSA\`, opción 1 > opción 8 en \`*CMDSEC\`, la salida \`EVENTMAN\` **debe estar adjuntada (*Attached Outputs*)** y los eventos \`UMI\`, \`UMA\`, \`UMR\` deben tener valor **\`1\` (Activo)**.

---

## 5. Reglas y Filtros de Reducción de Ruido
Para evitar saturar el SIEM con transacciones batch rutinarias:
1. En \`WRKPTSA\`, entre con opción 2 (*Event Descriptions*) en la fuente deseada.
2. Seleccione el evento (ej. \`UMI\` o \`TCD\`) y presione **9=Rules**.
3. Cree reglas con condiciones para excluir trabajos desatendidos o de mantenimiento (ej. \`*JOBUSER EQUALTO('QUSER')\` -> Acción \`*DROP\`).

---

## 6. Comandos CL de Control del SIEM Agent
* \`WRKPTSA\`: Menú principal del SIEM Agent.
* \`PSASTRMON MON(*ALL | *AUDIT | *CMDSEC)\`: Inicia los monitores en \`PTWRKMGT\`.
* \`PSAENDMON MON(*ALL | *AUDIT | *CMDSEC)\`: Detiene los monitores.
* \`PSAHCLMON\` / \`PSARLSMON\`: Pausa o reanuda un monitor sin finalizar el trabajo.
* \`PSATRCSIEM\`: Activa trazas de diagnóstico de bajo nivel en caso de problemas de red.
`;

// 3. GUIA DEL USUARIO SIEM AGENT 4.10
const siemUsuario = `# Guía del Usuario - Powertech SIEM Agent for IBM i 4.10
**Versión del Producto:** 4.10  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Menú Principal de SIEM Agent (\`WRKPTSA\`)

Al ejecutar \`WRKPTSA\` en pantalla verde 5250, se presenta el panel maestro:

* **1. Work with Event Sources (\`PSA4100\`):** Configura los orígenes de datos (diarios y colas de mensajes) y sus salidas adjuntas.
* **2. Work with Formats (\`PSA4300\`):** Administra las plantillas de formato de mensaje Syslog, CEF, LEEF, RFC 5424 y JSON.
* **3. Work with Outputs (\`PSA4400\`):** Define los destinos IP, puertos y protocolos hacia los que se transmiten los eventos.
* **4. Work with Extensions (\`PSA4500\`):** Campos adicionales enriquecidos (ej. IP del cliente, usuario del trabajo, pila de llamadas).
* **10. Commit configuration changes:** **IMPRESCINDIBLE.** Compila y aplica en memoria todas las modificaciones realizadas en fuentes, formatos y salidas, recargando los monitores activos en \`PTWRKMGT\`.
* **82. Work with Utilities:** Utilidades de mantenimiento, depuración y conversión.

---

## 2. Monitores Activos en el Subsistema \`PTWRKMGT\`

Para verificar que el SIEM Agent esté enviando eventos en tiempo real:
\`\`\`cl
WRKACTJOB SBS(PTWRKMGT)
\`\`\`
Debe observar los siguientes trabajos según las fuentes habilitadas:
* \`PSAMGRMON USR-EVENTMAN\`: Monitor de despacho hacia el destino \`EVENTMAN\` (estado \`RUN\` o \`SELW\`).
* \`PSAMGRMON USR-CMDSEC\`: Monitor lector del diario \`PTCSLIB/PCSLOG\` de Command Security.
* \`PSAMGRMON USR-AUDIT\`: Monitor lector del diario general \`QSYS/QAUDJRN\`.

---

## 3. Procedimiento para Vincular Command Security al SIEM

1. Ingrese a \`WRKPTSA\` > opción **1. Work with Event Sources**.
2. Ubique la fuente **\`CMDSEC\`** (*Command Security*).
3. Escriba opción **8 (Work with Attached Outputs)** al lado de \`CMDSEC\`.
   * Asegúrese de que la salida **\`EVENTMAN\`** figure en la lista con estado **\`1=Active\`**.
   * Si no está, presione **F6=Create** y seleccione \`EVENTMAN\`.
4. Regrese con F12 y escriba opción **2 (Work with Event Descriptions)** en \`CMDSEC\`.
   * Verifique que \`UMI\`, \`UMA\`, \`UMR\` y \`UAE\` tengan **\`Act = 1\`**.
5. Regrese al menú principal y seleccione la **opción 10 (Commit configuration changes)**.

---

## 4. Solución de Problemas y Alertas

* **Mensaje "ALERTS" en la cabecera de \`WRKPTSA\`:** Indica que el monitor detectó un corte de red, un receptor dañado o que el servidor SIEM destino no responde a los paquetes Syslog.
* **Ver registros de error del despachador:**
  \`\`\`cl
  DSPLOG PERIOD((*AVAIL *BEGIN)) MSGID(PSA0000)
  \`\`\`
  O consulte los spools del usuario \`PTUSER\` con \`WRKSPLF USER(PTUSER)\`.
`;

// 4. GUIA DEL USUARIO EVENT MANAGER 6.9
const eventManagerUsuario = `# Guía del Usuario - Fortra Event Manager 6.9
**Versión del Producto:** 6.9  
**Fabricante:** Fortra  
**Entorno:** Interfaz Web Insite / Servidor Event Manager  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Visión General de Event Manager
Fortra Event Manager centraliza, normaliza y correlaciona eventos de seguridad de toda la infraestructura corporativa (IBM i, Windows, Linux, Firewalls, Bases de Datos). Se accede a través de la interfaz web de HelpSystems/Fortra Insite (\`https://<servidor-insite>:19180\` o HTTPS corporativo).

---

## 2. Módulos Principales de la Consola Web

### A. Análisis Forense > Cronología (*Forensic Analysis > Timeline*)
* Es la consola operativa en tiempo real donde se visualizan todos los incidentes y eventos recolectados.
* **Filtros Clave en la Cabecera:**
  - **Activos (*Assets*):** Filtra por servidor específico (ej. \`S100906D\`).
  - **Buscador de Texto:** **Atención: Es sensible a Mayúsculas/Minúsculas (*Case-Sensitive*).** Los nombres de objetos y usuarios de IBM i deben buscarse estrictamente en MAYÚSCULAS (\`STRSQL\`, \`BANASIA029\`).
  - **Columnas:** Operador, Acción, Subacción, Objeto, Plataforma, Texto del Mensaje.
  - **Paginación:** Configurable en 10, 25, 50 o 100 líneas por página.

### B. Gestor de Eventos > Activos (*Event Manager > Assets*)
* Permite gestionar los servidores monitorizados.
* En cada activo se configuran sus **Acciones a Auditar (*Actions to Audit*)**, divididas en:
  - **Standard DataSources:** Conectores predefinidos por Fortra para sus productos de IBM i (\`Exit Point Manager\`, \`SIEM Agent for IBMi (QAUDJRN)\`, \`Authority Broker\`).
  - **DataSources Personalizados por el Usuario (*Custom DataSources*):** Receptores abiertos (Syslog, Syslog CEF, Microstream, Base de Datos, Windows Event Log).

---

## 3. Cómo Crear un DataSource para Command Security en Event Manager

Dado que en los activos de IBM i no existe un DataSource predeterminado llamado "Command Security", se debe integrar por una de las siguientes dos vías:

### Vía 1: DataSource Personalizado (Lector de Syslog)
1. Vaya a **Gestor de Eventos > Activos**.
2. Haga clic en el activo **\`S100906D\`** (o en el ícono de edición de la derecha).
3. Seleccione la pestaña **Acciones a Auditar**.
4. Desplácese hasta la sección **\`DATASOURCES PERSONALIZADOS POR EL USUARIO\`**.
5. Haga clic en el botón azul **\`+\`**.
6. En el menú desplegable, seleccione **\`Lector de Syslog\`** (o \`Lector de Syslog CEF\` según el formato de salida del AS400).
7. Configure:
   - **Estado:** Habilitado (Azul).
   - **Nombre:** \`Command Security\` (o \`Powertech Command Security\`).
   - **Filtro de IP:** Ingrese la IP del IBM i: \`10.137.0.138\`.
8. Guarde con **Aplicar** o **Aceptar**.

### Vía 2: Ingesta Nativa vía QAUDJRN (Sin DataSources adicionales)
* El conector preinstalado **\`SIEM Agent for IBM i (QAUDJRN)\`** ya está habilitado en el activo.
* Si el IBM i tiene activa la auditoría de comandos para el usuario (\`CHGUSRAUD USRPRF(...) AUDLVL(*CMD)\`) y el SIEM Agent tiene activo **\`TCD=1\`**, cualquier comando ejecutado entrará automáticamente por el DataSource estándar de QAUDJRN sin requerir configurar lectores personalizados.
`;

// 5. GUIA IMPLEMENTACION DATABASE MONITOR
const dbmImplementacion = `# Guía de Implementación - Powertech Database Monitor for IBM i
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400 - Db2 for i)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Resumen y Propósito
Powertech Database Monitor permite auditar y registrar quién modificó datos a nivel de registro en tablas y archivos físicos de Db2 for i, capturando el valor anterior (*Before Image*) y el valor nuevo (*After Image*).

---

## 2. Metodología de Implementación

1. **Identificar Tablas Críticas:** Seleccionar los archivos físicos (PF) y tablas que contienen datos regulados (PCI, SOX, balances contables, parámetros maestros).
2. **Registro de Archivos a Monitorear:**
   - En el menú principal de Database Monitor (\`WRKPTDBM\`), agregar los archivos especificando biblioteca y tabla.
3. **Definición de Campos Sensibles:**
   - Se puede seleccionar monitorear toda la tabla o campos específicos (por ejemplo: saldo, tasa de interés, estado de cuenta).
4. **Captura de Operaciones:**
   - Altas (\`*INSERT\`).
   - Modificaciones (\`*UPDATE\`).
   - Eliminaciones (\`*DELETE\`).
   - Lecturas no autorizadas (\`*READ\`).

---

## 3. Integración con SIEM Agent y Event Manager
Database Monitor registra las transacciones en un diario de base de datos dedicado. El **SIEM Agent** lee dicho diario y despacha alertas inmediatas a Event Manager ante modificaciones fuera de horario o ejecutadas por usuarios privilegiados fuera de la aplicación.
`;

// 6. GUIA DEL USUARIO DATABASE MONITOR
const dbmUsuario = `# Guía del Usuario - Powertech Database Monitor for IBM i
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400 - Db2 for i)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Navegación y Menú Principal (\`WRKPTDBM\`)
Comando para acceder a la gestión de auditoría de base de datos en pantalla verde:
\`\`\`cl
WRKPTDBM
\`\`\`

### Opciones Principales:
* **1. Work with Monitored Files:** Administra qué archivos físicos y tablas están bajo vigilancia de auditoría.
* **2. Work with Monitored Fields:** Configura qué columnas específicas disparan alertas.
* **3. Work with Filters:** Permite excluir trabajos del sistema o interfaces automáticas que procesan millones de registros diarios para evitar falsos positivos.
* **80. Reports:** Generación de reportes de auditoría de modificaciones de datos (*Before vs After*).

---

## 2. Diarios de Auditoría y Rendimiento
* Database Monitor utiliza la tecnología nativa de **Journaling de Db2** (\`STRJRNPF IMAGES(*BOTH)\`).
* Se recomienda utilizar receptores de diario con gestión automática de cambio (\`MNGRCV(*SYSTEM)\`) para garantizar que el rendimiento del subsistema bancario no se vea degradado.
`;

fs.writeFileSync(path.join(targetDir, 'Guia_Instalacion_SIEM_Agent_ES.md'), siemInstalacion, 'utf8');
console.log('1. Guia Instalacion SIEM Agent creada');

fs.writeFileSync(path.join(targetDir, 'Guia_Implementacion_SIEM_Agent_ES.md'), siemImplementacion, 'utf8');
console.log('2. Guia Implementacion SIEM Agent creada');

fs.writeFileSync(path.join(targetDir, 'Guia_del_Usuario_SIEM_Agent_ES.md'), siemUsuario, 'utf8');
console.log('3. Guia del Usuario SIEM Agent creada');

fs.writeFileSync(path.join(targetDir, 'Guia_del_Usuario_Event_Manager_ES.md'), eventManagerUsuario, 'utf8');
console.log('4. Guia del Usuario Event Manager creada');

fs.writeFileSync(path.join(targetDir, 'Guia_Implementacion_Database_Monitor_ES.md'), dbmImplementacion, 'utf8');
console.log('5. Guia Implementacion Database Monitor creada');

fs.writeFileSync(path.join(targetDir, 'Guia_del_Usuario_Database_Monitor_ES.md'), dbmUsuario, 'utf8');
console.log('6. Guia del Usuario Database Monitor creada');
