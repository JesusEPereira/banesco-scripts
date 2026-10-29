# Gestión de Reglas de Seguridad, Intercepción y Estrategia Deny-by-Default

**Producto:** Powertech Command Security for IBM i (Fortra)  
**Ubicación en Cerebro Digital:** `D:\Cerebro Digital\05_AS400_IBM_i\06_Fortra_Auditoria`

---

## 1. Arquitectura de Intercepción de Comandos vs Puntos de Salida

En la suite de seguridad Fortra para IBM i existe una distinción clara entre dos productos complementarios:

| Característica | Powertech Command Security | Powertech Network Security / Exit Point Manager |
| :--- | :--- | :--- |
| **Enfoque Principal** | Intercepción de comandos nativos de IBM i (`CL`, `QSH`, `PASE`, `Batch`). | Intercepción de accesos por red/sockets (`FTP`, `ODBC`, `JDBC`, `DDM`, `Telnet`). |
| **Punto de Control** | Analiza el nombre del comando y sus parámetros específicos antes de ejecutar. | Analiza el usuario, dirección IP de origen y función de red invocada. |
| **Nivel de Detalle** | Permite bloquear o modificar parámetros específicos de un comando. | Permite autorizar o denegar el acceso global al servicio de red. |

---

## 2. Motor de Reglas y Evaluación de Condiciones

**Powertech Command Security** evalúa las ejecuciones de comandos mediante un motor de reglas en tiempo real. Cada regla consta de **Condiciones** y **Acciones**.

### 2.1 Criterios de Evaluación (Condiciones)
* **Perfil de Usuario / Grupo**: Identifica si el comando es ejecutado por un usuario interactivo, un perfil de servicio o un miembro de un grupo.
* **Nombre de Comando y Biblioteca**: Aplica sobre comandos individuales (ej. `DLTLIB`, `PWRDWNSYS`, `STRSQL`) o patrones.
* **Valores de Parámetros**: Permite inspeccionar parámetros críticos (ej. `DLTLIB LIB(QGPL)` o `CHGUSRPRF USRPRF(QSECOFR) STATUS(*DISABLED)`).
* **Entorno de Ejecución**: Distingue si la ejecución es desde línea de comandos interactiva (`*INTERACT`), envío de trabajos por lote (`*BATCH`), o programas de salida de red.
* **Ventana Horaria / Día**: Aplica restricciones en horarios fuera de jornada laboral o mantenimiento.

---

### 2.2 Acciones Disponibles ante Coincidencia de Regla

1. **`*ALLOW` (Permitir)**: Autoriza la ejecución del comando normalmente.
2. **`*BLOCK` (Bloquear)**: Impide la ejecución del comando y retorna una excepción de seguridad al usuario/trabajo.
3. **`*LOG` (Auditar)**: Registra la ejecución en el diario de seguridad sin interrumpir la operación.
4. **`*SUBSTITUTE` (Sustituir Parámetros)**: Modifica dinámicamente los parámetros del comando antes de su ejecución real (ej. forzar `OUTPUT(*PRINT)` o reorientar una biblioteca).
5. **`*NOTIFY` (Notificar)**: Envía una alerta automática a los administradores de seguridad (vía mensaje de cola `MSGQ` o correo Syslog/SIEM).

---

## 3. Implementación del Modelo *Deny-by-Default* (Zero Trust)

Para garantizar el cumplimiento de normativas financieras como **PCI DSS**, **ISO 27001** y regulaciones bancarias:

1. **Regla Base Restrictiva**:
   Configurar una regla por defecto que deniegue (`*BLOCK`) o requiera autorización explícita para la ejecución de comandos de alteración de seguridad (`CHGUSRPRF`, `CHGJOB`, `DLTF`, `CLRPRTDTA`) por parte de usuarios no privilegiados.

2. **Excepciones Controladas**:
   Crear reglas específicas de excepción autorizando únicamente a los perfiles de producción requeridos durante las ventanas de tiempo operativas.

3. **Auditoría Continua**:
   Activar el registro `*LOG` en todas las ejecuciones de comandos de nivel de administrador (`*SECADM`, `*ALLOBJ`) para trazabilidad completa de cambios.
