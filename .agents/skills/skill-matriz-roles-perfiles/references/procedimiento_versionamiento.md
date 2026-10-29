# Procedimiento de Versionamiento y Respaldo de Matrices

Este documento establece el estándar de versionamiento, almacenamiento histórico y remediación para las Matrices de Roles y Perfiles en la red compartida de Banesco.

---

## 1. Nomenclatura Estándar de Versionamiento

Antes de aplicar cualquier cambio o depuración sobre una matriz original (por ejemplo `ICS.xlsm`), el sistema genera obligatoriamente una copia exacta e inmutable en la subcarpeta `_Versiones_Historicas`.

### Formato de Archivo Versionado:
```
[Nombre_Matriz]_v[AÑO][MES][DIA]_[HORA][MINUTO][SEGUNDO].[ext]
```

### Ejemplos:
- Archivo Original: `ICS.xlsm`
- Copia de Respaldo: `_Versiones_Historicas\ICS_v20261008_140210.xlsm`
- Reporte Asociado: `reports\Reporte_Inconsistencias_ICS_20261008_140210.xlsx`

---

## 2. Prevención de Bloqueos en Red UNC (File Locking)

Dado que las matrices residen en recursos compartidos de Windows (`\\intra.banesco.com\datos\...`), es común que otros usuarios o analistas tengan el archivo abierto en Excel.

Para prevenir excepciones de tipo `IOException: El proceso no puede obtener acceso al archivo porque está siendo utilizado en otro proceso`:

1. **Lectura Segura**: Se abre el stream con modo `FileShare.ReadWrite`.
2. **Copia en Memoria/Temporal**: Se crea una copia de trabajo en el directorio `%TEMP%` local para procesar el análisis de celdas sin retener bloqueos en el recurso de red.
3. **Escritura Transaccional**: Al momento de aplicar la remediación (eliminación de filas), se verifica que el archivo no posea un lock temporal de Excel (`~$ICS.xlsm`). Si el archivo está bloqueado por otro usuario con permiso exclusivo de edición, el proceso se detiene de forma segura y emite una alerta indicando que el archivo debe cerrarse antes de proceder.

---

## 3. Plan de Reversibilidad (Rollback)

Si por error se depura a un usuario que poseía una excepción aprobada o justificación operativa:
1. El archivo versionado en `_Versiones_Historicas` conserva el estado 100% original con todas sus fórmulas, macros (VBA) y formatos visuales intactos.
2. Cada acción queda asentada en `logs/matriz_audit.jsonl` registrando la línea exacta y datos del colaborador retirado.
3. El proceso de restauración consiste simplemente en reponer el archivo original desde la copia versionada previa.
