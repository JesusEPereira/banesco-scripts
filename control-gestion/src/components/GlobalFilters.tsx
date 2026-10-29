import React from 'react';
import { Search, X, AlertTriangle, Clock, Flame, Filter } from 'lucide-react';
import { Collaborator, Domain, FilterState, Priority, Task, TaskStatus } from '../types';
import { isTaskOverdue, isTaskThisWeek } from '../utils/metrics';

interface GlobalFiltersProps {
  filters: FilterState;
  setFilters: React.Dispatch<React.SetStateAction<FilterState>>;
  collaborators: Collaborator[];
  allTasks: Task[];
  filteredCount: number;
  cutoffDate: string;
}

const DOMAINS: Domain[] = [
  'Windows',
  'IBMi',
  'Documentación',
  'PCI',
  'Auditoria Interna',
  'Auditoria Externa',
];

const PRIORITIES: Priority[] = ['Crítica', 'Alta', 'Media', 'Baja'];

const STATUSES: TaskStatus[] = ['Completado', 'En Proceso', 'En Revisión', 'Pendiente', 'Bloqueado'];

const COMPANIES = ['BBU', 'Banesco', 'CSO', 'Global'];

export const GlobalFilters: React.FC<GlobalFiltersProps> = ({
  filters,
  setFilters,
  collaborators,
  allTasks,
  filteredCount,
  cutoffDate,
}) => {
  const overdueCount = allTasks.filter((t) => isTaskOverdue(t, cutoffDate)).length;
  const thisWeekCount = allTasks.filter((t) => isTaskThisWeek(t, cutoffDate)).length;
  const criticalCount = allTasks.filter((t) => t.priority === 'Crítica' && t.status !== 'Completado').length;

  const handleResetFilters = () => {
    setFilters({
      searchQuery: '',
      collaboratorId: 'all',
      domain: 'all',
      priority: 'all',
      status: 'all',
      companyUnit: 'all',
      quickFilter: 'all',
      dateRangeStart: '',
      dateRangeEnd: '',
    });
  };

  const hasActiveFilters =
    filters.searchQuery.trim() !== '' ||
    filters.collaboratorId !== 'all' ||
    filters.domain !== 'all' ||
    filters.priority !== 'all' ||
    filters.status !== 'all' ||
    filters.companyUnit !== 'all' ||
    filters.quickFilter !== 'all' ||
    filters.dateRangeStart !== '' ||
    filters.dateRangeEnd !== '';

  return (
    <div className="bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 py-3.5 px-4 sm:px-6 transition-colors shadow-2xs">
      <div className="max-w-[1720px] mx-auto space-y-3">
        {/* Row 1: Search Bar + Quick status filter pills */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center gap-3">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={filters.searchQuery}
              onChange={(e) => setFilters((prev) => ({ ...prev, searchQuery: e.target.value }))}
              placeholder="Buscar por actividad, descripción, RFC, sistema, responsable..."
              className="w-full pl-10 pr-9 py-2 rounded-xl text-xs sm:text-sm bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
            />
            {filters.searchQuery && (
              <button
                onClick={() => setFilters((prev) => ({ ...prev, searchQuery: '' }))}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Quick pills */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0">
            <button
              onClick={() => setFilters((prev) => ({ ...prev, quickFilter: 'all' }))}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all ${
                filters.quickFilter === 'all'
                  ? 'bg-slate-900 dark:bg-slate-100 text-white dark:text-slate-900 shadow-xs'
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700'
              }`}
            >
              Todas ({allTasks.length})
            </button>

            <button
              type="button"
              onClick={() => {
                setFilters((prev) => {
                  const nextQuick = prev.quickFilter === 'overdue' ? 'all' : 'overdue';
                  return {
                    ...prev,
                    quickFilter: nextQuick,
                    status: nextQuick === 'overdue' && prev.status === 'Completado' ? 'all' : prev.status,
                  };
                });
              }}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap border transition-all cursor-pointer ${
                filters.quickFilter === 'overdue'
                  ? 'bg-rose-600 text-white border-rose-600 shadow-xs ring-2 ring-rose-500/30'
                  : 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-900/60 hover:bg-rose-100'
              }`}
            >
              <AlertTriangle className="w-3.5 h-3.5" />
              <span>Vencidas ({overdueCount})</span>
            </button>

            <button
              onClick={() => setFilters((prev) => ({ ...prev, quickFilter: prev.quickFilter === 'this_week' ? 'all' : 'this_week' }))}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap border transition-all ${
                filters.quickFilter === 'this_week'
                  ? 'bg-amber-600 text-white border-amber-600 shadow-xs'
                  : 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-900/60 hover:bg-amber-100'
              }`}
            >
              <Clock className="w-3.5 h-3.5" />
              <span>Esta Semana ({thisWeekCount})</span>
            </button>

            <button
              onClick={() => setFilters((prev) => ({ ...prev, quickFilter: prev.quickFilter === 'critical' ? 'all' : 'critical' }))}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap border transition-all ${
                filters.quickFilter === 'critical'
                  ? 'bg-red-700 text-white border-red-700 shadow-xs'
                  : 'bg-red-50 dark:bg-red-950/40 text-red-700 dark:text-red-300 border-red-200 dark:border-red-900/60 hover:bg-red-100'
              }`}
            >
              <Flame className="w-3.5 h-3.5" />
              <span>Críticas ({criticalCount})</span>
            </button>
          </div>
        </div>

        {/* Row 2: Secondary Dropdown Filters */}
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-2.5 items-center">
          {/* Responsable */}
          <div>
            <label className="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Responsable
            </label>
            <select
              value={filters.collaboratorId}
              onChange={(e) => setFilters((prev) => ({ ...prev, collaboratorId: e.target.value }))}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 focus:outline-hidden truncate"
            >
              <option value="all">Todos los integrantes</option>
              {collaborators.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} ({c.initials})
                </option>
              ))}
            </select>
          </div>

          {/* Categoría / Dominio */}
          <div>
            <label className="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Categoría / Dominio
            </label>
            <select
              value={filters.domain}
              onChange={(e) => setFilters((prev) => ({ ...prev, domain: e.target.value }))}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 focus:outline-hidden truncate"
            >
              <option value="all">Todos los dominios</option>
              {DOMAINS.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </div>

          {/* Prioridad */}
          <div>
            <label className="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Prioridad
            </label>
            <select
              value={filters.priority}
              onChange={(e) => setFilters((prev) => ({ ...prev, priority: e.target.value }))}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 focus:outline-hidden truncate"
            >
              <option value="all">Todas las prioridades</option>
              {PRIORITIES.map((p) => (
                <option key={p} value={p}>
                  {p}
                </option>
              ))}
            </select>
          </div>

          {/* Estado */}
          <div>
            <label className="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Estado
            </label>
            <select
              value={filters.status}
              onChange={(e) => setFilters((prev) => ({ ...prev, status: e.target.value }))}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 focus:outline-hidden truncate"
            >
              <option value="all">Todos los estados</option>
              {STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>

          {/* Empresa / Unidad */}
          <div>
            <label className="block text-[11px] font-semibold text-slate-600 dark:text-slate-400 mb-1">
              Empresa / Unidad
            </label>
            <select
              value={filters.companyUnit}
              onChange={(e) => setFilters((prev) => ({ ...prev, companyUnit: e.target.value }))}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 focus:outline-hidden truncate"
            >
              <option value="all">Todas</option>
              {COMPANIES.map((co) => (
                <option key={co} value={co}>
                  {co}
                </option>
              ))}
            </select>
          </div>

          {/* Limpiar Filtros */}
          <div className="flex items-end">
            <button
              onClick={handleResetFilters}
              disabled={!hasActiveFilters}
              className={`w-full text-xs py-1.5 px-3 rounded-lg border font-medium flex items-center justify-center gap-1.5 transition-all ${
                hasActiveFilters
                  ? 'border-indigo-300 dark:border-indigo-800 bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100 cursor-pointer'
                  : 'border-slate-200 dark:border-slate-700 text-slate-400 dark:text-slate-600 bg-slate-50 dark:bg-slate-800/40 cursor-not-allowed'
              }`}
            >
              <X className="w-3.5 h-3.5" />
              <span>Limpiar</span>
            </button>
          </div>
        </div>

        {/* Counter Info Line */}
        <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400 pt-0.5">
          <div className="flex items-center gap-1.5 font-medium">
            <span>Mostrando</span>
            <span className="font-bold text-slate-900 dark:text-white">{filteredCount}</span>
            <span>de</span>
            <span className="font-bold text-slate-900 dark:text-white">{allTasks.length}</span>
            <span>tareas filtradas</span>
            {hasActiveFilters && (
              <span className="inline-flex items-center gap-1 ml-2 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300">
                <Filter className="w-2.5 h-2.5" /> Filtro activo
              </span>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
