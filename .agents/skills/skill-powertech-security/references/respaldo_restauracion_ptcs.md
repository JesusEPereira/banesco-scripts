# Procedimiento de Respaldo, Migración y Restauración: Biblioteca PTCSLIB

**Producto:** Powertech Command Security for IBM i (Fortra)  
**Objetos Principales:** Biblioteca `PTCSLIB`, Subsistema `PTWRKMGT`  

---

## 1. Introducción y Consideraciones de Respaldo

Para respaldar correctamente el entorno de **Powertech Command Security** en IBM i, es fundamental salvar tanto la biblioteca principal `PTCSLIB` como los trabajos de gestión en `PTWRKMGT`. Antes de ejecutar el respaldo, **debe detenerse el trabajo de monitoreo activo (`PCSDAQMON`)** para evitar inconsistencias u objetos bloqueados.

---

## 2. Procedimiento Completo de Respaldo

### Paso 1: Detener el Servicio de Monitoreo

Desde la línea de comandos de IBM i con un usuario administrativo:
```cl
PTCSLIB/PCSENDMON
```
*Esto finalizará de forma limpia el trabajo `PCSDAQMON` en el subsistema `PTWRKMGT`.*

### Paso 2: Verificar la Ausencia de Bloqueos en la Biblioteca

Validar que no existan trabajos reteniendo objetos en `PTCSLIB`:
```cl
WRKOBJLCK OBJ(PTCSLIB) OBJTYPE(*LIB)
```
*Si se detectan trabajos interactivos o batch, deben finalizarse antes de continuar.*

### Paso 3: Crear el Archivo de Salvamento (Save File) y Ejecutar el Respaldo

```cl
CRTSAVF FILE(QGPL/PTCSBKUP) TEXT('Respaldo Powertech Command Security PTCSLIB')
SAVLIB LIB(PTCSLIB) DEV(*SAVF) SAVF(QGPL/PTCSBKUP) DTACPR(*HIGH)
```

### Paso 4: Reiniciar el Servicio de Monitoreo

Una vez finalizado el comando `SAVLIB`:
```cl
PTCSLIB/PCSSTRMON
```

---

## 3. Procedimiento de Migración o Restauración en un Nuevo Servidor (LPAR)

> ⚠️ **REGLA CRÍTICA DE RESTAURACIÓN**:  
> No restaure directamente la biblioteca `PTCSLIB` en un servidor IBM i nuevo sin realizar previamente una instalación limpia del producto. La instalación inicial crea perfiles de usuario del sistema, listas de autorización (*AUTL), subsistemas (`PTWRKMGT`) y puntos de salida (*Exit Points*).

### Pasos para Migrar o Restaurar en un Nuevo Sistema:

1. **Instalación Previa**: Ejecutar la instalación básica de Powertech Command Security en el nuevo servidor con la **misma versión** que el servidor de origen (verificar con `DSPDTAARA PTCSLIB/PCSRELMOD`).
2. **Detener el Monitoreo en el Servidor Destino**:
   ```cl
   PTCSLIB/PCSENDMON
   ```
3. **Restaurar la Biblioteca Sobreescribiendo Objetos de Datos**:
   ```cl
   RSTLIB SAVLIB(PTCSLIB) DEV(*SAVF) SAVF(QGPL/PTCSBKUP) MBROPT(*ALL) ALWOBJDIF(*ALL)
   ```
4. **Actualizar la Licencia de Producto**:
   Ingresar las nuevas claves de licencia proporcionadas por Fortra para el número de serie de la nueva LPAR/procesador.
5. **Reconstruir y Actualizar el Registro de Comandos**:
   ```cl
   PTCSLIB/PCSUPDREG
   ```
6. **Iniciar el Servicio de Monitoreo**:
   ```cl
   PTCSLIB/PCSSTRMON
   ```
