# Guía Técnica de Instalación y Requisitos: Powertech Command Security para IBM i

**Producto:** Powertech Command Security for IBM i (Fortra / HelpSystems)  
**Biblioteca Principal:** `PTCSLIB`  
**Ubicación en Cerebro Digital:** `D:\Cerebro Digital\05_AS400_IBM_i\06_Fortra_Auditoria`

---

## 1. Visión General del Producto

**Powertech Command Security** es la solución empresarial de Fortra para el monitoreo, control, intercepción y auditoría en tiempo real de comandos ejecutados en entornos **IBM i (AS/400)**. Permite controlar la ejecución de comandos sensibles (ej. `PWRDWNSYS`, `DLTLIB`, `CHGUSRPRF`, `STRSQL`, `CPYF`) tanto por línea de comandos como por programas en lote (batch) o interfaces de red.

---

## 2. Requisitos Previos e Instalación en IBM i

### 2.1 Valores del Sistema Requeridos

Antes de iniciar la instalación de Powertech Command Security, deben verificarse y ajustarse los siguientes valores de sistema (*System Values*) en IBM i:

* **`QALWOBJRST` (Restauración de Objetos)**:
  Debe estar configurado al menos en `*ALWPGMADP` o `*ALL` para permitir la restauración de programas con derechos adoptados.
  ```cl
  WRKSYSVAL SYSVAL(QALWOBJRST)
  ```

* **`QVFYOBJRST` (Verificación de Firma de Objetos)**:
  Debe permitir la restauración de objetos firmados o confiables (valores `1`, `2` o `3`).
  ```cl
  WRKSYSVAL SYSVAL(QVFYOBJRST)
  ```

* **`QALWUSRDMN` (Bibliotecas de Dominios de Usuario)**:
  Debe incluir la biblioteca `PTCSLIB` o el valor `*ALL`.
  ```cl
  WRKSYSVAL SYSVAL(QALWUSRDMN)
  ```

---

### 2.2 Autorizaciones Especiales del Usuario Instalador

El perfil de usuario que ejecute la instalación (ej. `QSECOFR` o un administrador de seguridad dedicado) **debe poseer clase `*SECOFR`** y las siguientes autorizaciones especiales (*Special Authorities*):

* `*ALLOBJ` (Acceso a todos los objetos)
* `*SECADM` (Administración de seguridad)
* `*JOBCTL` (Control de trabajos)
* `*SAVSYS` (Salvar/Restaurar sistema)
* `*IOSYSCFG` (Configuración de E/S)
* `*AUDIT` (Gestión de auditoría de sistema)

Para verificar las autoridades del perfil:
```cl
DSPUSRPRF USRPRF(SU_USUARIO_ADMIN)
```

---

## 3. Métodos de Instalación

### Método A: Instalación Automática mediante Setup Wizard (Recomendado)

1. Descargar el instalador `setupCommandSecurity.exe` desde el portal oficial de **Fortra Support**.
2. Ejecutar `setupCommandSecurity.exe` desde una estación de trabajo Windows conectada por red al servidor IBM i.
3. El asistente solicitará:
   - Dirección IP o nombre de Host del IBM i.
   - Perfil de usuario administrativo (`QSECOFR`) y contraseña.
   - Puerto FTP (por defecto puerto `21`).
4. El instalador transferirá automáticamente el archivo de salvamento (*Save File*) a la biblioteca `QGPL` y ejecutará los comandos de instalación en segundo plano.

---

### Método B: Instalación Manual mediante Save File (`LODRUN`)

Si las políticas de firewall impiden conexiones FTP directas:

1. Transferir manualmente el archivo de salvamento `PCSINSTALL` a la biblioteca `QGPL` del IBM i.
2. Desde la línea de comandos interactiva de IBM i, ejecutar:
   ```cl
   LODRUN DEV(*SAVF) SAVF(QGPL/PCSINSTALL)
   ```
3. Seguir las instrucciones en pantalla para confirmar la biblioteca de destino `PTCSLIB`.

---

## 4. Verificación de Instalación y Versión

Una vez finalizada la instalación, realizar las siguientes comprobaciones:

1. **Verificar la existencia de la biblioteca `PTCSLIB`**:
   ```cl
   DSPLIB LIB(PTCSLIB)
   ```

2. **Consultar la versión y módulo instalado**:
   ```cl
   DSPDTAARA DTAARA(PTCSLIB/PCSRELMOD)
   ```

3. **Verificar el servicio de monitoreo**:
   ```cl
   WRKACTJOB SBS(PTWRKMGT)
   ```
