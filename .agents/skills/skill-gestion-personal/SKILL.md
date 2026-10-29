---
name: skill-gestion-personal
description: Skill especializado para la administración de notas de trabajo, atajos de comandos, capturas de pantalla de Snagit y documentos personales en D:\Cerebro Digital. Activar al trabajar con notas, Snagit o documentos personales.
---

# Skill: Gestión Personal & Notas (`skill-gestion-personal`)

Este Skill administra la documentación del día a día, capturas de pantalla de Snagit, notas rápidas de texto y expedientes personales.

---

## Cobertura de Carpetas

### 1. `D:\Cerebro Digital\10_Notas_y_Comandos`
- **`Atajos_y_Comandos`**: PDFs de atajos de teclado Windows y listas de comandos CMD.
- **`Notas_Trabajo_Textos`**: Notas en texto plano (`.txt`) de trabajo diario (AZMONITOR, SQL, StandGuard, Ciber, CyberArk, etc.).

### 2. `D:\Cerebro Digital\11_Snagit_Capturas`
- **`DataStore`**: Base de datos de capturas de Snagit.
- **`Capturas_Snagx`**: Archivos de captura `.snagx` y `.snag`.

### 3. `D:\Cerebro Digital\12_Personal`
- **`ARI`**: Formularios y comprobantes ARI.
- **`Certificados`**: Certificados académicos y profesionales personales.
- **`Documentos`**: Documentación legal e identificación.
- **`Poliza`**: Documentos de pólizas y seguros.
- **`Otros`**: Archivos personales diversos.

---

## Reglas de Clasificación

* Notas en formato texto `.txt` sin clasificar van automáticamente a `10_Notas_y_Comandos\Notas_Trabajo_Textos`.
* Archivos `.snagx` deben ser ubicados en `11_Snagit_Capturas`.
* Expedientes personales, comprobantes fiscales o fotos van a `12_Personal`.
