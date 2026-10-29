---
name: skill-as400-admin-dashboard
description: >-
  Administrar y operar el Portal Web corporativo para la gestion de identidades, perfiles QSYS2.USER_INFO, contrasenas (CHGUSRPRF) y autorizaciones (GRTOBJAUT) en IBM i / AS400.
  USE CUANDO el usuario mencione 'dashboard as400', 'portal as400', 'QSYS2.USER_INFO', 'CHGUSRPRF', 'GRTOBJAUT', '10.137.0.138', 'sesion as400 15 min', 'buscar perfil as400' o 'portal administracion seguridad as400'.
  NO USE PARA modificacion de campos en tabla TLMST (use skill-tlmst-as400), ni para reglas Deny-Default de Powertech (use skill-powertech-security), ni para auditoria de matrices en Excel (use skill-matriz-roles-perfiles).
---

# Skill: Portal de Administracion de Seguridad IBM i / AS400 (`skill-as400-admin-dashboard`)

Este Skill provee la arquitectura completa, servicios backend y la interfaz grafica SPA (Single Page Application) para la gestion segura de identidades, perfiles y autorizaciones sobre servidores **IBM i / AS400 (v7.5)**.

---

## Paso 0 Mandatorio: Anclaje Epistemico (One-Hop al Manifiesto SSOT)

De acuerdo a la Capa 1 y Capa 3 del Manual de Ingenieria Agentica, este skill consume los parametros de la LPAR y procedimientos desde el manifiesto central:

```powershell
$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\manifests\banesco-infrastructure.psd1'
if (-not (Test-Path $ManifestPath)) {
    $ManifestPath = 'D:\WKESPEREIRA\D\Scripts\.agents\manifests\banesco-infrastructure.psd1'
}
$Infra = Import-PowerShellDataFile -Path $ManifestPath

$As400Host       = $Infra.AS400.LparHost
$UserCatalog     = $Infra.AS400.UserCatalogTable
$CmdProcedure    = $Infra.AS400.CommandExecProcedure
$SessionTimeout  = $Infra.AS400.SessionTimeoutMin
```

---

## 1. Características Principales

### 🔐 1.1 Autenticación Corporativa LDAPS (636 TLS) y Sesión de Inactividad
- **Protocolo**: Conexión cifrada mediante **LDAPS sobre el puerto 636 con TLS 1.2/1.3** hacia Active Directory Banesco (`intra.banesco.com`).
- **Diseño del Login**: Interfaz idéntica a la identidad corporativa de Banesco:
  - Escudo verde esmeralda con checkmark y resplandor sutil.
  - Título institucional: **Banesco** / **ADMINISTRACIÓN DE SEGURIDAD**.
  - Campo de usuario con placeholder corporativo: `Ej. jespereira o usuario@intra.banesco.com`.
  - Campo de contraseña enmascarada con botón de alternar visibilidad.
- **Control de Inactividad (15 Minutos)**:
  - Temporizador visible en el header del portal (`⏱️ Expira en: 14:59`) que se restablece con cada interacción (mouse, teclado, scroll).
  - Si transcurren 15 minutos sin actividad, se destruye el token en memoria, se bloquea el portal y se despliega el banner contextual:
    > **⚠️ Su sesión ha expirado por inactividad (15 minutos). Por favor inicie sesión nuevamente.**

---

### 🔍 1.2 Buscador Maestro de Usuarios (`QSYS2.USER_INFO`)
Permite consultar en tiempo real el catálogo de usuarios del sistema en la LPAR `10.137.0.138` extrayendo exactamente los 7 campos requeridos:

| # | Campo DB2 (`QSYS2.USER_INFO`) | Etiqueta / Nombre Descriptivo | Descripción y Formato |
| :-: | :--- | :--- | :--- |
| **1** | `AUTHORIZATION_NAME` | **Authorization Name** | Nombre único del perfil de usuario (VARCHAR 10). |
| **2** | `PREVIOUS_SIGNON` | **Previous Signon** | Fecha y hora exacta del último inicio de sesión (TIMESTAMP). |
| **3** | `SIGN_ON_ATTEMPTS_NOT_VALID` | **Sign On Attempts Not Valid** | Conteo de intentos de autenticación fallidos (INTEGER). |
| **4** | `STATUS` | **Status** | Estado del perfil (`*ENABLED` en verde / `*DISABLED` en rojo). |
| **5** | `PASSWORD_CHANGE_DATE` | **Password Change Date** | Fecha del último cambio de contraseña (DATE). |
| **6** | `SPECIAL_AUTHORITIES` | **Special Authorities** | Permisos especiales asignados (`*ALLOBJ`, `*SECADM`, `*SAVSYS`, etc.). |
| **7** | `GROUP_PROFILE_NAME` | **Group Profile Name** | Nombre del perfil de grupo al que pertenece (o `*NONE`). |

**Capacidades del Buscador:**
- Soporte para búsqueda exacta o comodines (`BANASIA029`, `BAN1740%`, `OPER%`).
- Filtro rápido por estado (`*ALL`, `*ENABLED`, `*DISABLED`).
- Tarjetas métricas KPI en tiempo real (total usuarios, habilitados, deshabilitados, intentos fallidos).
- Botones de acción rápida en cada fila:
  - **🔑 Clave**: Abre el módulo de cambio de contraseña con el usuario ya pre-cargado.
  - **🛡️ Permisos**: Abre el módulo de autorizaciones con el usuario pre-cargado.

---

### 🔑 1.3 Módulo de Cambio de Contraseñas (`CHGUSRPRF`)
- Modificación controlada de credenciales en IBM i.
- Soporte para forzar expiración (`PWDEXP(*YES)` / `PWDEXP(*NO)`).
- Ocultamiento estricto de contraseñas: las claves nunca se graban en texto claro en logs de auditoría.
- Validación obligatoria Human-in-the-Loop (HITL) previa a la ejecución.
- Registro segregado en el archivo de auditoría independiente:
  `skill-as400-sql-permisos/logs/as400_password_audit.jsonl`

---

### 🛡️ 1.4 Módulo de Permisología de Objetos (`GRTOBJAUT` / `RVKOBJAUT`)
- Solicita obligatoriamente los parámetros esenciales de IBM i:
  - **Librería / Biblioteca** (ej. `SIIF0910`, `SEGDATLIB`, `BANCYFILES`).
  - **Objeto** (ej. `CUMAD`, `TLMST`, `TEMP1740C8`).
  - **Tipo de Objeto**: `*FILE`, `*PGM`, `*SRVPGM`, `*LIB`, `*DTAARA`, `*OUTQ`, `*JOBD`, `*CMD`, etc.
  - **Acción**: `GRANT` (`GRTOBJAUT`) o `REVOKE` (`RVKOBJAUT`).
  - **Nivel de Autoridad**: `*CHANGE`, `*USE`, `*ALL`, `*EXCLUDE`.
  - **Usuario Destino**: `*PUBLIC` o usuario específico.
  - **Dispositivo de ASP / IASP**: Opcional (ej. `IASP01`).
- Validación obligatoria HITL con ficha descriptiva.
- Registro segregado en el archivo de auditoría independiente:
  `skill-as400-sql-permisos/logs/as400_permissions_audit.jsonl`

---

## 2. Estructura de Archivos del Skill

```text
.agents/skills/skill-as400-admin-dashboard/
├── SKILL.md                                 # Documentación y manual del skill
├── references/
│   └── guia_despliegue_24_7_opcion1.md      # Guía de continuidad operativa 24/7 (Servicio Windows + IIS)
├── scripts/
│   ├── as400_dashboard_server.ps1          # Servidor HTTP nativo + API REST en PowerShell
│   ├── as400_ldap_auth.ps1                 # Módulo de validación LDAPS (636 TLS) Active Directory
│   ├── as400_get_user_info.ps1             # Conector ODBC para consultar QSYS2.USER_INFO
│   ├── as400_get_ad_hierarchy.ps1          # Consulta de jerarquía AD (aguevara + supervisados por cedulasupervisor)
│   └── install_service_dashboard.ps1       # Instalador y gestor del servicio Windows 24/7 (Opción 1)
└── web/
    ├── index.html                           # Estructura SPA (Login corporativo + Dashboard)
    ├── styles.css                           # Diseño Vanilla CSS moderno con tema oscuro
    └── app.js                              # Lógica SPA, temporizador 15 min, buscador y modales
```

---

## 3. Guía de Ejecución del Dashboard

### 3.1 Iniciar el Servidor Web Localmente
Abra una consola de PowerShell y ejecute:

```powershell
# Iniciar servidor en el puerto 8085 y abrir navegador
powershell.exe -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-as400-admin-dashboard\scripts\as400_dashboard_server.ps1" -Port 8085 -OpenBrowser
```

El portal estará disponible de inmediato en:
👉 `http://localhost:8085`

### 3.2 Credenciales para Pruebas / Desarrollo
- **Usuario Corporativo**: `jespereira` o `jespereira@intra.banesco.com`
- **Contraseña de Red**: Cualquier contraseña corporativa o clave de prueba (ej. `Banesco2026*`).
- **Modo Offline/Simulado**: El servidor detecta automáticamente si el controlador de dominio o el AS400 están disponibles y commuta sin interrupción a modo simulado con datos enriquecidos.

### 3.3 Despliegue de Continuidad Operativa 24/7 (Opción 1: Servicio Windows + IIS)
Para operar el servicio de manera ininterrumpida sin depender de una consola interactiva abierta:

```powershell
# Instalar el servicio de Windows 24/7 (Ejecutar como Administrador)
powershell.exe -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-as400-admin-dashboard\scripts\install_service_dashboard.ps1" -Action Install -Port 8085

# Verificar estado y sonda de salud
powershell.exe -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-as400-admin-dashboard\scripts\install_service_dashboard.ps1" -Action Status -Port 8085

# Generar plantilla web.config para IIS Reverse Proxy (HTTPS 443 -> 8085)
powershell.exe -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\skills\skill-as400-admin-dashboard\scripts\install_service_dashboard.ps1" -Action GenerateIISConfig -Port 8085
```

Para más detalles sobre la arquitectura de alta disponibilidad, consulte la guía completa en:
👉 [guia_despliegue_24_7_opcion1.md](./references/guia_despliegue_24_7_opcion1.md)

---

## 4. Endpoints de la API REST Interna

| Método | Endpoint | Descripción |
| :---: | :--- | :--- |
| `POST` | `/api/auth/login` | Valida credenciales contra LDAPS (636 TLS) de Active Directory. |
| `GET` | `/api/user-info?user=...&status=...` | Consulta la tabla `QSYS2.USER_INFO` en la LPAR `10.137.0.138`. |
| `POST` | `/api/change-password` | Ejecuta el cambio de contraseña vía `as400_change_password.ps1`. |
| `POST` | `/api/manage-permissions` | Modifica autorizaciones de objetos vía `as400_manage_permissions.ps1`. |
| `GET` | `/api/logs/passwords` | Retorna los últimos registros de `as400_password_audit.jsonl`. |
| `GET` | `/api/logs/permissions` | Retorna los últimos registros de `as400_permissions_audit.jsonl`. |

---

## 5. Auditoría y Trazabilidad Segregada

El portal garantiza que los eventos de seguridad no se mezclen:
1. **Cambios de Contraseña**: Registrados exclusivamente en `skill-as400-sql-permisos/logs/as400_password_audit.jsonl`.
2. **Permisología de Objetos**: Registrados exclusivamente en `skill-as400-sql-permisos/logs/as400_permissions_audit.jsonl`.
3. Ambos feeds pueden visualizarse en tiempo real desde la pestaña **"Trazabilidad de Auditoría"** del dashboard.
