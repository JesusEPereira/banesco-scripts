# Banesco - Gobernanza y Normas de Ingeniería Agéntica

Este repositorio opera bajo la **Arquitectura Neurosimbólica de 4 Capas** estandarizada en el [Manual de Ingeniería Agéntica](file:///c:/Users/jespereira/Downloads/Manual_de_Ingenieria_Agentica.md).

## Reglas Obligatorias para Agentes y Skills:
1. **SSOT en Manifiestos:** Cero rutas, OUs, hosts o credenciales quemadas en código o markdown. Consultar siempre `.agents/manifests/banesco-infrastructure.psd1` o `.json`.
2. **Frontmatter Canónico de 3 Partes:** Todo `SKILL.md` debe incluir Acción Imperativa, `USE CUANDO` denso y `NO USE PARA` restrictivo.
3. **Anclaje One-Hop:** Paso 0 de carga directa del manifiesto al inicio del flujo operativo en `SKILL.md`.
4. **Guardarraíles Activos:** Respetar los hooks del ciclo de vida en `.agents/hooks.json` (`safety-gate.ps1`, `post-tool-ps1.ps1`, `stop-format-linter.ps1`).
5. **Invariantes Windows/PowerShell:**
   - Inyección de UTF-8 con BOM en archivos `.ps1`/`.psm1`.
   - Cabecera `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`.
   - Cero emojis en backend/consola: emplear prefijos ASCII `[INFO]`, `[OK]`, `[ALERTA]`, `[ERROR]`, `[GUARDARRAIL]`.
   - Cero delimitadores LaTeX en narrativa.

Para detalles completos, consulte la regla de workspace: [ingenieria-agentica.md](file:///d:/WKESPEREIRA/D/Scripts/.agents/rules/ingenieria-agentica.md).

