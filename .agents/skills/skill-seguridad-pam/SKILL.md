---
name: skill-seguridad-pam
description: Skill especializado para la administración de ciberseguridad, PAM (CyberArk), autenticación multifactor (MFA Powertech) y gestión de Certificados/Truststores dentro de D:\Cerebro Digital. Activar al trabajar con CyberArk, MFA o Certificados SSL.
---

# Skill: Ciberseguridad & PAM (`skill-seguridad-pam`)

Este Skill gestiona las carpetas relativas a la gestión de accesos privilegiados, autenticación y certificados de seguridad.

---

## Cobertura de Carpetas

### 1. `D:\Cerebro Digital\01_CyberArk_PAM`
- **`01_Documentacion`**: Manuales, procedimientos y documentos informativos de CyberArk.
- **`02_Instaladores_y_Agentes`**: Agentes EPM, VFAgent, EdgeWebView2, SecurityOps.
- **`03_Certificados_y_Config`**: Certificados VPN CyberArk, CredFiles, archivos `.config`.
- **`04_Grabaciones_y_Casos`**: Videos de soporte e incidentes (ej. INC-632736 PSMP).

### 2. `D:\Cerebro Digital\02_MFA_Powertech`
- **`01_Instaladores`**: `setupPowertechMFA.exe`, `setupPowertechMFADesktop.exe`, Tomcat.
- **`02_Manuales_y_Guias`**: Guías de instalación, actualización de Tomcat, manuales de administración.
- **`03_Configuracion_y_Properties`**: `powertechmfa.properties` (Contingencia / PROD), listas de usuarios LDAP.
- **`04_Videos_Demostraciones`**: Demostraciones de instalación en HA, PROD y Contingencia.

### 3. `D:\Cerebro Digital\08_Certificados_y_Seguridad`
- **`SSL_TLS`**: Certificados públicos y privados (`.crt`, `.pem`, `.p7b`, `.csr`).
- **`P12_Truststores`**: Almacenes de claves y certs en formato PKCS12 (`client_truststore.p12`).
- **`Solicitudes_Formularios`**: Formularios de solicitud VICA Banesco.

---

## Reglas de Clasificación

* Toda extensión de instalador de seguridad (`.msi`, `.exe`) para CyberArk/MFA debe ir a su respectiva subcarpeta `01_Instaladores` / `02_Instaladores_y_Agentes`.
* Archivos `.properties` y `.config` de MFA/CyberArk van a `Configuraciones`.
* Certificados de cualquier tipo (`.pem`, `.pfx`, `.p12`, `.crt`, `.csr`) deben ir a `08_Certificados_y_Seguridad` salvo que sean específicos de CyberArk VPN.
