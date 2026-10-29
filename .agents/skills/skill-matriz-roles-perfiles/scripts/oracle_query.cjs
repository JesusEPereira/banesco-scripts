/**
 * oracle_query.cjs - Cliente Oracle Thin Mode para validacion de Cedulas en Banesco
 * Conecta a sdb8023.intra.banesco.com:1521/rrhh (actived) sin requerir cliente nativo.
 */

const fs = require('fs');
const path = require('path');
const oracledb = require('oracledb');

// Por defecto oracledb 6+ opera en Thin mode (100% JS puro)

const configPath = path.join(__dirname, 'config.json');
if (!fs.existsSync(configPath)) {
  console.error(JSON.stringify({ error: `No se encontró config.json en ${configPath}` }));
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

// Obtener credenciales desde argumentos o variables de entorno
const args = process.argv.slice(2);
function getArg(key, defaultValue = '') {
  const idx = args.indexOf(key);
  if (idx !== -1 && idx + 1 < args.length) return args[idx + 1];
  return defaultValue;
}

const mode = getArg('--mode', 'test');
const cedulasArg = getArg('--cedulas', '');
const password = getArg('--password', process.env.ORACLE_ACTIVED_PWD || '');
const outputFile = getArg('--output', '');

const dbConfig = {
  user: config.oracle.user || 'actived',
  password: password,
  connectString: `${config.oracle.host}:${config.oracle.port}/${config.oracle.sid}`
};

async function run() {
  if (mode === 'test') {
    console.log(`[ORACLE-THIN] Verificando parámetros de conexión:`);
    console.log(` - Cadena de conexión : ${dbConfig.connectString}`);
    console.log(` - Usuario            : ${dbConfig.user}`);
    console.log(` - Contraseña provista: ${password ? 'SÍ (enmascarada)' : 'NO (se requiere en runtime)'}`);

    if (!password) {
      console.log(`[INFO] Para probar autenticación completa ejecute con: node oracle_query.cjs --mode test --password TU_PASSWORD`);
      return;
    }
  }

  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    console.log(`[OK] Conexión establecida exitosamente con Oracle (${config.oracle.host}:${config.oracle.port}/${config.oracle.sid})`);

    if (mode === 'test') {
      const result = await connection.execute('SELECT COUNT(*) AS TOTAL FROM actived');
      console.log(`[OK] Consulta de prueba exitosa. Total activos en BD:`, result.rows[0]);
    } else if (mode === 'queryCedulas' && cedulasArg) {
      const cedulasList = cedulasArg.split(',').map(c => c.trim().replace(/\D/g, '')).filter(Boolean);
      if (cedulasList.length === 0) {
        console.log(JSON.stringify({ activeFound: [] }));
        return;
      }

      // Consulta en lote
      const bindParams = {};
      const bindKeys = cedulasList.map((ced, i) => {
        const key = `c${i}`;
        bindParams[key] = ced;
        return `:${key}`;
      });

      const sql = `SELECT CEDULA, NOMBRE, APELLIDO, SITUACION, COD_CARGO, CARGO, COD_UNI 
                   FROM ${config.oracle.tableActive} 
                   WHERE CEDULA IN (${bindKeys.join(',')})`;

      const result = await connection.execute(sql, bindParams, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      
      if (outputFile) {
        fs.writeFileSync(outputFile, JSON.stringify(result.rows, null, 2), 'utf8');
        console.log(`[OK] Resultados guardados en: ${outputFile}`);
      } else {
        console.log(JSON.stringify(result.rows));
      }
    } else if (mode === 'exportAll') {
      const sql = `SELECT CEDULA, NOMBRE, APELLIDO, SITUACION, COD_CARGO, CARGO, COD_UNI FROM ${config.oracle.tableActive}`;
      const result = await connection.execute(sql, {}, { outFormat: oracledb.OUT_FORMAT_OBJECT });
      const targetOut = outputFile || path.join(__dirname, '..', 'reports', 'actived_cache.json');
      fs.writeFileSync(targetOut, JSON.stringify(result.rows, null, 2), 'utf8');
      console.log(`[OK] Censo completo exportado (${result.rows.length} registros) en: ${targetOut}`);
    }
  } catch (err) {
    console.error(`[ERROR ORACLE]`, err.message);
    process.exitCode = 1;
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

run();
