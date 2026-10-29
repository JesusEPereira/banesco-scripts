# Guía de Resolución de Problemas y Mantenimiento: Powertech Command Security

**Producto:** Powertech Command Security for IBM i (Fortra)  
**Biblioteca Principal:** `PTCSLIB`  

---

## 1. Solución de Fallas Comunes y Diagnóstico

### 1.1 Error: "Objects are locked in PTCSLIB" durante Actualización o Respaldo

**Causa**: Uno o más trabajos del sistema o usuarios mantienen un candado (*lock*) sobre los programas o archivos físicos de la biblioteca `PTCSLIB`.

**Solución**:
1. Identificar los trabajos activos en el subsistema de gestión:
   ```cl
   WRKACTJOB SBS(PTWRKMGT)
   ```
2. Detener el proceso de monitoreo de Command Security:
   ```cl
   PTCSLIB/PCSENDMON
   ```
3. Consultar los bloqueos existentes sobre la biblioteca `PTCSLIB`:
   ```cl
   WRKOBJLCK OBJ(PTCSLIB) OBJTYPE(*LIB)
   ```
4. Si existen sesiones interactivas o batch colgadas, finalizar el trabajo inmediatamente:
   ```cl
   ENDJOB JOB(NUMERO/USUARIO/NOMBRE) OPTION(*IMMED)
   ```

---

### 1.2 El Trabajo de Monitoreo `PCSDAQMON` no Inicia o se Cancela Inesperadamente

**Causa**: Falta de autorizaciones especiales en el perfil de servicio, clave de licencia vencida o daño en las colas de mensajes del producto.

**Pasos de Diagnóstico**:
1. Inspeccionar el diario de trabajo (*Job Log*) del proceso `PCSDAQMON`:
   ```cl
   DSPJOBLOG JOB(PCSDAQMON)
   ```
2. Verificar la validez de las claves de licencia:
   ```cl
   PTCSLIB/WRKLICINF
   ```
3. Confirmar que el valor del sistema `QAUDCTL` tenga activos los valores de auditoría:
   ```cl
   WRKSYSVAL SYSVAL(QAUDCTL)
   ```
4. Reconstruir los puntos de registro del producto:
   ```cl
   PTCSLIB/PCSUPDREG
   ```
5. Reiniciar el trabajo de monitoreo:
   ```cl
   PTCSLIB/PCSSTRMON
   ```

---

## 2. Integración con Agente Powertech SIEM (Envío Syslog)

Para retransmitir los eventos de intercepción de comandos en tiempo real hacia un **SIEM centralizado** (ej. QRadar, Splunk):

1. **Configuración de Salida**: Asegurar que la biblioteca del agente SIEM (`AVLIB` o `PTSIEM`) esté registrada en el punto de salida de auditoría de IBM i.
2. **Filtros de Envío**: Los eventos generados por `PTCSLIB` se registran en el diario del sistema `QAUDJRN` con tipos de entrada `CD` (*Command Security*) y `AF` (*Authority Failure*).
3. **Verificación de Transmisión Syslog**:
   Validar que el puerto Syslog UDP/TCP (por defecto `514`) esté abierto hacia el servidor SIEM:
   ```cl
   NETSTAT OPTION(*CNN)
   ```

---

## 3. Matriz de Comandos de Referencia Rápida

| Comando | Función / Descripción |
| :--- | :--- |
| `PTCSLIB/PCSSTRMON` | Inicia el trabajo de monitoreo de comandos (`PCSDAQMON`). |
| `PTCSLIB/PCSENDMON` | Detiene el trabajo de monitoreo de comandos. |
| `PTCSLIB/PCSUPDREG` | Reconstruye y actualiza la tabla de registros de comandos interceptados. |
| `DSPDTAARA PTCSLIB/PCSRELMOD` | Muestra la versión y release instalado de Command Security. |
| `WRKOBJLCK PTCSLIB *LIB` | Muestra los trabajos que bloquean la biblioteca del producto. |
| `WRKACTJOB SBS(PTWRKMGT)` | Muestra los procesos activos en el subsistema del producto. |
