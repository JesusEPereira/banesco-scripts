---
name: skill-tlmst-as400
description: Skill especializado para la modificación de campos, lotes, tipos de cajero y cuentas contables en la tabla TLMST y tablas temporales (TEMP1740C8, TEMP1750, TEMP1750C2, TEMP1750C6, TEMPC591K2) en IBM i / AS400 (DB2).
---

# Skill: Modificación de Campos en Tabla TLMST y Temporales AS400 (`skill-tlmst-as400`)

Este Skill contiene el repositorio de sentencias SQL (DB2 for i) utilizadas para actualizar parámetros, lotes, tipos de cajeros, cuentas G/L y reestructurar identificadores (`TLMTID`) en la tabla maestra **`TLMST`** (`BANCYFILES`) y sus librerías / tablas de trabajo temporales (`ADMSEGCAL`, `SEGDATLIB`).

---

## 📋 Catálogo de Sentencias SQL de Actualización

### 1. Cambiar Tipo de Cajero (`TLMTYP`)
Modifica el tipo de cajero de 'T' a 'S' para un cajero específico en la tabla temporal.
- **Campos afectados:** `TLMTYP` (Teller Type)
- **Librería/Tabla:** `ADMSEGCAL/TEMP1750C6`

```sql
UPDATE ADMSEGCAL/TEMP1750C6 
SET TLMTYP = 'S' 
WHERE TLMTID = 'BAN1750C51' 
  AND TLMTYP = 'T';
```

---

### 2. Resetear Límite de Retiro en Taquilla (`TLMFLW`)
Establece a cero el Floor Limit Withdrawal (Límite de retiro autorizado) en la tabla maestra.
- **Campos afectados:** `TLMFLW` (Floor Limit Withdrawal)
- **Librería/Tabla:** `BANCYFILES/TLMST`

```sql
UPDATE BANCYFILES/TLMST 
SET TLMFLW = '.00' 
WHERE TLMTID = 'BAN1750C51';
```

---

### 3. Limpiar Cuentas Contables G/L de Cheques Retenidos y Locales
Actualiza las cuentas contables de retención de cheques a cargo del mismo banco (On-Us), cheques locales y no locales a `.00`.
- **Campos afectados:** `TLMOHG` (CK ONUS HLD G/L), `TLMLOG` (LOCAL CHK G/L), `TLMNLG` (N/LOCAL CHK G/L)
- **Librería/Tabla:** `SEGDATLIB/TEMP1750`

```sql
UPDATE SEGDATLIB/TEMP1750 
SET TLMOHG = '.00', 
    TLMLOG = '.00', 
    TLMNLG = '.00' 
WHERE TLMTID = 'BAN1750CAA';
```
> **Nota técnica:** Se corrigió la errata visual del script original (`TLMNLG7` -> `TLMNLG`) para corresponder al estándar real de la tabla `TLMST`.

---

### 4. Reemplazar Prefijo en Identificador de Cajero (`TLMTID`)
Reemplaza masivamente el prefijo de terminales de `BAN0591K` a `BAN1750C`.
- **Campos afectados:** `TLMTID` (Teller ID)
- **Librería/Tabla:** `SEGDATLIB/TEMP1750C2`
- **Registro histórico:** 1037 filas actualizadas en `TEMP1750C2` de `SEGDATLIB`.

```sql
UPDATE SEGDATLIB/TEMP1750C2 
SET TLMTID = REPLACE(TLMTID, 'BAN0591K', 'BAN1750C') 
WHERE TLMTID LIKE 'BAN0591K%';
```

---

### 5. Resetear Número de Lote (`TLMBTH`)
Reinicia el número de lote activo (`TLMBTH`) a 0 para un cajero específico cuando posea un lote anterior determinado.
- **Campos afectados:** `TLMBTH` (Teller Batch No)
- **Librería/Tabla:** `BANCYFILES/TLMST`

```sql
UPDATE BANCYFILES/TLMST 
SET TLMBTH = 0 
WHERE TLMTID = 'BAN1750CAA' 
  AND TLMBTH = 31180;
```

---

### 6. Reestructurar Formato del Identificador `TLMTID` mediante Substring
Modifica la posición 8 del identificador `TLMTID` colocándole el carácter `'K'`.
- **Campos afectados:** `TLMTID` (Teller ID)
- **Librería/Tabla:** `SEGDATLIB/TEMPC591K2`

```sql
UPDATE SEGDATLIB/TEMPC591K2 
SET TLMTID = SUBSTR(TLMTID, 1, 7) || 'K' || SUBSTR(TLMTID, 9, 2);
```

---

### 7. Cambiar Moneda del Cajero (`TLMCCY` / `TLMCUR`) de USD a EUR
Modifica la moneda operativa y de transacción de todos los cajeros que se encuentren configurados en USD a EUR.
- **Campos afectados:** `TLMCCY` (Teller Currency / Moneda Operativa), `TLMCUR` (Teller Currency ISO / Moneda Transacción)
- **Librería/Tabla:** `BANCYFILES/TLMST`

```sql
-- Opción A: Actualizar ambas columnas de moneda (Recomendado)
UPDATE BANCYFILES/TLMST 
SET TLMCCY = 'EUR', 
    TLMCUR = 'EUR' 
WHERE TLMCCY = 'USD' 
   OR TLMCUR = 'USD';

-- Opción B: Filtrar por un grupo/agencia específica (ej. BAN1740)
UPDATE BANCYFILES/TLMST 
SET TLMCCY = 'EUR', 
    TLMCUR = 'EUR' 
WHERE TLMTID LIKE 'BAN1740%' 
  AND TLMCCY = 'USD';
```

---

### 8. Reemplazar Rango de IDs de Cajero (`TLMTID`) de C51-C60 a C01-C10
Reemplaza el identificador único de cajero (`TLMTID`) para los terminales del `BAN1740C51` al `BAN1740C60` por la nueva numeración `BAN1740C01` al `BAN1740C10`.
- **Campos afectados:** `TLMTID` (Teller ID)
- **Librería/Tabla:** `SEGDATLIB/TEMP1740C8`
- **Total registros esperados:** 10 filas afectadas.

```sql
UPDATE SEGDATLIB/TEMP1740C8 
SET TLMTID = CASE TLMTID 
    WHEN 'BAN1740C51' THEN 'BAN1740C01' 
    WHEN 'BAN1740C52' THEN 'BAN1740C02' 
    WHEN 'BAN1740C53' THEN 'BAN1740C03' 
    WHEN 'BAN1740C54' THEN 'BAN1740C04' 
    WHEN 'BAN1740C55' THEN 'BAN1740C05' 
    WHEN 'BAN1740C56' THEN 'BAN1740C06' 
    WHEN 'BAN1740C57' THEN 'BAN1740C07' 
    WHEN 'BAN1740C58' THEN 'BAN1740C08' 
    WHEN 'BAN1740C59' THEN 'BAN1740C09' 
    WHEN 'BAN1740C60' THEN 'BAN1740C10' 
    ELSE TLMTID 
END 
WHERE TLMTID IN (
    'BAN1740C51', 'BAN1740C52', 'BAN1740C53', 'BAN1740C54', 'BAN1740C55', 
    'BAN1740C56', 'BAN1740C57', 'BAN1740C58', 'BAN1740C59', 'BAN1740C60'
);
```

---

### 9. Reemplazar Rango de IDs de Cajero (`TLMTID`) de C01-C10 a C11-C20
Reemplaza el identificador único de cajero (`TLMTID`) para los terminales del `BAN1740C01` al `BAN1740C10` por la nueva numeración consecutiva `BAN1740C11` al `BAN1740C20`.
- **Campos afectados:** `TLMTID` (Teller ID)
- **Librería/Tabla:** `SEGDATLIB/BAN1740JP9`
- **Total registros esperados:** 20 filas afectadas (10 cajeros con 2 registros de moneda cada uno: EUR y USD).

```sql
UPDATE SEGDATLIB/BAN1740JP9 
SET TLMTID = CASE TLMTID 
    WHEN 'BAN1740C01' THEN 'BAN1740C11' 
    WHEN 'BAN1740C02' THEN 'BAN1740C12' 
    WHEN 'BAN1740C03' THEN 'BAN1740C13' 
    WHEN 'BAN1740C04' THEN 'BAN1740C14' 
    WHEN 'BAN1740C05' THEN 'BAN1740C15' 
    WHEN 'BAN1740C06' THEN 'BAN1740C16' 
    WHEN 'BAN1740C07' THEN 'BAN1740C17' 
    WHEN 'BAN1740C08' THEN 'BAN1740C18' 
    WHEN 'BAN1740C09' THEN 'BAN1740C19' 
    WHEN 'BAN1740C10' THEN 'BAN1740C20' 
    ELSE TLMTID 
END 
WHERE TLMTID IN (
    'BAN1740C01', 'BAN1740C02', 'BAN1740C03', 'BAN1740C04', 'BAN1740C05', 
    'BAN1740C06', 'BAN1740C07', 'BAN1740C08', 'BAN1740C09', 'BAN1740C10'
);
```

---

### 10. Actualizar Teller G/L (`TLMGLN`) y Límite de Depósito en Taquilla (`TLMFLD`)
Modifica la cuenta contable de Mayor (`TLMGLN`) y el límite máximo de depósito autorizado (*Floor Limit Deposit* - `TLMFLD`) para los cajeros recién creados/actualizados `BAN1740C11` al `BAN1740C20`.
- **Campos afectados:** 
  - `TLMGLN` (TELLER G/L): de `0` a `111011000105000000` (formato contable sin comas de 18 dígitos: 111,011,000,105,000,000).
  - `TLMFLD` (FLR/LIM DEPS): de `100,000,000.00` a `.01`.
- **Librería/Tabla:** `SEGDATLIB/BAN1740JP9`
- **Total registros esperados:** 20 filas afectadas.

```sql
UPDATE SEGDATLIB/BAN1740JP9 
SET TLMGLN = 111011000105000000, 
    TLMFLD = .01 
WHERE TLMTID BETWEEN 'BAN1740C11' AND 'BAN1740C20';
```

---

### 11. Actualizar Cuentas G/L de Cheques Retenidos, Locales y No Locales
Modifica las tres cuentas contables G/L para cheques On-Us retenidos (`TLMOHG`), cheques locales (`TLMLOG`) y cheques no locales (`TLMNLG`) para los cajeros `BAN1740C11` al `BAN1740C20`.
- **Campos afectados:** 
  - `TLMOHG` (CK ONUS HLD G/L): de `0` a `116011020500000000` (18 dígitos: 116,011,020,500,000,000).
  - `TLMLOG` (LOCAL CHK G/L): de `0` a `116011020500000000`.
  - `TLMNLG` (N/LOCAL CHK G/L): de `0` a `116011020500000000`.
- **Librería/Tabla:** `SEGDATLIB/BAN1740JP9`
- **Total registros esperados:** 20 filas afectadas.

```sql
UPDATE SEGDATLIB/BAN1740JP9 
SET TLMOHG = 116011020500000000, 
    TLMLOG = 116011020500000000, 
    TLMNLG = 116011020500000000 
WHERE TLMTID BETWEEN 'BAN1740C11' AND 'BAN1740C20';
```

---

## 📌 Referencia Rápida de Campos Modificados


| Campo | Descripción Funcional | Tipo / Formato |
| :--- | :--- | :--- |
| **`TLMTID`** | Identificador Único de Cajero/Terminal | Alfanumérico (ej. `BAN1750C51`) |
| **`TLMTYP`** | Tipo de Cajero (`S` = Supervisor, `T` = Terminal/Taquilla) | Carácter |
| **`TLMFLW`** | Floor Limit Withdrawal (Límite máximo de retiro) | Numérico Decimal |
| **`TLMFLD`** | Floor Limit Deposit (Límite máximo de depósito) | Numérico Decimal |
| **`TLMGLN`** | Teller G/L (Cuenta Contable de Mayor del Cajero) | Numérico / Decimal (18 dígitos) |
| **`TLMOHG`** | Cuenta G/L para Cheques On-Us Retenidos | Numérico / String Decimal |
| **`TLMLOG`** | Cuenta G/L para Cheques Locales | Numérico / String Decimal |
| **`TLMNLG`** | Cuenta G/L para Cheques No Locales / Foráneos | Numérico / String Decimal |
| **`TLMBTH`** | Número de Lote activo del Cajero (Batch Number) | Entero Numérico |


---

## 🛡️ Buenas Prácticas de Ejecución en DB2 for i (AS400)

1. **Respaldar Tablas Antes de Ejecutar:**
   ```sql
   -- Crear copia de respaldo en QTEMP o librería de trabajo
   CREATE TABLE QTEMP.TLMST_BAK AS (SELECT * FROM BANCYFILES.TLMST) WITH DATA;
   ```
2. **Validación Previa con `SELECT`:**
   Antes de ejecutar un `UPDATE`, verificar los registros que serán impactados:
   ```sql
   SELECT COUNT(*) FROM BANCYFILES.TLMST WHERE TLMTID = 'BAN1750CAA';
   ```
3. **Calificadores de Librería:**
   Recordar que en AS400/IBM i la sintaxis SQL puede usar `/` (sistema de archivos AS400) o `.` (estándar SQL):
   - `BANCYFILES/TLMST` o `BANCYFILES.TLMST`
