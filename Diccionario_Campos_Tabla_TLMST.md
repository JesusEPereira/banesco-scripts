# Diccionario de Campos de la Tabla TLMST (Maestro de Cajeros/Cajas IBS - IBM i / AS400)

**Biblioteca Recomendada:** `BANCYFILES` / `CCCCYFILES`  
**Nombre de la Tabla / Archivo Físico:** `TLMST`  
**Descripción:** Tabla Maestra de Configuración, Lotes, Balances y Parámetros Operativos de Cajeros/Cajas (Tellers/Terminals).  
**Ubicación en Cerebro Digital:** `D:\Cerebro Digital\05_AS400_IBM_i\01_Documentos_y_Manuales\Diccionario_Campos_Tabla_TLMST.md`

---

## Estrategia de Diccionario de Campos (29 Campos Principales)

| # | Nombre de Campo | Etiqueta / Texto de Columna | Descripción y Uso Funcional en IBS |
| :---: | :--- | :--- | :--- |
| 1 | **`TLMTID`** | TELLER I D | Identificador único del Cajero / Carga Terminal (ej. `BAN1750C51`). |
| 2 | **`TLMCCY`** | TELLER CCY | Moneda operativa del cajero (ej. `BS`, `USD`). |
| 3 | **`TLMF01`** | AVAILABLE | Campo reservado / Disponible 1. |
| 4 | **`TLMCLF`** | CLOSED FLAG | Estado de cierre del cajero (`A` = Abierto/Activo, `C` = Cerrado). |
| 5 | **`TLMBTH`** | TELLER BATCH NO | Número de Lote activo del cajero (ej. `31191`, `31213`). |
| 6 | **`TLMCST`** | COST CENTER | Centro de Costo asignado a la caja/oficina. |
| 7 | **`TLMF02`** | AVAILABLE | Campo reservado / Disponible 2. |
| 8 | **`TLMRDM`** | TL RUN DATE MM | Mes del proceso / Fecha de ejecución de la caja (MM). |
| 9 | **`TLMRDD`** | TL RUN DATE DD | Día del proceso / Fecha de ejecución de la caja (DD). |
| 10 | **`TLMRDY`** | TL RUN DATE YY | Año del proceso / Fecha de ejecución de la caja (YY). |
| 11 | **`TLMTOP`** | TL OPNING CASH | Saldo o efectivo de apertura de la caja. |
| 12 | **`TLMMXC`** | TELLER MAX CASH | Límite máximo de efectivo permitido en la caja. |
| 13 | **`TLMPWD`** | TELLER PASSWORD | Contraseña/Credencial asignada a la clave de cajero. |
| 14 | **`TLMOHD`** | CK ONUS HLD DYS | Días de retención para cheques a cargo del mismo banco (On-Us). |
| 15 | **`TLMLOD`** | LOCAL HLD DYS | Días de retención para cheques locales de otros bancos. |
| 16 | **`TLMNLD`** | N/LOCAL HLD DYS | Días de retención para cheques no locales / plazas foráneas. |
| 17 | **`TLMTYP`** | TELLER TYPE | Tipo de cajero / clasificación de taquilla (ej. Principal, Multifuncional). |
| 18 | **`TLMBNK`** | TELLER BANK | Código del banco emisor/operativo. |
| 19 | **`TLMBRN`** | TELLER BRANCH | Código de la agencia / sucursal a la que pertenece la caja. |
| 20 | **`TLMCUR`** | TELLER CCY | Código ISO de moneda de transacción del cajero. |
| 21 | **`TLMGLN`** | TELLER G/L | Cuenta de Mayor (General Ledger) contable del cajero. |
| 22 | **`TLMMBL`** | TELLER MEMO BAL | Saldo acumulado en memoria del cajero. |
| 23 | **`TLMFLW`** | FLR/LIM WITH | Límite de retiro autorizado en taquilla (*Floor Limit Withdrawal*). |
| 24 | **`TLMFLD`** | FLR/LIM DEPS | Límite de depósito autorizado en taquilla (*Floor Limit Deposit*). |
| 25 | **`TLMTCN`** | TRANSACTION COUNTER | Contador secuencial acumulado de transacciones efectuadas. |
| 26 | **`TLMONG`** | CK ONUS N/H G/L | Cuenta contable G/L para cheques On-Us sin retención. |
| 27 | **`TLMOHG`** | CK ONUS HLD G/L | Cuenta contable G/L para cheques On-Us retenidos. |
| 28 | **`TLMLOG`** | LOCAL CHK G/L | Cuenta contable G/L para cheques locales. |
| 29 | **`TLMNLG`** | N/LOCAL CHK G/L | Cuenta contable G/L para cheques no locales / foráneos. |

---

## Consultas Frecuentes de Ejemplo en SQL (DB2 for i)

### 1. Consultar estado y lote por cajero
```sql
SELECT TLMTID, TLMCCY, TLMCLF, TLMBTH, TLMBRN 
FROM BANCYFILES.TLMST 
WHERE TLMTID = 'BAN1750C51';
```

### 2. Consultar cajeros por lote
```sql
SELECT TLMTID, TLMCCY, TLMBTH 
FROM BANCYFILES.TLMST 
WHERE TLMBTH = 31191;
```

### 3. Modificar lote en un rango de cajeros
```sql
UPDATE BANCYFILES.TLMST 
SET TLMBTH = 31191 
WHERE TLMTID BETWEEN 'BAN1750C51' AND 'BAN1750C99' 
  AND TLMBTH = 31213;
```

---

## 🛠️ Skill Especializado de Modificaciones (`skill-tlmst-as400`)

Para acceder al catálogo completo de sentencias SQL depuradas y listas para ejecución (modificación de `TLMTYP`, `TLMFLW`, `TLMOHG`, `TLMLOG`, `TLMNLG`, `TLMBTH` y manipulación de `TLMTID` con `REPLACE` y `SUBSTR`), consulta:
- **Skill:** [`SKILL.md`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-tlmst-as400/SKILL.md)
- **Script SQL:** [`update_tlmst_queries.sql`](file:///d:/WKESPEREIRA/D/Scripts/.agents/skills/skill-tlmst-as400/scripts/update_tlmst_queries.sql)

