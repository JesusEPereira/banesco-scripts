const path = require('path');
const fs = require('fs');
const XLSX = require('../node_modules/xlsx');

const filePath = process.argv[2] || 'C:\\Users\\jespereira\\Downloads\\_Clasificación de Actividades No Recurrentes V1.0.xlsx';
const exportJsonPath = process.argv[3] || 'D:\\WKESPEREIRA\\D\\Scripts\\actividades_resumen.json';

if (!fs.existsSync(filePath)) {
  console.error(`[ERROR] No se encontró el archivo: ${filePath}`);
  process.exit(1);
}

const workbook = XLSX.readFile(filePath);
const report = [];
let globalOpen = 0;
let globalClosed = 0;
let globalTotal = 0;
const globalAreas = {};

const IGNORED_SHEETS = ['dashboard central', 'indicadores', 'resumen', 'ind'];

workbook.SheetNames.forEach(sheetName => {
  const normSheetName = sheetName.trim().toLowerCase();
  if (IGNORED_SHEETS.includes(normSheetName)) return;

  const sheet = workbook.Sheets[sheetName];
  if (!sheet || !sheet['!ref']) return;

  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });
  if (rows.length < 2) return;

  let headerRow = -1;
  let colArea = -1;
  let colResp = -1;
  let colStatus = -1;

  for (let r = 0; r < Math.min(rows.length, 5); r++) {
    const row = rows[r];
    for (let c = 0; c < row.length; c++) {
      const val = String(row[c]).trim().toLowerCase();
      if (val.includes('area') || val.includes('unidad administrativa')) {
        colArea = c;
        headerRow = r;
      }
      if (val === 'responsable' || val === 'responsables') {
        colResp = c;
        headerRow = r;
      }
      if (val === 'estatus banco') {
        colStatus = c;
      }
    }
    if (colArea !== -1 && colResp !== -1 && colStatus !== -1) break;
  }

  if (headerRow === -1) headerRow = 1;
  if (colResp === -1) colResp = 9; // Col J
  if (colArea === -1) colArea = (colResp === 8) ? 4 : 8; // Col E si resp es Col I, o Col I si resp es Col J

  if (colStatus === -1) {
    if (sheetName.toLowerCase().includes('npf')) colStatus = 14;
    else if (colResp === 8) colStatus = 13;
    else colStatus = 14;
  }

  let openCount = 0;
  let closedCount = 0;
  const respStats = {};
  const areaStats = {};
  const items = [];

  for (let r = headerRow + 1; r < rows.length; r++) {
    const row = rows[r];
    const idVal = String(row[0] || row[1] || '').trim();
    let areaRaw = String(row[colArea] || '').trim();
    let respRaw = String(row[colResp] || '').trim();
    const statusRaw = String(row[colStatus] || '').trim();
    const detailVal = String(row[2] || row[3] || row[4] || '').trim();

    if (!idVal && !areaRaw && !respRaw && !statusRaw) continue;

    // Normalizar Área
    let areaVal = areaRaw
      .replace(/\r?\n/g, ' / ')
      .replace(/\s+/g, ' ')
      .replace(/\/\s*\//g, '/')
      .replace(/^\/\s*|\s*\/$/g, '')
      .trim();
    if (!areaVal) areaVal = "Sin Asignar";

    // Normalizar Responsable
    let respVal = respRaw
      .replace(/\r?\n/g, ' / ')
      .replace(/\s+/g, ' ')
      .replace(/\/\s*\//g, '/')
      .replace(/^\/\s*|\s*\/$/g, '')
      .trim();
    if (!respVal) respVal = "Sin Asignar";

    const isClosed = /^(cerrado|conforme|completado|entregado|cumple|ok)$/i.test(statusRaw);
    
    if (isClosed) {
      closedCount++;
    } else {
      openCount++;
    }

    // Estadísticas de Responsable
    if (!respStats[respVal]) {
      respStats[respVal] = { Abiertos: 0, Cerrados: 0, Total: 0 };
    }
    if (isClosed) respStats[respVal].Cerrados++; else respStats[respVal].Abiertos++;
    respStats[respVal].Total++;

    // Estadísticas de Área
    if (!areaStats[areaVal]) {
      areaStats[areaVal] = { Abiertos: 0, Cerrados: 0, Total: 0 };
    }
    if (isClosed) areaStats[areaVal].Cerrados++; else areaStats[areaVal].Abiertos++;
    areaStats[areaVal].Total++;

    // Global Área
    if (!globalAreas[areaVal]) {
      globalAreas[areaVal] = { Abiertos: 0, Cerrados: 0, Total: 0 };
    }
    if (isClosed) globalAreas[areaVal].Cerrados++; else globalAreas[areaVal].Abiertos++;
    globalAreas[areaVal].Total++;

    items.push({
      Fila: r + 1,
      Id: idVal || ('Fila ' + (r + 1)),
      Area: areaVal,
      Responsable: respVal,
      EstatusBanco: statusRaw || 'Abierto',
      EstatusNormalizado: isClosed ? 'Cerrado' : 'Abierto',
      Detalle: detailVal.length > 90 ? detailVal.slice(0, 90) + '...' : detailVal
    });
  }

  const sheetTotal = openCount + closedCount;
  globalOpen += openCount;
  globalClosed += closedCount;
  globalTotal += sheetTotal;

  report.push({
    Pestana: sheetName,
    ColumnaAreaIndex: colArea + 1,
    ColumnaResponsableIndex: colResp + 1,
    ColumnaEstatusIndex: colStatus + 1,
    TotalAbiertos: openCount,
    TotalCerrados: closedCount,
    Total: sheetTotal,
    PorcentajeCerrado: sheetTotal > 0 ? Math.round((closedCount / sheetTotal) * 10000) / 100 : 0,
    Areas: areaStats,
    Responsables: respStats,
    Items: items
  });
});

console.log('\n================================================================================');
console.log(' BANESCO - INFORME CONSOLIDADO (ÁREAS, RESPONSABLES Y ESTATUS BANCO)');
console.log('================================================================================');
const globalPct = globalTotal > 0 ? Math.round((globalClosed / globalTotal) * 10000) / 100 : 0;
console.log(`  [TOTAL GENERAL] Items Auditados: ${globalTotal} | Cerrados: ${globalClosed} | Abiertos: ${globalOpen} | Avance: ${globalPct}%`);
console.log('--------------------------------------------------------------------------------');

// Resumen Global por Área
console.log('\n>>> CONSOLIDADO GLOBAL POR ÁREA / UNIDAD ADMINISTRATIVA:');
console.log('    ' + 'Área / Unidad Administrativa'.padEnd(52) + ' | ' + 'Abiertos'.padStart(9) + ' | ' + 'Cerrados'.padStart(9) + ' | ' + 'Total'.padStart(8));
console.log('    --------------------------------------------------------------------------------');
Object.keys(globalAreas).sort((a,b) => globalAreas[b].Total - globalAreas[a].Total).forEach(area => {
  const s = globalAreas[area];
  console.log(`    ${area.padEnd(52)} | ${String(s.Abiertos).padStart(9)} | ${String(s.Cerrados).padStart(9)} | ${String(s.Total).padStart(8)}`);
});

report.forEach(rep => {
  console.log(`\n>>> PESTAÑA: [${rep.Pestana}]`);
  console.log(`    Columnas -> Área: Col ${rep.ColumnaAreaIndex} | Responsable: Col ${rep.ColumnaResponsableIndex} | Estatus: Col ${rep.ColumnaEstatusIndex}`);
  console.log(`    Totales  -> Cerrados: ${rep.TotalCerrados} | Abiertos: ${rep.TotalAbiertos} | Total: ${rep.Total} (${rep.PorcentajeCerrado}% Cerrado)`);
  console.log('    -- Áreas en esta Pestaña --');
  Object.keys(rep.Areas).sort((a,b) => rep.Areas[b].Total - rep.Areas[a].Total).forEach(area => {
    const s = rep.Areas[area];
    console.log(`      * ${area.padEnd(48)} | Ab: ${String(s.Abiertos).padStart(3)} | Ce: ${String(s.Cerrados).padStart(3)} | Tot: ${String(s.Total).padStart(3)}`);
  });
});
console.log('================================================================================');

const exportData = {
  ArchivoFuente: filePath,
  FechaGeneracion: new Date().toISOString().replace('T', ' ').slice(0, 19),
  TotalesGlobales: {
    TotalItems: globalTotal,
    TotalAbiertos: globalOpen,
    TotalCerrados: globalClosed,
    PorcentajeAvance: globalPct
  },
  ConsolidadoGlobalAreas: globalAreas,
  Pestanas: report
};

fs.writeFileSync(exportJsonPath, JSON.stringify(exportData, null, 2), 'utf8');
console.log(`[OK] Datos exportados exitosamente a JSON: ${exportJsonPath}`);
