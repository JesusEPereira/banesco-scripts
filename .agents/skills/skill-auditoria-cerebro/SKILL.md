---
name: skill-auditoria-cerebro
description: >-
  Auditar, escanear y organizar la estructura de carpetas y archivos huerfanos del repositorio maestro D:\Cerebro Digital.
  USE CUANDO el usuario mencione 'Cerebro Digital', 'auditoria cerebro', 'archivos sueltos', 'escanear D:\Cerebro Digital', 'Daily_Scan_Log.txt', 'CerebroDigital_DailyScan', 'organizar cerebro', 'carpetas maestras' o 'limpieza de raiz'.
  NO USE PARA matrices de roles y perfiles en Excel (use skill-matriz-roles-perfiles), ni para administracion de AS400 (use skill-as400-infra o skill-tlmst-as400), ni para control de gestion de tareas (use skill-control-gestion).
---

# Skill: Auditoria Diaria y Escaneo de Cerebro Digital (`skill-auditoria-cerebro`)

Este Skill supervisa el cumplimiento de la politica de orden y estructura de `D:\Cerebro Digital`, garantizando que ninguna informacion quede suelta en la raiz y auditando la ocupacion de las 13 carpetas maestras.

---

## Paso 0 Mandatorio: Anclaje Epistemico (One-Hop al Manifiesto SSOT)

De acuerdo a la Capa 1 y Capa 3 del Manual de Ingenieria Agentica, este skill consume sus rutas de configuracion desde el manifiesto central:

```powershell
$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\manifests\banesco-infrastructure.psd1'
if (-not (Test-Path $ManifestPath)) {
    $ManifestPath = 'D:\WKESPEREIRA\D\Scripts\.agents\manifests\banesco-infrastructure.psd1'
}
$Infra = Import-PowerShellDataFile -Path $ManifestPath

$RootDrive    = $Infra.CerebroDigital.RootDrive
$ScanTaskName = $Infra.CerebroDigital.DailyScanTaskName
$ScanLogFile  = $Infra.CerebroDigital.ScanLogFile
```

---

## 1. Alcance y Objetivos

1. **Auditoría de Carpetas Maestras**:
   - Inspecciona y calcula métricas (cantidad de archivos y MB) de las 13 carpetas maestras:
     * `01_CyberArk_PAM`
     * `02_MFA_Powertech`
     * `03_CodeChecker`
     * `04_Cryptgrip_Tokenizacion`
     * `05_AS400_IBM_i`
     * `06_Antivirus_StandGuard`
     * `07_Banesconecta`
     * `08_Certificados_y_Seguridad`
     * `09_Scripts_y_Herramientas`
     * `10_Notas_y_Comandos`
     * `11_Snagit_Capturas`
     * `12_Personal`
     * `13_Core_Tarjeta_AZ7`

2. **Detección de Archivos Sueltos en Raíz**:
   - Alerta inmediatamente si existen archivos depositados directamente en `D:\Cerebro Digital`.
   - Propone o ejecuta su reubicación en la carpeta maestra correspondiente.

3. **Registro Histórico de Auditoría**:
   - Guarda el reporte continuo en:
     `D:\Cerebro Digital\10_Notas_y_Comandos\Notas_Trabajo_Textos\Daily_Scan_Log.txt`.

---

## 2. Automatización en el Sistema Operativo

El escaneo diario se encuentra automatizado a nivel de **Windows Task Scheduler**:

- **Nombre de Tarea**: `CerebroDigital_DailyScan`
- **Frecuencia**: Diaria a las **08:00 AM**
- **Comando Ejecutado**:
  ```powershell
  PowerShell.exe -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\agents\cerebro-digital-agent\scripts\daily_scan_cerebro.ps1"
  ```
- **Verificación de Estado**:
  ```powershell
  Get-ScheduledTask -TaskName "CerebroDigital_DailyScan" | Format-List
  Get-ScheduledTaskInfo -TaskName "CerebroDigital_DailyScan" | Format-List
  ```

---

## 3. Scripts de Ejecución y Mantenimiento

### A. Reorganización y Movimiento Automático (`organize_cerebro.ps1`)
Inspecciona la raíz, clasifica de forma inteligente los archivos huérfanos y los mueve automáticamente a sus carpetas correspondientes:

```powershell
# Ejecución con movimiento automático de archivos huérfanos
powershell -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\agents\cerebro-digital-agent\scripts\organize_cerebro.ps1"

# Modo simulación (solo audita sin mover)
powershell -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\agents\cerebro-digital-agent\scripts\organize_cerebro.ps1" -AuditOnly
```

### B. Escaneo Diario y Registro de Logs (`daily_scan_cerebro.ps1`)
Ejecuta la auditoría integral, actualiza el registro histórico e invoca `organize_cerebro.ps1` si detecta archivos en la raíz:

```powershell
powershell -ExecutionPolicy Bypass -File "d:\WKESPEREIRA\D\Scripts\.agents\agents\cerebro-digital-agent\scripts\daily_scan_cerebro.ps1"
```

O verificar las últimas entradas de auditoría:

```powershell
Get-Content -Path "D:\Cerebro Digital\10_Notas_y_Comandos\Notas_Trabajo_Textos\Daily_Scan_Log.txt" -Tail 40
```

---

## 4. Reglas de Clasificación para Archivos Huérfanos Detectados

Si el escaneo reporta archivos sueltos en la raíz, aplicar la siguiente matriz de reubicación:

| Tipo de Archivo / Patrón | Carpeta Destino Sugerida |
| :--- | :--- |
| Vulnerabilidades AS400, FTP, Telnet (`.xlsx`, `.docx`) | `05_AS400_IBM_i\01_Documentos_y_Manuales` o `06_Fortra_Auditoria` |
| Guías de VPN, Cisco, Firewalls, Redes (`.pdf`, `.docx`) | `08_Certificados_y_Seguridad` o `10_Notas_y_Comandos\Notas_Trabajo_Textos` |
| Proyectos comprimidos, herramientas, código (`.zip`, `.rar`) | `09_Scripts_y_Herramientas\Proyectos_Automatizacion` |
| Presentaciones corporativas y plantillas (`.pptx`) | Subcarpeta de proyectos o `08_Certificados_y_Seguridad` / `09_Scripts_y_Herramientas` |
| Notas sueltas, listas rápidas (`.txt`) | `10_Notas_y_Comandos\Notas_Trabajo_Textos` |
| Capturas de pantalla (`.snag`, `.snagx`, `.png`) | `11_Snagit_Capturas` |
