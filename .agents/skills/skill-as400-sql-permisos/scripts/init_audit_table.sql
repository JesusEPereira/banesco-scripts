-- =============================================================================
-- init_audit_table.sql
-- DDL para la Creación de la Tabla de Auditoría de Integración AS400 en Antigravity
-- Compatible con: DB2 for i (IBM i V7.5) y Microsoft SQL Server
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Opción 1: DDL para DB2 for i (IBM i V7.5)
-- -----------------------------------------------------------------------------
-- Crear Biblioteca de Auditoría (si no existe):
-- CALL QSYS2.QCMDEXC('CRTLIB LIB(ANTIGRAVAUD) TEXT(''Biblioteca Auditoría Antigravity'')')

CREATE TABLE ANTIGRAVAUD.AS400_AUDIT_LOG (
    AUDITORIA_ID         VARCHAR(64)   NOT NULL PRIMARY KEY,
    FECHA_HORA           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    HOST_AS400           VARCHAR(128)  NOT NULL,
    USUARIO_SOLICITANTE  VARCHAR(64)   NOT NULL,
    USUARIO_APROBADOR    VARCHAR(64),
    TIPO_OPERACION       VARCHAR(32)   NOT NULL, -- 'SELECT', 'DML', 'CL_PERMISOS'
    COMANDO_ENVIADO      VARCHAR(4000) NOT NULL,
    ESTADO_TRANSACCION   VARCHAR(32)   NOT NULL, -- 'EXITOSO', 'RECHAZADO_POR_USUARIO', 'ERROR_EJECUCION'
    FILAS_AFECTADAS      INTEGER       DEFAULT 0,
    SQLSTATE_CODIGO      VARCHAR(10),
    CPF_CODIGO           VARCHAR(10),
    DETALLE_RESPUESTA    VARCHAR(4000)
);

LABEL ON TABLE ANTIGRAVAUD.AS400_AUDIT_LOG IS 'Bitácora de Auditoría Antigravity - IBM i SQL & Permisos';
LABEL ON COLUMN ANTIGRAVAUD.AS400_AUDIT_LOG (
    AUDITORIA_ID IS 'ID Único Transacción',
    FECHA_HORA IS 'Timestamp Ejecución',
    HOST_AS400 IS 'IP/Host AS400 Destino',
    USUARIO_SOLICITANTE IS 'Usuario Solicitante',
    USUARIO_APROBADOR IS 'Usuario Aprobador HITL',
    TIPO_OPERACION IS 'Tipo Operación SQL/CL',
    COMANDO_ENVIADO IS 'Sentencia o Comando CL',
    ESTADO_TRANSACCION IS 'Estado Final Operación',
    FILAS_AFECTADAS IS 'Recuento Filas Afectadas',
    SQLSTATE_CODIGO IS 'Código SQLSTATE DB2',
    CPF_CODIGO IS 'Código Error CPF Native',
    DETALLE_RESPUESTA IS 'Payload o Error JSON'
);

CREATE INDEX ANTIGRAVAUD.IDX_AUDIT_FECHA ON ANTIGRAVAUD.AS400_AUDIT_LOG (FECHA_HORA DESC);
CREATE INDEX ANTIGRAVAUD.IDX_AUDIT_SOLICITANTE ON ANTIGRAVAUD.AS400_AUDIT_LOG (USUARIO_SOLICITANTE);


-- -----------------------------------------------------------------------------
-- Opción 2: DDL para Microsoft SQL Server (Base de Datos Local / Centralizada)
-- -----------------------------------------------------------------------------
/*
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AS400_AUDIT_LOG')
BEGIN
    CREATE TABLE AS400_AUDIT_LOG (
        AUDITORIA_ID         NVARCHAR(64)   NOT NULL PRIMARY KEY,
        FECHA_HORA           DATETIME2(3)   NOT NULL DEFAULT GETDATE(),
        HOST_AS400           NVARCHAR(128)  NOT NULL,
        USUARIO_SOLICITANTE  NVARCHAR(64)   NOT NULL,
        USUARIO_APROBADOR    NVARCHAR(64)   NULL,
        TIPO_OPERACION       NVARCHAR(32)   NOT NULL,
        COMANDO_ENVIADO      NVARCHAR(MAX)  NOT NULL,
        ESTADO_TRANSACCION   NVARCHAR(32)   NOT NULL,
        FILAS_AFECTADAS      INT            NOT NULL DEFAULT 0,
        SQLSTATE_CODIGO      NVARCHAR(10)   NULL,
        CPF_CODIGO           NVARCHAR(10)   NULL,
        DETALLE_RESPUESTA    NVARCHAR(MAX)  NULL
    );

    CREATE NONCLUSTERED INDEX IX_AS400_AUDIT_LOG_FECHA ON AS400_AUDIT_LOG (FECHA_HORA DESC);
    CREATE NONCLUSTERED INDEX IX_AS400_AUDIT_LOG_SOLICITANTE ON AS400_AUDIT_LOG (USUARIO_SOLICITANTE);
END
*/
