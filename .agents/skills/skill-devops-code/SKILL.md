---
name: skill-devops-code
description: Skill especializado para la revisión de código (CodeChecker), perfiles de Banesconecta y gestión de scripts de automatización (PowerShell, SQL, Oracle) dentro de D:\Cerebro Digital. Activar al trabajar con CodeChecker, Banesconecta o scripts.
---

# Skill: Desarrollo & Automatización DevOps (`skill-devops-code`)

Este Skill administra los análisis de calidad de código, scripts de automatización y procedimientos de Banesconecta.

---

## Cobertura de Carpetas

### 1. `D:\Cerebro Digital\03_CodeChecker`
- **`01_Instaladores_y_Updates`**: Servidores, paquetes zip y actualizaciones de CodeChecker (23.x, 24.x, 25.1.1).
- **`02_Documentacion_y_Guias`**: Guías de reglas, configuración, roles y análisis de vulnerabilidades.
- **`03_Videos_Entrenamiento`**: Videos de entrenamiento en revisión de código y reglas.

### 2. `D:\Cerebro Digital\07_Banesconecta`
- **`01_Documentacion_y_Perfiles`**: Documentos de gestión de perfil de administración SICPR-01 (Módulo Administrativo y Recuperaciones).
- **`02_Videos_Transferencia`**: Videos de transferencia de conocimientos.

### 3. `D:\Cerebro Digital\09_Scripts_y_Herramientas`
- **`PowerShell`**: Scripts `.ps1` de automatización de tareas.
- **`Oracle`**: Archivos de configuración de base de datos (`tnsnames.ora`).
- **`SQL_Fusion`**: Scripts SQL y de base de datos.
- **`Proyectos_Automatizacion`**: Proyectos de actualización masiva de grupos, conectores Cloud, etc.

---

## Reglas de Clasificación

* Todos los scripts ejecutable (`.ps1`, `.sql`, `.ora`, `.py`) deben residir en `09_Scripts_y_Herramientas`.
* Paquetes de instalación o reglas de CodeChecker van exclusivamente en `03_CodeChecker`.
* Documentación de perfilado SICPR va en `07_Banesconecta`.
