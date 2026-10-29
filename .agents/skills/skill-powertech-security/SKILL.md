---
name: skill-powertech-security
description: Administra la seguridad, intercepción de comandos, reglas Deny-Default, respaldos de PTCSLIB y solución de problemas en Powertech Command Security (IBM i / AS400). USE CUANDO el usuario mencione 'Powertech', 'PTCSLIB', 'Command Security', 'Deny Default', 'restaurar PTCSLIB', 'intercepción de comandos CL' o la gestión de reglas de seguridad en AS400. NO USE PARA administración general de CyberArk PAM, tokenización Cryptgrip ni consultas SQL directas a la tabla TLMST.
---

# Skill: Powertech Command Security (`skill-powertech-security`)

Este Skill es el enrutador operativo para la gestión de Powertech Command Security (`PTCSLIB`) en entornos IBM i / AS400.

---

## 🛠️ Matriz de Navegación Just-In-Time (JIT)

Para consultar los procedimientos técnicos detallados, accede a los siguientes módulos de referencia:

1. **Requisitos de Sistema e Instalación:**
   - Consultar [`requisitos_e_instalacion.md`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-powertech-security/references/requisitos_e_instalacion.md)
   - *Cubre: System Values (`QALWOBJRST`, `QVFYOBJRST`, `QALWUSRDMN`), autorizaciones `*SECOFR` e instalación manual (`LODRUN`) o automatizada.*

2. **Respaldo, Migración y Restauración:**
   - Consultar [`respaldo_restauracion_ptcs.md`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-powertech-security/references/respaldo_restauracion_ptcs.md)
   - *Cubre: Detención segura (`PCSENDMON`), creación de `SAVF`, restauración (`RSTLIB`) y reinicio (`PCSSTRMON`).*

3. **Gestión de Reglas, Intercepción y Deny-by-Default:**
   - Consultar [`reglas_deny_default.md`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-powertech-security/references/reglas_deny_default.md)
   - *Cubre: Diferencia entre Command Security y Network Security, motor de reglas (`*ALLOW`, `*BLOCK`, `*LOG`, `*SUBSTITUTE`) y estrategia Zero Trust.*

4. **Resolución de Problemas y Mantenimiento:**
   - Consultar [`mantenimiento_y_trouble.md`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-powertech-security/references/mantenimiento_y_trouble.md)
   - *Cubre: Bloqueos de biblioteca `PTCSLIB`, fallas en `PCSDAQMON`, integración SIEM (Syslog/QAUDJRN) y comandos rápidos.*

---

## 🛡️ Reglas Operativas de Portabilidad y Resiliencia
- Utilizar variables de entorno (`$env:POWERTECH_PATH`) o rutas relativas para referencias locales.
- **Idempotencia en comandos CL:** Antes de ejecutar `RSTLIB`, verificar la detención limpia del monitoreo (`PCSENDMON`) y la ausencia de candados (`WRKOBJLCK PTCSLIB *LIB`).
