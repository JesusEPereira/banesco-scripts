---
name: skill-as400-sql-permisos
description: >-
  Skill para la integración programática con IBM i / AS400 (v7.5) para procesamiento de consultas SQL DB2 (SELECT, DML),
  ejecución de comandos CL nativos y gestión de permisología mediante QSYS2.QCMDEXC (GRANT, REVOKE, CHGOBJAUT, GRTOBJAUT).
  Requiere aprobación humana previa (Human-in-the-Loop) antes de ejecutar cualquier cambio y registra auditoría completa.
---

# Skill: Integración IBM i / AS400 (V7.5) - SQL DB2 y Permisología (`skill-as400-sql-permisos`)

Este Skill automatiza la interacción programática con servidores IBM i / AS400 (DB2 for i v7.5) para ejecutar consultas SQL de extracción, sentencias de modificación de datos (DML) y administración de autorizaciones de objetos nativos del sistema operativo a través del procedimiento almacenado `QSYS2.QCMDEXC`.

---

## 1. Casos de Uso Soportados

1. **Procesamiento de Sentencias SQL (Consultas SELECT)**:
   - Extracción de datos de tablas, archivos físicos (PF) y lógicos (LF).
   - Formateo automático del resultado en estructuras JSON estándar o tablas.

2. **Ejecución DML (`INSERT`, `UPDATE`, `DELETE`)**:
   - Modificación controlada de registros en DB2 for i.
   - Retorno explícito del recuento de filas afectadas.

3. **Gestión de Permisología de Objetos (SQL & Sistema Operativo Native CL)**:
   - **Nivel SQL**: Sentencias estándar `GRANT` y `REVOKE`.
   - **Nivel OS Nativo (CL)**: Ejecución de comandos de control como `CHGOBJAUT`, `GRTOBJAUT`, `RVKOBJAUT` utilizando el procedimiento almacenado del sistema:
     ```sql
     CALL QSYS2.QCMDEXC('GRTOBJAUT OBJ(BIBLIOTECA/OBJETO) OBJTYPE(*FILE) USER(USUARIO) AUT(*CHANGE)')
     ```

---

## 2. Parámetros de Entrada (Inputs del Skill)

El skill acepta la siguiente estructura de parámetros:

| Parámetro | Tipo | Requerido | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- | :--- |
| `host` | String | Sí | Nombre de host o dirección IP del servidor AS400. | `"192.168.1.100"` o `"as400prod.banesco.com"` |
| `usuario` | String | Sí | Usuario directo de IBM i / AS400 (solicitado en cada operación). | `"USR_ANTIGRAV"` |
| `password` | String | Sí | Contraseña directa de IBM i / AS400 (solicitada en cada operación). | `"********"` |
| `tipo_operacion` | Enum | Sí | Tipo de acción: `SELECT`, `DML`, o `CL_PERMISOS`. | `"CL_PERMISOS"` |
| `comando_sql` | String | Sí | Sentencia SQL o comando CL a ejecutar. | `"CALL QSYS2.QCMDEXC('CHGOBJAUT OBJ(LIB/FILE1) OBJTYPE(*FILE) USER(USR1) AUT(*ALL)')"` |
| `solicitante` | String | Sí | Usuario o sistema que inicia la solicitud. | `"analista_seguridad"` |
| `aprobado_por` | String | Opcional | Identificador del usuario que aprobó la ejecución. | `"jefe_seguridad"` |
| `motivo` | String | Opcional | Justificación del cambio para auditoría. | `"Ticket #12345 - Ajuste permisología"` |

---

## 3. Flujo Obligatorio de Aprobación Humana (Human-in-the-Loop)

> [!IMPORTANT]
> **REGLA DE SEGURIDAD INDISPENSABLE:**
> Este skill **NO debe ejecutar ninguna sentencia DML o comando CL de forma autónoma sin confirmación explícita previa**.

### Protocolo de Aprobación

1. **Generación de Notificación de Solicitud**:
   Antes de llamar al conector AS400, el agente o script detiene la ejecución y solicita confirmación al usuario mostrando la siguiente ficha descriptiva:

   ```text
   ====================================================================
   ⚠️ SOLICITUD DE APROBACIÓN DE EJECUCIÓN EN AS400 (IBM i v7.5)
   ====================================================================
   Servidor Destino : 192.168.1.100 (AS400-PROD)
   Tipo de Acción   : CL_PERMISOS (Gestión de Autoridad de Objetos)
   Solicitante      : analista_seguridad
   Acción a Ejecutar: 
     CALL QSYS2.QCMDEXC('GRTOBJAUT OBJ(MI_BIBLIOTECA/TABLA_DATOS) OBJTYPE(*FILE) USER(OPERADOR1) AUT(*USE)')
   
   ¿Desea AUTORIZAR o RECHAZAR esta transacción? [Aprobar / Rechazar]
   ====================================================================
   ```

2. **Evaluación de la Respuesta**:
   - **Si el usuario selecciona "Aprobar"**:
     - Se registra el evento de aprobación en el rastro de auditoría.
     - Se procede a la ejecución de la consulta/comando contra el AS400.
   - **Si el usuario selecciona "Rechazar"**:
     - Se aborta la ejecución inmediatamente.
     - Se inserta un registro de auditoría con estado `"RECHAZADO_POR_USUARIO"`.
     - El skill retorna un error controlado (Status `403 Forbidden / Operation Cancelled`).

---

## 4. Trazabilidad y Registro de Auditoría (Logs)

Toda transacción enviada a través de este Skill debe registrar auditoría en dos niveles:

1. **Log Interno de Antigravity**:
   Ficheros de log y consola registran timestamp, solicitante, aprobador, host, hash de comando y código de retorno DB2.

2. **Tabla de Auditoría `AS400_AUDIT_LOG`**:
   Antes de ejecutar la acción (o inmediatamente tras su dictamen), se ejecuta una inserción en la tabla de auditoría:
   Ver el script DDL [init_audit_table.sql](./scripts/init_audit_table.sql) para la estructura de la tabla.

---

## 5. Salidas Esperadas (Outputs del Skill)

### Respuesta Exitosa (Status 200 / OK)

**Para Consultas SELECT:**
```json
{
  "status": 200,
  "mensaje": "Consulta ejecutada exitosamente",
  "tipo_operacion": "SELECT",
  "filas_retornadas": 2,
  "data": [
    { "LIBNAME": "PRODLIB", "OBJNAME": "CUSTOMERPF", "OBJTYPE": "*FILE", "OBJAUT": "*CHANGE" },
    { "LIBNAME": "PRODLIB", "OBJNAME": "ACCOUNTSPF", "OBJTYPE": "*FILE", "OBJAUT": "*ALL" }
  ],
  "auditoria_id": "AUD-20260911-0001"
}
```

**Para Operaciones DML / Comandos CL:**
```json
{
  "status": 200,
  "mensaje": "Comando CL / Operación DML ejecutada exitosamente",
  "tipo_operacion": "CL_PERMISOS",
  "filas_afectadas": 1,
  "detalle_ejecucion": "Comando QSYS2.QCMDEXC completado sin errores.",
  "auditoria_id": "AUD-20260911-0002"
}
```

### Respuesta de Error (Status 500 / DB2 Exception)

```json
{
  "status": 500,
  "mensaje": "Error durante la ejecución en IBM i DB2",
  "sqlstate": "42704",
  "sqlcode": -204,
  "cpf_code": "CPF9801",
  "error_detalle": "[IBM][CLI Driver][DB2/400 SQL] SQL0204N El objeto MI_BIBLIOTECA/OBJETO_INEXISTENTE tipo *FILE no existe.",
  "auditoria_id": "AUD-20260911-0003"
}
```

---

## 6. Scripts y Enlaces de Referencia

- **Script Ejecutor Principal (Python)**: [as400_executor.py](./scripts/as400_executor.py)
- **Script Ejecutor Alternativo (PowerShell)**: [as400_executor.ps1](./scripts/as400_executor.ps1)
- **Script de Creación de Tabla de Auditoría**: [init_audit_table.sql](./scripts/init_audit_table.sql)
- **Guía Técnica JT400 y QSYS2.QCMDEXC**: [jt400_jdbc_qcmdexc_guide.md](./references/jt400_jdbc_qcmdexc_guide.md)
- **Arquitectura de Aprobación y PAM**: [approval_and_audit_architecture.md](./references/approval_and_audit_architecture.md)

---

## 7. Instrucciones de Uso para el Agente

Cuando se requiera interactuar con AS400 (IBM i v7.5) para ejecutar SQL o cambiar permisos:
1. Verificar si la operación es de modificación (`DML` o `CL_PERMISOS`).
2. Si modifica el sistema, **solicitar aprobación al usuario** mostrando el servidor y el comando exacto.
3. Al recibir confirmación ("Aprobar"), ejecutar [as400_executor.py](./scripts/as400_executor.py) pasando los parámetros requeridos.
4. Entregar el resultado en formato JSON estructurado al usuario.
