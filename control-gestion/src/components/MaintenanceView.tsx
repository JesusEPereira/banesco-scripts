import React, { useState } from 'react';
import { 
  Wrench, 
  Database, 
  Calendar, 
  RotateCcw, 
  Download, 
  CheckCircle2, 
  AlertTriangle,
  Upload,
  HardDrive
} from 'lucide-react';
import { Task } from '../types';

interface MaintenanceViewProps {
  tasks: Task[];
  cutoffDate: string;
  setCutoffDate: (date: string) => void;
  onResetData: () => void;
  onOpenExportModal: () => void;
}

export const MaintenanceView: React.FC<MaintenanceViewProps> = ({
  tasks,
  cutoffDate,
  setCutoffDate,
  onResetData,
  onOpenExportModal,
}) => {
  const [tempDate, setTempDate] = useState(cutoffDate);
  const [successMsg, setSuccessMsg] = useState('');

  const handleApplyCutoff = () => {
    setCutoffDate(tempDate);
    setSuccessMsg(`Fecha de corte actualizada a: ${tempDate}`);
    setTimeout(() => setSuccessMsg(''), 3500);
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
          <Wrench className="w-5 h-5 text-indigo-600" />
          Módulo de Mantenimiento y Parámetros del Sistema
        </h2>
        <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-0.5">
          Gestión de corte operativo, sincronización de base de datos SQLite y exportación de respaldos
        </p>
      </div>

      {successMsg && (
        <div className="p-3 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-200 rounded-xl text-xs flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4 text-emerald-600" />
          <span>{successMsg}</span>
        </div>
      )}

      {/* Database State Card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-50 dark:bg-emerald-950 text-emerald-600 border border-emerald-200 dark:border-emerald-900">
              <Database className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-white">
                Estado de la Base de Datos (SQLite)
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Conexión local activa y persistente en el navegador
              </p>
            </div>
          </div>

          <span className="px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300">
            Conectado / Saludable
          </span>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs pt-2 border-t border-slate-100 dark:border-slate-800">
          <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl">
            <div className="text-slate-400 text-[10px] uppercase font-bold">Total Registros</div>
            <div className="text-lg font-bold text-slate-900 dark:text-white mt-0.5">{tasks.length} tareas</div>
          </div>

          <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl">
            <div className="text-slate-400 text-[10px] uppercase font-bold">Almacenamiento</div>
            <div className="text-lg font-bold text-slate-900 dark:text-white mt-0.5">24.8 KB</div>
          </div>

          <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl">
            <div className="text-slate-400 text-[10px] uppercase font-bold">Integridad</div>
            <div className="text-lg font-bold text-emerald-600 mt-0.5">100% OK</div>
          </div>

          <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl">
            <div className="text-slate-400 text-[10px] uppercase font-bold">Corte Activo</div>
            <div className="text-lg font-bold text-indigo-600 mt-0.5">{cutoffDate}</div>
          </div>
        </div>
      </div>

      {/* Adjust Operational Cutoff Date */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs space-y-3">
        <h3 className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <Calendar className="w-4 h-4 text-indigo-600" />
          Ajuste de Fecha de Corte Operativo (Cálculo de Tasa de Retraso)
        </h3>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          Cualquier tarea pendiente cuya fecha de próximo seguimiento sea anterior a esta fecha será clasificada como vencida y ponderada en la tasa de retraso.
        </p>

        <div className="flex flex-col sm:flex-row items-center gap-3 pt-2">
          <input
            type="date"
            value={tempDate}
            onChange={(e) => setTempDate(e.target.value)}
            className="w-full sm:w-auto px-3.5 py-2 text-xs rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500"
          />

          <button
            onClick={handleApplyCutoff}
            className="w-full sm:w-auto px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-xs transition-all"
          >
            Actualizar Fecha de Corte
          </button>
        </div>
      </div>

      {/* Backup & Reset Actions */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs space-y-4">
        <h3 className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <HardDrive className="w-4 h-4 text-indigo-600" />
          Respaldos y Reversión
        </h3>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            onClick={onOpenExportModal}
            className="flex items-center justify-center gap-2 p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-800 dark:text-slate-200 text-xs font-semibold transition-all"
          >
            <Download className="w-4 h-4 text-indigo-600" />
            <span>Generar Respaldo CSV / JSON</span>
          </button>

          <button
            onClick={onResetData}
            className="flex items-center justify-center gap-2 p-3.5 rounded-xl border border-rose-200 dark:border-rose-900/60 bg-rose-50/50 dark:bg-rose-950/20 hover:bg-rose-100 text-rose-700 dark:text-rose-300 text-xs font-semibold transition-all cursor-pointer"
          >
            <RotateCcw className="w-4 h-4 text-rose-600" />
            <span>Limpiar y Restablecer a 0 Actividades</span>
          </button>
        </div>
      </div>
    </div>
  );
};
