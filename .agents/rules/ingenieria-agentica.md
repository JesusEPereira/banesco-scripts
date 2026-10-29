# Regla de Ingeniería Agéntica: Arquitectura Neurosimbólica de 4 Capas y Guardarraíles Banesco

> **Alcance:** Obligatorio para todo agente, subagente y desarrollador al crear, refactorizar o auditar skills, herramientas y scripts en este workspace.
> **Fuente de Verdad:** `c:\Users\jespereira\Downloads\Manual_de_Ingenieria_Agentica.md`.

---

## 1. Regla de Oro: Ciclo de Creación de Nuevas Skills
Toda nueva habilidad (*skill*) que se agregue al catálogo debe cumplir estrictamente las **4 Capas Neurosimbólicas**:

```text
Paso 1: Delimitar el Dominio
   ↓
Paso 2: Construir el Manifiesto SSOT (.psd1 o .json < 4 KB en .agents/manifests/)
   ↓
Paso 3: Redactar Frontmatter YAML (Acción Imperativa + USE CUANDO + NO USE PARA)
   ↓
Paso 4: Redactar SKILL.md con Paso 0 Mandatorio (Carga One-Hop del Manifiesto)
   ↓
Paso 5: Registrar Guardarraíles en Hooks (.agents/hooks.json / safety-gate.ps1)
   ↓
Paso 6: Certificar mediante Pruebas Unitarias
```

---

## 2. Especificación Técnica por Capa

### Capa 1: Manifiesto Declarativo de Configuración (SSOT)
* Los datos de infraestructura (servidores, IPs, OUs, puertos, rutas UNC, nombres de tablas) **NUNCA** se redactan en prosa dentro de `SKILL.md` ni se queman (*hardcodean*) en scripts.
* Residen en `.agents/manifests/<nombre>.psd1` (o `.json`), con un tamaño estrictamente **menor a 4 KB** (250 a 1.000 tokens).
* **Blindaje AST:** En archivos `.psd1` se deben usar **exclusivamente comillas simples `'...'`** para rutas o variables, previniendo errores de parseo en `Import-PowerShellDataFile`.

### Capa 2: Frontmatter YAML de Alta Activación
Todo archivo `SKILL.md` debe abrir con un bloque YAML que cumpla la **Fórmula Canónica de 3 Partes**:
1. **Acción Imperativa:** Verbo técnico que declare la acción concreta.
2. **`USE CUANDO`:** Catálogo denso de términos clave exactos, comandos, rutas, extensiones y síntomas de error.
3. **`NO USE PARA`:** Fronteras de exclusión negativa hacia otras skills para eliminar colisiones semánticas.

### Capa 3: Anclaje Epistémico One-Hop en `SKILL.md`
* Erradicar la navegación laberíntica en dos saltos (*two-hop retrieval*).
* **Paso 0 Mandatorio:** Toda skill técnica debe iniciar su flujo operativo con el bloque estándar de carga del manifiesto de la Capa 1:
  ```powershell
  $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\manifests\banesco-infrastructure.psd1'
  if (-not (Test-Path $ManifestPath)) {
      $ManifestPath = 'D:\WKESPEREIRA\D\Scripts\.agents\manifests\banesco-infrastructure.psd1'
  }
  $Infra = Import-PowerShellDataFile -Path $ManifestPath
  ```
* Se prohíbe asumir o adivinar OUs, rutas o hosts: todo parámetro debe filtrarse desde `$Infra`.

### Capa 4: Guardarraíles Físicos en Hooks (`.agents/hooks.json`)
* Toda acción de escritura, plan o parada de turno está custodiada por `hooks.json` en `.agents/hooks/`:
  - `PreToolUse` (`safety-gate.ps1`): Scope lock y compuerta anti-incertidumbre (rechaza `TBD`, `por confirmar`, `se asume`).
  - `PostToolUse` (`post-tool-ps1.ps1`): Auditoría posterior y saneamiento.
  - `Stop` (`stop-format-linter.ps1`): Linter de salida contra fugas de sintaxis LaTeX.

---

## 3. Invariantes de Código Windows Server / PowerShell 5.1

1. **Inyección de UTF-8 con BOM:** Todo script `.ps1` o `.psm1` debe guardarse con BOM (`0xEF, 0xBB, 0xBF`) para erradicar el *mojibake* en Windows PowerShell 5.1.
2. **Cabecera Obligatoria de Consola:**
   ```powershell
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   $OutputEncoding = [System.Text.Encoding]::UTF8
   ```
3. **Invariante Cero Emojis en Backend/Consola:** Se prohíbe el uso de emojis en scripts `.ps1`, tareas programadas, logs y respuestas de guardarraíles. Usar exclusivamente prefijos ASCII canónicos:
   `[INFO]`, `[OK]`, `[ALERTA]`, `[ERROR]`, `[GUARDARRAIL]`.
4. **Cero Sintaxis LaTeX en Prosa:** Prohibido el uso de delimitadores matemáticos `$...$` o `$$...$$` en texto explicativo; usar texto plano y flechas Unicode (`A → B`).

