# Guía Técnica: Conexión JT400 JDBC y Procedimiento QSYS2.QCMDEXC en IBM i (V7.5)

Esta guía detalla los requisitos de conectividad, configuración de drivers JDBC/ODBC, sintaxis del procedimiento de ejecución de comandos de sistema `QSYS2.QCMDEXC`, puertos de red y mapeo de errores para el Skill `skill-as400-sql-permisos`.

---

## 1. Conexión mediante JT400.jar (JTOpen)

El driver oficial de IBM para conexiones Java / JDBC hacia IBM i / AS400 es **JT400 (JTOpen)**.

- **Nombre de Clase del Driver**: `com.ibm.as400.access.AS400JDBCDriver`
- **Cadena de Conexión Estándar (JDBC)**:
  ```text
  jdbc:as400://<HOST_IP>;naming=sql;errors=full;prompt=false;libraries=*LIBL,QSYS2;
  ```
- **Cadena de Conexión TLS / SSL**:
  ```text
  jdbc:as400://<HOST_IP>;secure=true;ssl=basic;naming=sql;errors=full;prompt=false;
  ```

---

## 2. Requisitos de Puertos en Firewall

Para garantizar la conectividad bidireccional entre la plataforma Antigravity / Servidor ejecutor y el IBM i v7.5, se deben habilitar los siguientes puertos en la red/Firewall:

| Puerto TCP | Servicio IBM i | Función / Descripción |
| :--- | :--- | :--- |
| **449** | Host Server Mapper | Mapeador inicial de servicios IBM i Host Servers. |
| **8471** | Database Server | Conexión JDBC/ODBC DB2 for i estándar (no encriptado). |
| **9471** | SSL Database Server | Conexión JDBC/ODBC DB2 for i encriptada con TLS/SSL. |
| **446** | DRDA / DDM | Conexiones distribuidas de base de datos DRDA. |
| **8476** | Signon / Central Server | Autenticación central de usuarios y resolución de credenciales. |
| **8473** | Network Print Server | (Opcional) Gestión de spools de impresión. |

---

## 3. Procedimiento Almacenado `QSYS2.QCMDEXC`

IBM i v7.5 incluye en la biblioteca `QSYS2` el procedimiento almacenado `QCMDEXC`, el cual permite ejecutar cualquier comando de Control Language (CL) del sistema operativo nativo directamente desde una sesión SQL JDBC/ODBC.

### Sintaxis del Procedimiento

```sql
CALL QSYS2.QCMDEXC('COMANDO_CL_AQUI', LONGITUD_DEL_COMANDO)
```

### Ejemplos de Permisología de Objetos vía `QCMDEXC`

1. **Conceder Autoridad a un Archivo Físico/Tabla (`GRTOBJAUT`)**:
   ```sql
   CALL QSYS2.QCMDEXC('GRTOBJAUT OBJ(BIBLIOTECA/TABLA1) OBJTYPE(*FILE) USER(USR_CONSULTA) AUT(*USE)', 80)
   ```

2. **Cambiar Autoridad Directa de un Objeto (`CHGOBJAUT`)**:
   ```sql
   CALL QSYS2.QCMDEXC('CHGOBJAUT OBJ(BIBLIOTECA/PROGRAMA1) OBJTYPE(*PGM) USER(OPERADOR) AUT(*ALL)', 80)
   ```

3. **Revocar Autoridad (`RVKOBJAUT`)**:
   ```sql
   CALL QSYS2.QCMDEXC('RVKOBJAUT OBJ(BIBLIOTECA/TABLA1) OBJTYPE(*FILE) USER(USR_DESEUSADO) AUT(*ALL)', 81)
   ```

> [!NOTE]
> En la implementación del skill ([as400_executor.py](../scripts/as400_executor.py) / [as400_executor.ps1](../scripts/as400_executor.ps1)), la longitud en caracteres se calcula dinámicamente y las comillas simples internas se escapan automáticamente multiplicándolas (`''`).

---

## 4. Mapeo de Errores DB2 / Códigos CPF de IBM i

Cuando una instrucción o comando falla en IBM i, DB2 retorna un código `SQLSTATE` y el sistema operativo puede emitir un código de excepción `CPF`.

| Código Error | Origen | Descripción | Causa Probable | Solución |
| :--- | :--- | :--- | :--- | :--- |
| **CPF2207** | IBM i OS | No autorizado a objeto o biblioteca. | El usuario no posee perfil con autoridad suficiente sobre el objeto. | Verificar perfil de usuario o conceder autoridad previa con `GRTOBJAUT`. |
| **CPF9801** | IBM i OS | Objeto no encontrado. | La biblioteca o el objeto no existe en el AS400. | Verificar ortografía y la lista de bibliotecas (`*LIBL`). |
| **CPF2202** | IBM i OS | Parámetro no válido en comando CL. | Sintaxis errónea en el comando enviado a `QCMDEXC`. | Revisar los parámetros del comando CL nativo. |
| **SQL0204N** | DB2 | Nombre no definido (Objeto no existe). | Tabla, vista o procedimiento no encontrado en el esquema. | Validar esquema/biblioteca en la consulta. |
| **SQL0551N** | DB2 | No tiene autorización para realizar la operación. | Privilegios insumos a nivel de base de datos SQL (`SELECT`/`UPDATE`). | Ejecutar `GRANT` correspondiente a nivel SQL. |
| **SQLSTATE 42704** | DB2 | Objeto no encontrado. | Objeto no existe. | Revisar nombres de física/lógica. |
