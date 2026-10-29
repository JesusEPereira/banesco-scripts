# Diccionario de Datos: Tablas Oracle de Capital Humano (`actived`)

Esta documentación técnica detalla el modelo de datos de la base de datos de Capital Humano (RRHH / Fusion Banesco), utilizada para la validación de colaboradores vigentes.

---

## 1. Conexión a la Base de Datos

- **Servidor Oracle**: `sdb8023.intra.banesco.com`
- **Puerto**: `1521`
- **SID**: `rrhh`
- **Nombre de Servicio / FQDN**: `fucsion.intra.banesco.com`
- **Usuario del Esquema**: `actived`

---

## 2. Tabla Principal de Empleados Activos: `actived`

Contiene el universo de empleados actualmente activos y en nómina de la corporación.

| Campo | Tipo | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- |
| `CEDULA` | `VARCHAR2(20)` / `NUMBER` | Número de cédula o documento de identidad del empleado (clave de validación). | `13978898` |
| `NOMBRE` | `VARCHAR2(60)` | Nombres del empleado. | `DELIA CAROLINA` |
| `APELLIDO` | `VARCHAR2(60)` | Apellidos del empleado. | `RODRIGUEZ TORRES` |
| `CIA` | `VARCHAR2(5)` | Código de compañía / banco. | `01` |
| `EMPRESA` | `VARCHAR2(50)` | Razón social de la filial o entidad. | `BANESCO BANCO UNIVERSAL` |
| `SITUACION` | `VARCHAR2(10)` | Estatus de la relación laboral (`ACT` = Activo, `VAC` = Vacaciones, `REP` = Reposo). | `ACT` |
| `FECHA_SALIDA` | `DATE` | Fecha de inicio de período especial (vacaciones, permiso, suspensión). | `15-JAN-26` |
| `FECHA_REGRESO` | `DATE` | Fecha esperada de reincorporación laboral. | `30-JAN-26` |
| `COD_CARGO` | `VARCHAR2(20)` | Código único de cargo homologado en RRHH. | `20000476` |
| `CARGO` | `VARCHAR2(100)` | Denominación formal del puesto. | `Consultor II de Admin. de Seguridad` |
| `COD_UNI` | `VARCHAR2(20)` | Código de unidad organizativa a la que pertenece. | `10000835` |
| `CODAREA` | `VARCHAR2(10)` | Código de área funcional. | `04` |

---

## 3. Tabla de Egresados y Retirados: `actived_ret`

Almacena los colaboradores desvinculados o que han cesado su relación laboral con Banesco.

| Campo | Tipo | Descripción | Ejemplo |
| :--- | :--- | :--- | :--- |
| `CEDULA` | `VARCHAR2(20)` / `NUMBER` | Número de cédula del colaborador retirado. | `15789184` |
| `FEGRESO` | `DATE` | Fecha oficial en que se formalizó el egreso de la institución. | `04-JAN-22` |
| `MOTIVO` | `VARCHAR2(50)` | Motivo de la desvinculación (renuncia, despido, jubilación). | `RENUNCIA VOLUNTARIA` |

---

## 4. Criterio de Inconsistencia para la Matriz de Roles

Un registro presente en la hoja `Usuarios` de una Matriz de Roles y Perfiles se clasifica como **INCONSISTENCIA** cuando:

1. **Egresado / No Encontrado**: Su `CEDULA` no existe en la tabla `actived`.
2. **Desvinculación Confirmada**: Su `CEDULA` aparece en la tabla `actived_ret` con `FEGRESO` registrado.
3. **Situación Inactiva**: Su campo `SITUACION` en `actived` presenta un estado de baja o suspensión definitiva.

En cualquiera de estos casos, el usuario **debe ser retirado de la matriz** para dar cumplimiento a los controles SOX y a las políticas de seguridad de la información corporativa.
