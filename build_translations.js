const fs = require('fs');
const path = require('path');

const targetDir = 'D:\\Cerebro Digital';

// 1. GUIA DE INSTALACION
const guiaInstalacion = `# Guía de Instalación - Powertech Command Security 1.16
**Versión del Producto:** 1.16  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Antes de Comenzar
Lea esta sección detenidamente antes de instalar Powertech Command Security.

> **Nota:** Instalación en Entornos de Alta Disponibilidad (HA):
> 1. Detenga la replicación de perfiles de usuario desde el sistema de producción hacia el sistema de HA, ya sea finalizando el software de replicación o finalizando la replicación de perfiles de usuario.
> 2. Instale Command Security tanto en el sistema de producción como en el de HA.
> 3. Configure la replicación de Command Security según las instrucciones de configuración de HA (*Command Security Setup in an HA Environment*).
> 4. Inicie la replicación (incluyendo los perfiles de usuario).

### Licenciamiento
Command Security requiere el ingreso de una clave de licencia válida. Póngase en contacto con keys@helpsystems.com si necesita solicitar una nueva clave.

### Requisitos del Sistema
Command Security requiere lo siguiente:
* IBM i versión 7.2 o superior.
* V7R2: PTF SI58106
* V7R2: PTF SI69104
* V7R3: PTF SI67661

> **Importante:** Durante la instalación se inicia una conexión FTP. El servidor FTP responde con mensajes que solicitan credenciales de inicio de sesión. El puerto estándar reservado para establecer una conexión FTP con IBM i es el **puerto 21**. Por consiguiente, es obligatorio que este puerto esté abierto y a la escucha en el servidor para establecer conexión con el Asistente de Instalación (*Installation Wizard*).  
> Si FTP no está disponible, debe instalar el producto manualmente.

---

## 2. Valores del Sistema (System Values)
La política de Powertech es no modificar los valores del sistema en los servidores de los clientes, reconociendo los rigurosos procesos de control de cambios existentes. Sin embargo, el proceso de instalación podría requerir ajustar temporalmente ciertos valores:

1. **\`QALWOBJRST\`:** Establecer en \`*ALWPGMADP\` (como mínimo) para permitir restaurar programas que adoptan autoridad. Muchos programas de Command Security adoptan la autoridad del propietario del producto. (*Para algunas configuraciones se requiere temporalmente \`*ALL\`*).
2. **\`QALWUSRDMN\`:** Controla qué bibliotecas pueden contener objetos de dominio de usuario. Debe configurarse en \`*ALL\` o incluir la biblioteca del producto **\`PTCSLIB\`** y **\`QTEMP\`**.
3. **\`QVFYOBJRST\`:** Establecer en \`1\`, \`2\` o \`3\`. Esto permite que Command Security restaure todos los objetos sin importar su firma digital.
4. **\`QFRCCVNRST\`:** (Forzar conversión al restaurar) Establecer en \`0\` o \`1\`.

---

## 3. Proceso de Instalación

1. Descargue el instalador de Command Security (\`setupCommandSecurity.exe\`) desde el portal de HelpSystems/Fortra y ejecútelo con doble clic.
2. En el panel **Choose Components**, seleccione los componentes a instalar (Manuales y/o Software para IBM i). Haga clic en **Next**.
   * *Ubicación local de manuales:* \`C:\\Program Files\\PowerTech\\Command Security\\manuals\`
3. En el panel **Choose a Destination IBM i**:
   * Seleccione o introduzca la dirección IP o nombre del IBM i de destino.
   * Ingrese un perfil de usuario y contraseña con clase \`*SECOFR\` y con las siguientes autoridades especiales mínimas:  
     \`*ALLOBJ\`, \`*SECADM\`, \`*JOBCTL\`, \`*SAVSYS\`, \`*IOSYSCFG\` y \`*AUDIT\`.  
     El perfil debe tener \`LMTCPB(*NO)\`.
   * En configuración avanzada, especifique el puerto FTP (por defecto 21) o FTPS (puerto 990 por defecto).
4. En el panel **Product Load Options**:
   * **Immediate Load:** Carga el producto en el IBM i de inmediato.
   * **Staged Load:** Transfiere los objetos ahora para cargarlos posteriormente en el IBM i mediante el comando \`HSLOADMGR/HSWRKLOAD\` (opción 1=Load).
5. Se ejecuta el progreso de carga. Al finalizar, haga clic en **Finish**.
6. Use el comando \`WRKSPLF\` para verificar el registro de trabajo (*job log*) de la instalación.

---

## 4. Objetos y Recursos Creados en el Sistema

| Objeto / Recurso | Nombre / Valor | Descripción |
| :--- | :--- | :--- |
| **Bibliotecas del Producto** | \`PTCSLIB\`<br>\`PTWRKMGT\` | Biblioteca de programas y reglas.<br>Biblioteca de gestión de trabajos del subsistema. |
| **Perfiles de Usuario** | \`PTADMIN\`<br>\`PTUSER\` | Similar a \`*SECOFR\` con \`*ALLOBJ\`, \`*SECADM\`, \`*JOBCTL\`, \`*AUDIT\` (Password = \`*NONE\`).<br>Similar a \`*USER\` sin autoridades especiales (Password = \`*NONE\`). |
| **Lista de Autorización** | \`PTADMIN\` | Todo usuario que administre Command Security debe pertenecer a esta lista con autoridad \`*USE\`. |
| **Comando Principal** | \`PTCSLIB/WRKPTCS\` | Inicia el entorno de trabajo y menú principal del producto. |
| **Subsistema** | \`PTWRKMGT\` | Subsistema de ejecución de monitores y procesos en segundo plano. |
| **Cola de Trabajos** | \`PCSJOBQ\` | Cola de trabajos asignada al subsistema \`PTWRKMGT\` (Max Active: 1000). |

---

## 5. Inicio del Producto
Para iniciar Powertech Command Security en pantalla verde 5250:
\`\`\`cl
PTCSLIB/WRKPTCS
\`\`\`
O mediante el menú general de Powertech:
\`\`\`cl
POWERTECH
\`\`\`
Opción correspondiente a Command Security.
`;

// 2. GUIA DE IMPLEMENTACION Y MEJORES PRACTICAS
const guiaImplementacion = `# Guía de Implementación y Mejores Prácticas - Powertech Command Security 1.16
**Versión del Producto:** 1.16  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Resumen y Propósito
Powertech Command Security permite supervisar, gestionar y gobernar la ejecución de mandatos CL en IBM i. Le permite especificar qué mandatos monitorear y, para cada uno, definir un conjunto de **Condiciones** (*Conditions*) que deben evaluarse y las **Acciones** (*Actions*) que se ejecutarán en respuesta.

Por ejemplo, puede definir que un mandato no pueda ejecutarse, que se ejecute únicamente con ciertos valores en sus parámetros o en franjas horarias específicas. Los mandatos evaluados pueden provenir de una línea de comandos interactiva, aplicaciones o trabajos en lote (*batch*).

---

## 2. Flujo de Trabajo para Asegurar un Mandato

1. **Seleccionar el mandato a monitorear:** No es necesario monitorear todos los mandatos; concéntrese en mandatos de alto impacto o donde sea necesario restringir incluso a usuarios con autoridad \`*ALLOBJ\`.
2. **Crear una Regla (*Rule*):** Cada regla se compone de Condiciones y Acciones.
3. **Definir Condiciones:** Establecen cuándo aplica la regla (evalúan a Verdadero o Falso). Pueden validar:
   - Quién es el usuario (\`*USER\`, \`*JOBUSER\`).
   - Perfil de grupo (\`*GRPPRF\`).
   - Autoridades especiales (\`*SPCAUT\`).
   - Tipo de trabajo (\`*JOBTYPE\` interactivo o batch).
   - Dirección IP del cliente (\`*LOCATION\`).
   - Fecha y Hora (\`*DATE\`, \`*TIME\`, \`*DAYOFWEEK\`).
   - Palabras clave / Parámetros del mandato (\`<keyword>\`).
   - Pila de llamadas (\`*STACK\`, \`*CALLER\`, \`*CALLERLIB\`).
4. **Determinar las Acciones a ejecutar:**
   - Rechazar al usuario (\`*REJECT\`).
   - Enviar un mensaje (\`*MSG\`, \`*LOGMSG\`, \`*QUEUEMSG\`).
   - Modificar el mandato (\`*ADDKWD\`, \`*RMVKWD\`, \`*RPLKWDVAL\`, \`*RPLCMD\`, \`*RPLALL\`).
   - Permitir y terminar evaluación (\`*ALLOW\`).
   - Ejecutar mandatos adicionales (\`*CMDINLINE\`, \`*COMMAND\`).

---

## 3. Control de Acceso a Command Security (Asegurar WRKPTCS)

El acceso al menú de Command Security está regido por la lista de autorización **\`PTADMIN\`**. No obstante, dado que un usuario con \`*ALLOBJ\` puede agregarse a sí mismo a dicha lista, la mejor práctica es proteger el mandato **\`WRKPTCS\`** dentro de Command Security creando una regla que sólo permita a **\`QSECOFR\`** (o al equipo de seguridad) ejecutarlo.

### Procedimiento:
1. Ir a opción **1. Work with Monitored Commands**.
2. Presionar **F6=Create** y seleccionar biblioteca \`PTCSLIB\`, mandato \`WRKPTCS\`.
3. Entrar con opción **8=Rules**.
4. Crear regla con Condición: \`*USER NOT EQUALTO('QSECOFR')\` (u operadores \`ONEOF\`).
5. Crear Acción: \`*REJECT\`.

---

## 4. Condiciones y Acciones con Nombre (Named Conditions & Named Actions)

* **Condición con Nombre (*Named Condition*):** Conjunto reutilizable de condiciones que se define una vez (por ejemplo: \`HORARIO_LABORAL\` o \`ADMINISTRADORES\`) y se asigna a múltiples mandatos.
* **Acción con Nombre (*Named Action*):** Conjunto reutilizable de acciones (por ejemplo: \`RECHAZAR_Y_ALERTAR\`) para estandarizar respuestas.

---

## 5. Integración con otros Productos Fortra / HelpSystems

* **Powertech SIEM Agent for IBM i:** Envía eventos de Command Security a soluciones SIEM corporativas (Event Manager, IBM QRadar, Splunk, Sentinel). Los eventos se pueden despachar cada vez que Command Security permite o rechaza un mandato.
* **Robot Alert:** Envía alertas vía correo o mensajería móvil ante ejecuciones críticas.
* **Robot Console / Halcyon:** Gestión automatizada de colas de mensajes.
* **Robot Schedule:** Programación automática de reportes de auditoría.

---

## 6. Apéndice A: Catálogo Completo de Acciones

| Acción | Descripción |
| :--- | :--- |
| **\`*ACTION\`** | Ejecuta un conjunto de acciones agrupadas en una Acción con Nombre (*Named Action*). |
| **\`*ADDKWD\`** | Agrega un parámetro al mandato. Parámetro en *Argument*, valor en *Value*. |
| **\`*ALLOW\`** | Permite la ejecución del mandato y detiene la evaluación de reglas posteriores. |
| **\`*CMDINLINE\`**| Ejecuta un mandato CL en línea dentro del mismo trabajo que invoca el comando monitoreado. |
| **\`*COMMAND\`**  | Ejecuta un mandato CL de forma remota y asíncrona a través del monitor \`PCSDAQMON\`. |
| **\`*EMAIL\`**    | Envía un correo electrónico mediante Robot Alert. |
| **\`*MSG\`**      | Envía un mensaje a una cola de mensajes (requiere \`PCSDAQMON\` en ejecución). |
| **\`*LOGMSG\`**   | Envía un mensaje de diagnóstico/informativo al registro del trabajo (*job log*). |
| **\`*QUEUEMSG\`** | Envía un mensaje específico desde un archivo de mensajes (\`*MSGF\`) a una cola. |
| **\`*REJECT\`**   | Bloquea la ejecución del mandato y detiene la evaluación de reglas. |
| **\`*RMVKWD\`**   | Remueve un parámetro específico de la cadena del mandato. |
| **\`*RPLALL\`**   | Reemplaza la cadena completa del mandato y todos sus parámetros por el contenido de *Value*. |
| **\`*RPLCMD\`**   | Reemplaza el nombre del comando y la biblioteca por lo especificado en *Value*. |
| **\`*RPLKWDVAL\`\`| Reemplaza el valor de un parámetro existente por el nuevo valor en *Value*. |

---

## 7. Apéndice B: Fuentes de Datos (Data Sources) y Operadores

### Fuentes de Datos:
* \`*USER\`: Usuario actual del trabajo.
* \`*JOBUSER\`: Usuario con el que se inició la sesión del trabajo.
* \`*JOBTYPE\`: \`*INTER\` (interactivo) o \`*BATCH\` (en lote).
* \`*LOCATION\`: Dirección IP de la estación de trabajo cliente.
* \`*SPCAUT\`: Autoridades especiales del usuario actual.
* \`*STACK\`: Pila de llamadas (busca si un programa específico está en la pila).
* \`*TIME\` / \`*DATE\` / \`*DAYOFWEEK\`: Hora, fecha y día de la semana.
* \`*GRPPRF\`: Perfil de grupo y grupos suplementarios.
* \`<keyword>\`: Valor digitado por el usuario en un parámetro del mandato.

### Operadores:
* \`EQUALTO\` / \`NOT EQUALTO\`
* \`ONEOF\` (compara con una lista de valores separados por espacio)
* \`MEMBEROF\` (valida si el usuario pertenece a una Lista de Autorización)
* \`BETWEEN\` (rango de dos valores, inclusivo)
* \`CONTAINS\`, \`STARTSWITH\`, \`ENDSWITH\`
* \`SATISFIED\` (para validar Condiciones con Nombre)
* \`SPECIFIED\` (valida si el usuario introdujo un parámetro específico en el mandato)
`;

// 3. GUIA DEL USUARIO Y REFERENCIA COMPLETA
const guiaUsuario = `# Guía del Usuario y Referencia Completa - Powertech Command Security 1.16
**Versión del Producto:** 1.16  
**Fabricante:** Fortra / HelpSystems  
**Plataforma:** IBM i (OS/400)  
**Traducción Oficial al Español para Repositorio Cerebro Digital**

---

## 1. Menú Principal y Navegación (\`WRKPTCS\`)

El menú principal de Powertech Command Security (\`PCS3000\`) presenta las siguientes opciones:

* **1. Work with Monitored Commands (\`PCS3120\`):** Administra los mandatos monitoreados, sus reglas, condiciones y acciones.
* **2. Work with Named Conditions (\`PCS3130C\`):** Gestiona condiciones reutilizables.
* **3. Work with Named Actions (\`PCS3130A\`):** Gestiona bloques de acciones reutilizables.
* **4. Work with Global Rules (\`PCS3220\`):** Reglas globales que se evalúan **antes** que cualquier regla específica de mandato.
* **80. Reports Menu (\`PCS3001\`):** Menú de reportes e informes de auditoría.
* **81. License Setup (\`PCS9802\`):** Configuración de la clave de producto.

---

## 2. Reglas Globales vs Reglas Específicas
* **Reglas Globales (\`*ALL/*ALL\`):** Se evalúan en primer lugar para **todos** los mandatos monitoreados en el sistema.
  * *Ejemplo típico:* \`WHEN *USER EQUALTO(QSECOFR) DO *ALLOW\`. Permite acceso a administradores registrando siempre la acción en el diario.
* **Reglas Específicas:** Pertenecen a un mandato puntual (ej. \`QSQL/STRSQL\`). Se procesan en orden numérico ascendente (10, 20, 30...). La primera regla cuyas condiciones se cumplan ejecutará sus acciones.

---

## 3. Ejemplos de Implementación de Seguridad por Mandato

### A. Proteger Mandatos de Modificación de Sistema (CHGSYSVAL)
* Condición: \`*USER NOT MEMBEROF(AUTL_SYSVAL)\`
* Acción: \`*MSG\` a \`*SYSOPR\` y \`*REJECT\`.

### B. Proteger Mandatos de Modificación de Perfiles (CHGUSRPRF)
* Evita que usuarios no autorizados cambien contraseñas o autoridades especiales omitiendo políticas corporativas.

### C. Proteger Mandatos Peligrosos (PWRDWNSYS)
* Evita apagados accidentales sin reinicio forzando el parámetro \`RESTART(*YES)\`:
  * Regla 10: \`WHEN RESTART NOT SPECIFIED DO *ADDKWD RESTART(*YES)\`
  * Regla 20: \`WHEN RESTART EQUALTO(*NO) AND *USER NOT IN ADMINS DO *RPLKWDVAL RESTART(*YES)\`

### D. Mandatos Interactivos de Consulta y SQL (STRSQL / UPDDTA)
* Restricción por horario, estación de trabajo o listas de bibliotecas seguras (\`*ADDKWD LIBOPT(*USRLIBL)\`).

---

## 4. Limitaciones Técnicas del Sistema Operativo IBM i

De acuerdo con las restricciones de la arquitectura IBM i y el punto de salida \`QIBM_QCA_CHG_COMMAND\`:
1. **Mandatos calificados con biblioteca:** Si un usuario ejecuta explícitamente un mandato especificando la biblioteca (por ejemplo \`QSYS/ADDLIBLE\`), el sistema operativo no permite que un programa de salida altere los parámetros.
2. **Mandatos con \`RTNVAL(*YES)\`:** Mandatos que devuelven valores a programas CL llamadores no permiten alteración de cadena.
3. **Mandatos de compilación CL interna:** Mandatos como \`CALLPRC\`, \`DO\`, \`GOTO\`, \`IF\`, \`DCL\`.
4. **Mandato \`CALL\`:** IBM i no permite interceptar \`CALL\` a través de \`QIBM_QCA_CHG_COMMAND\`.
5. **Mandatos Proxy:** Mandatos proxy que residen fuera de \`QSYS\`. Si se monitorea un mandato destino (target), todos los proxys en \`QSYS\` que apunten a él serán monitoreados automáticamente.

---

## 5. Diagnóstico y Depuración en Tiempo Real (\`PCSSTRDBG\`)

Command Security incluye una función nativa de rastreo para analizar exactamente cómo se evalúan las reglas ante una ejecución real:

1. **Activar depuración en la sesión actual:**
   \`\`\`cl
   PTCSLIB/PCSSTRDBG
   \`\`\`
   *(O presionar F4 para especificar el trabajo interactivo de otro usuario).*
2. **Ejecutar el comando bajo prueba:** (Por ejemplo, \`STRSQL\`).
3. **Ver el resultado en el Job Log:**
   \`\`\`cl
   DSPJOB OPTION(*JOBLOG)
   \`\`\`
   *(Presionar F10 para desplegar mensajes detallados).*
   Verá líneas como:
   \`\`\`text
   << Command QSQL/STRSQL Point=QIBM_QCA_CHG_COMMAND ...
   << Added MI log entry
   << Condition : *CONDITION SATISFIED ... Result : TRUE
   << Action executed : *ALLOW
   \`\`\`
4. **Desactivar depuración:**
   \`\`\`cl
   PTCSLIB/PCSENDDBG
   \`\`\`

---

## 6. Diarios de Auditoría y Mantenimiento (\`PCSLOG\` y \`PCSDCL\`)

Command Security utiliza dos diarios nativos en la biblioteca \`PTCSLIB\`:

| Diario | Biblioteca | Receptores | Propósito |
| :--- | :--- | :--- | :--- |
| **\`PCSLOG\`** | \`PTCSLIB\` | \`PCSLOnnnn\` | Registra todas las intercepciones de mandatos (Entradas \`MI\`=Inicio, \`ME\`=Ejecución, \`MA\`=Acción). Es la fuente para reportes y para el SIEM Agent (\`*CMDSEC\`). |
| **\`PCSDCL\`** | \`PTCSLIB\` | \`PCSDCnnnn\` | Registro administrativo de cambios en la configuración del producto (creación/borrado de reglas). |

### Reportes del Diario:
* **\`PCSJRNRPT\`:** Imprime la actividad de mandatos monitoreados desde \`PCSLOG\` (permite filtrar por fecha, hora, usuario, trabajo y mandato).
* **\`PCSDCLRPT\`:** Imprime cambios en las reglas desde \`PCSDCL\`.
* **\`PCSPRTCMDS\`:** Imprime la lista completa de mandatos monitoreados y sus reglas.

---

## 7. Comandos CL del Producto

* \`PCSNEWCMD\`: Agrega un nuevo mandato a monitorear.
* \`PCSCPYCMD\`: Copia reglas de un mandato a otro.
* \`PCSDLTCMD\`: Elimina un mandato monitoreado.
* \`PCSMONSTS\`: Habilita o deshabilita los monitores (\`*ALL\`, \`*ACTION\`, \`*COMMAND\`).
* \`PCSLOGMSG\`: Envía un mensaje explicativo al joblog del usuario cuando un mandato es rechazado.
* \`PCSSTRMON\` / \`PCSENDMON\`: Inicia o finaliza el monitor de acciones diferidas (\`PCSDAQMON\`).

---

## 8. Integración con SIEM Agent y Event Manager

Para enviar eventos a consolas SIEM:
1. En **SIEM Agent (\`WRKPTSA\`)**, la fuente de eventos **\`*CMDSEC\`** debe estar activa.
2. Los tipos de eventos de inicio (\`UMI\`), ejecución (\`UME\`) y acción (\`UMA\`) deben estar habilitados con valor \`1\`.
3. Debe ejecutarse el **Commit** de configuración en SIEM Agent.
4. El monitor de fondo **\`PSAMGRMON USR-CMDSEC\`** en el subsistema \`PTWRKMGT\` lee en tiempo real el diario \`PTCSLIB/PCSLOG\` y despacha los eventos en formato Syslog hacia el servidor SIEM / Event Manager.
`;

fs.writeFileSync(path.join(targetDir, 'Guia_Instalacion_Command_Security_ES.md'), guiaInstalacion, 'utf8');
console.log('1. Guia de Instalacion creada en D:\\Cerebro Digital');

fs.writeFileSync(path.join(targetDir, 'Guia_Implementacion_y_Mejores_Practicas_Command_Security_ES.md'), guiaImplementacion, 'utf8');
console.log('2. Guia de Implementacion creada en D:\\Cerebro Digital');

fs.writeFileSync(path.join(targetDir, 'Guia_del_Usuario_Command_Security_ES.md'), guiaUsuario, 'utf8');
console.log('3. Guia del Usuario creada en D:\\Cerebro Digital');
