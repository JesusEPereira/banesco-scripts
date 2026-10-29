---
name: skill-matriz-roles-perfiles
description: >-
  Validar, auditar, versionar y depurar Matrices de Roles y Perfiles (Excel .xlsx/.xlsm) en rutas compartidas de red UNC de Banesco contra la base de datos Oracle de Capital Humano (tabla actived) y Active Directory.
  USE CUANDO el usuario mencione 'matriz', 'roles y perfiles', 'depuracion de matriz', 'usuarios inactivos', 'actived', 'actived_ret', 'cruce de cedula', 'ICS.xlsm', 'remediar matriz', 'versionamiento historico', 'resaltar en rojo' o 'auditar matriz en red'.
  NO USE PARA consultas DB2 en IBM i / AS400 (use skill-tlmst-as400 o skill-as400-sql-permisos), ni para gestion de privilegios CyberArk PAM (use skill-seguridad-pam), ni para auditoria del repositorio maestro D:\Cerebro Digital (use skill-auditoria-cerebro).
---

# Skill: Validacion y Depuracion de Matrices de Roles y Perfiles (`skill-matriz-roles-perfiles`)

Este Skill provee la arquitectura tecnica, procedimientos de seguridad, scripts de automatizacion y gestion de ciclo de vida para la auditoria de **Matrices de Roles y Perfiles** en formato Excel (`.xlsx`, `.xlsm`) alojadas en carpetas compartidas de red UNC corporativas de Banesco, validando la vigencia de los colaboradores contra la base de datos **Oracle de Capital Humano (RRHH)** y las OUs oficiales de **Active Directory**.

---

## Paso 0 Mandatorio: Anclaje Epistémico (One-Hop al Manifiesto SSOT)

De acuerdo a la Capa 1 y Capa 3 del Manual de Ingenieria Agentica, este skill **NUNCA** quema parametros de infraestructura ni navega rutas secundarias. Los scripts y el agente cargan la configuracion declarativa directamente:

```powershell
# Carga One-Hop del Manifiesto SSOT Banesco (Capa 1)
$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\manifests\banesco-infrastructure.psd1'
if (-not (Test-Path $ManifestPath)) {
    $ManifestPath = 'D:\WKESPEREIRA\D\Scripts\.agents\manifests\banesco-infrastructure.psd1'
}
$Infra = Import-PowerShellDataFile -Path $ManifestPath

# Parametros desacoplados y vinculados al SSOT:
$OracleHost      = $Infra.OracleRRHH.Host
$OracleSid       = $Infra.OracleRRHH.Sid
$TargetOU        = $Infra.ActiveDirectory.TargetOU
$SvcAccountOU    = $Infra.ActiveDirectory.ServiceAccountOU
$UncMatricesPath = $Infra.MatricesUNC.DefaultPath
```

---

## 1. Parametros Centralizados de Infraestructura (Capa 1)

* **Oracle Capital Humano**: `Host: $Infra.OracleRRHH.Host` | `Puerto: 1521` | `SID: $Infra.OracleRRHH.Sid` | `Tablas: actived, actived_ret`
* **Active Directory**: `Dominio: intra.banesco.com` | `OU Usuarios: OU=Usuarios,DC=intra,DC=banesco,DC=com` | `OU Servicios: OU=Cuentas de Servicios,DC=intra,DC=banesco,DC=com`
* **Ruta de Red UNC**: `\\intra.banesco.com\datos\Central\Gerencias\Vp Ejec Prev Perdidas y Cont Neg\Vp Cont del Negocio\Gcia Div Gestion y Control\VP PREVENCION\AdminSegTI\Prueba2026`

---

## 2. Flujo Operativo y Ciclo de Validacion

El proceso se divide estrictamente en 4 etapas deterministas:

```text
[1. EXTRACCION Y NORMALIZACION]
   - Acceso no bloqueante a la matriz en red (FileShare.ReadWrite).
   - Extraccion de identidades y cedulas de la hoja 'Usuarios'.
   - Normalizacion de cedula (limpieza de 'V-', 'E-', espacios, ceros a la izquierda).
         |
         v
[2. CRUCE CONTRA ORACLE (actived / actived_ret)]
   - Consulta en lote o filtrada a la tabla actived de RRHH.
   - Deteccion de cedulas inexistentes (egresados / dados de baja).
   - Validacion de cuenta y pertenencia a OU en Active Directory.
         |
         v
[3. REPORTE DE INCONSISTENCIAS Y VERSIONAMIENTO INMUTABLE]
   - Emision de reporte estructurado: Reporte_Inconsistencias_[Matriz]_[Fecha].xlsx / .csv
   - Creacion de version de respaldo con resaltado en rojo suave: [Matriz]_vYYYYMMDD_HHMMSS.xlsm
         |
         v
[4. REMEDIACION CONTROLADA (Human-in-the-Loop)]
   - Protocolo HITL: Se presenta la propuesta al analista de seguridad.
   - Requiere confirmacion explicita antes de eliminar filas no conformes en la matriz principal.
   - Asentamiento de bitacora inmutable en logs/matriz_audit.jsonl.
```

---

## 3. Scripts y Herramientas del Skill

| Script / Archivo | Funcion |
| :--- | :--- |
| `scripts/config.json` | Parametros sincronizados de host Oracle, SID, rutas UNC y nombres de tablas. |
| `scripts/test_oracle_connection.ps1` | Verifica conectividad TCP al puerto 1521 y credenciales hacia la BD `rrhh`. |
| `scripts/sync_matriz_roles.ps1` | Orquestador principal de lectura no bloqueante de matrices, cruce, reporte y versionamiento. |
| `scripts/remediate_matriz.ps1` | Aplica la eliminacion efectiva de filas tras confirmacion humana explicita. |
| `references/oracle_schema_actived.md` | Diccionario de datos de las tablas `actived` y `actived_ret`. |
| `references/procedimiento_versionamiento.md` | Estandar de nomenclatura y retencion de versiones previas. |

---

## 4. Modos de Ejecucion

### [MODO ESTANDAR] Versionamiento en Rojo + Depuracion en Matriz Principal
Genera la version con usuarios resaltados en rojo en `_Versiones_Historicas` (evidencia de auditoria) y **elimina efectivamente las filas no conformes en la matriz principal**:
```powershell
powershell -ExecutionPolicy Bypass -File "D:\WKESPEREIRA\D\Scripts\.agents\skills\skill-matriz-roles-perfiles\scripts\sync_matriz_roles.ps1"
```

### [MODO AUDITORIA] Simulacion / Solo Reporte (-DryRun)
Genera la version historica con resaltado en rojo en `_Versiones_Historicas` y emite los reportes de auditoria, **sin alterar la matriz principal**:
```powershell
powershell -ExecutionPolicy Bypass -File "D:\WKESPEREIRA\D\Scripts\.agents\skills\skill-matriz-roles-perfiles\scripts\sync_matriz_roles.ps1" -DryRun
```

### [MODO ESPECIFICO] Depuracion de una Matriz Unica
```powershell
powershell -ExecutionPolicy Bypass -File "D:\WKESPEREIRA\D\Scripts\.agents\skills\skill-matriz-roles-perfiles\scripts\sync_matriz_roles.ps1" -MatrixFileName "LA Agosto 2025.xlsm"
```

---

## 5. Reglas de Validacion de Cuentas y OUs en Active Directory

1. **Usuarios Regulares**:
   - Deben pertenecer a la Unidad Organizativa oficial: `OU=Usuarios,DC=intra,DC=banesco,DC=com`.
   - Cuentas ubicadas en `OU=Temporal`, `OU=Bajas` o inexistentes en el dominio son marcadas como **No Conformes**.
2. **Cuentas de Servicio (`svc_*` / `SVC*`)**:
   - Toda cuenta cuyo identificador empiece por `svc_` o `SVC` debe pertenecer a: `OU=Cuentas de Servicios,DC=intra,DC=banesco,DC=com`.
   - Si una cuenta de servicio se encuentra fuera de esta OU, es marcada como **No Conforme**.
3. **Usuarios de Aplicacion (Exentos / Activos por Regla de Negocio)**:
   - Cuentas tecnicas internas de aplicativos que no corresponden a identidades humanas ni requieren login en dominio (ej: `Project Executor` y `Gawuser` en la matriz **GoAnywhere**).
   - Se validan como **CONFORME** (tipo `Usuario de Aplicacion`) y **NO** se resaltan en rojo.
4. **Resaltado y Versionamiento**:
   - Toda fila con inconsistencia o fuera de su OU correspondiente es resaltada en **ROJO suave** (`Interior.Color = 13551615`, `Font.Color = 393372`, `Font.Bold = $true`) en una nueva version dentro de `_Versiones_Historicas`.

---

## 6. Reglas de Seguridad y Buenas Practicas Corporativas

1. **Proteccion de Archivos en Red**: Los archivos de matriz nunca se abren con bloqueo exclusivo directo, evitando errores si un analista tiene el archivo abierto en Excel.
2. **Deteccion Dinamica de Columnas**: Mapea automaticamente nombres de columnas heterogeneas (`employeeid`, `C.I.Nro`, `Cedula`, `Intra`, `Usuario`, o resolucion via Active Directory).
3. **Versionamiento Inmutable**: Antes de escribir un solo cambio en el archivo de matriz, se genera un archivo clon `[Matriz]_vYYYYMMDD_HHMMSS.[ext]` en la subcarpeta `_Versiones_Historicas`.
4. **Auditoria Estricta**: Cada usuario o cuenta analizada queda documentada con fecha, hora, responsable, cuenta, cedula, OU objetivo y motivo de diagnostico en `logs/matriz_audit.jsonl`.
