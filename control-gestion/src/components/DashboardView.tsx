import React from 'react';
import { 
  CheckCircle2, 
  AlertOctagon, 
  Clock3, 
  Users2, 
  TrendingUp, 
  ArrowUpRight, 
  AlertTriangle, 
  Calendar, 
  ShieldAlert,
  ChevronRight
} from 'lucide-react';
import { Collaborator, KPIData, Task } from '../types';
import { CollaboratorWorkload, isTaskOverdue } from '../utils/metrics';

interface DashboardViewProps {
  kpis: KPIData;
  workload: CollaboratorWorkload[];
  tasks: Task[];
  collaborators: Collaborator[];
  cutoffDate: string;
  onSelectCollaborator: (collaboratorId: string) => void;
  onSelectDomain: (domain: string) => void;
  onSelectPriority: (priority: string) => void;
  onGoToMatrix: () => void;
  onUpdateTaskStatus: (taskId: string, newStatus: Task['status']) => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({
  kpis,
  workload,
  tasks,
  collaborators,
  cutoffDate,
  onSelectCollaborator,
  onSelectDomain,
  onSelectPriority,
  onGoToMatrix,
  onUpdateTaskStatus,
}) => {
  // Overdue and critical tasks
  const criticalOverdueCount = tasks.filter((t) => t.priority === 'Crítica' && isTaskOverdue(t, cutoffDate)).length;
  const urgentTasks = tasks
    .filter((t) => isTaskOverdue(t, cutoffDate) || (t.priority === 'Crítica' && t.status !== 'Completado'))
    .slice(0, 5);

  // Group by domain
  const domainStats = [
    'Windows',
    'IBMi',
    'Documentación',
    'PCI',
    'Auditoria Interna',
    'Auditoria Externa',
  ].map((d) => {
    const domainTasks = tasks.filter((t) => t.domain === d);
    const completed = domainTasks.filter((t) => t.status === 'Completado').length;
    const delayed = domainTasks.filter((t) => isTaskOverdue(t, cutoffDate)).length;
    return {
      domain: d,
      total: domainTasks.length,
      completed,
      delayed,
      rate: domainTasks.length > 0 ? Math.round((completed / domainTasks.length) * 100) : 0,
    };
  }).filter((d) => d.total > 0);

  // Priority breakdown
  const priorityStats = [
    { label: 'Crítica', color: 'bg-rose-500', text: 'text-rose-600 dark:text-rose-400', count: tasks.filter(t => t.priority === 'Crítica').length },
    { label: 'Alta', color: 'bg-amber-500', text: 'text-amber-600 dark:text-amber-400', count: tasks.filter(t => t.priority === 'Alta').length },
    { label: 'Media', color: 'bg-sky-500', text: 'text-sky-600 dark:text-sky-400', count: tasks.filter(t => t.priority === 'Media').length },
    { label: 'Baja', color: 'bg-emerald-500', text: 'text-emerald-600 dark:text-emerald-400', count: tasks.filter(t => t.priority === 'Baja').length },
  ];

  return (
    <div className="space-y-6">
      {/* Executive Summary Banner */}
      <div className="bg-gradient-to-r from-indigo-900 via-indigo-800 to-slate-900 rounded-2xl p-5 text-white shadow-md relative overflow-hidden">
        <div className="absolute right-0 top-0 w-96 h-full opacity-10 pointer-events-none flex items-center justify-end pr-10">
          <ShieldAlert className="w-64 h-64 text-white" />
        </div>
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full text-xs font-semibold bg-indigo-500/30 border border-indigo-400/30 mb-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
              Corte Oficial de Operaciones: {cutoffDate}
            </div>
            <h2 className="text-xl font-bold tracking-tight text-white">
              Panel de Rendimiento Operativo y Gobernanza de Seguridad
            </h2>
            <p className="text-xs sm:text-sm text-indigo-200 mt-1 max-w-2xl">
              Monitoreo analítico de cumplimiento de actividades, horas de esfuerzo invertidas y balance de carga de trabajo por colaborador.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={onGoToMatrix}
              className="px-4 py-2 bg-white text-indigo-900 hover:bg-indigo-50 font-semibold rounded-xl text-xs sm:text-sm shadow-sm transition-all flex items-center gap-1.5"
            >
              <span>Ir a la Matriz de Tareas</span>
              <ArrowUpRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* 4 Core KPIs requested explicitly by the user */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1: Tareas Completadas */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Tareas Completadas
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900 dark:text-white">
              {kpis.completedTasks}
            </span>
            <span className="text-sm font-semibold text-slate-500 dark:text-slate-400">
              / {kpis.totalTasks} tareas
            </span>
          </div>
          {/* Progress Bar */}
          <div className="mt-3">
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="text-slate-600 dark:text-slate-400 font-medium">Tasa de Cumplimiento</span>
              <span className="font-bold text-emerald-600 dark:text-emerald-400">{kpis.completedRate}%</span>
            </div>
            <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                style={{ width: `${kpis.completedRate}%` }}
              ></div>
            </div>
          </div>
          <div className="mt-3 flex items-center gap-1.5 text-xs text-emerald-600 dark:text-emerald-400 font-medium">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>+8% respecto a la quincena anterior</span>
          </div>
        </div>

        {/* KPI 2: Tasa de Retraso */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs hover:border-rose-300 dark:hover:border-rose-700 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Tasa de Retraso
            </span>
            <div className="w-9 h-9 rounded-xl bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <AlertOctagon className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-rose-600 dark:text-rose-400">
              {kpis.delayRate}%
            </span>
            <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-rose-50 dark:bg-rose-950/80 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900/60">
              {kpis.delayedTasks} {kpis.delayedTasks === 1 ? 'vencida' : 'vencidas'}
            </span>
          </div>
          {/* Progress Bar */}
          <div className="mt-3">
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="text-slate-600 dark:text-slate-400 font-medium">Sobre Tareas Activas</span>
              <span className="font-bold text-rose-600 dark:text-rose-400">
                {kpis.delayedTasks} de {kpis.totalTasks - kpis.completedTasks}
              </span>
            </div>
            <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className="h-full bg-rose-500 rounded-full transition-all duration-500"
                style={{ width: `${Math.min(kpis.delayRate, 100)}%` }}
              ></div>
            </div>
          </div>
          <div className="mt-3 flex items-center gap-1.5 text-xs text-rose-600 dark:text-rose-400 font-medium">
            <AlertTriangle className="w-3.5 h-3.5" />
            <span>
              {criticalOverdueCount > 0
                ? `Atención: ${criticalOverdueCount} ${criticalOverdueCount === 1 ? 'crítica' : 'críticas'} con fecha vencida`
                : 'Sin actividades críticas vencidas'}
            </span>
          </div>
        </div>

        {/* KPI 3: Horas Invertidas */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Horas Invertidas
            </span>
            <div className="w-9 h-9 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <Clock3 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900 dark:text-white">
              {kpis.totalHoursInvested}h
            </span>
            <span className="text-sm font-semibold text-slate-500 dark:text-slate-400">
              de {kpis.totalHoursEstimated}h est.
            </span>
          </div>
          {/* Utilization Bar */}
          <div className="mt-3">
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="text-slate-600 dark:text-slate-400 font-medium">Consumo de Presupuesto</span>
              <span className="font-bold text-indigo-600 dark:text-indigo-400">{kpis.hoursUtilizationRate}%</span>
            </div>
            <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className="h-full bg-indigo-600 rounded-full transition-all duration-500"
                style={{ width: `${Math.min(kpis.hoursUtilizationRate, 100)}%` }}
              ></div>
            </div>
          </div>
          <div className="mt-3 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
            <span>Promedio por tarea:</span>
            <span className="font-semibold text-slate-800 dark:text-slate-200">{kpis.averageHoursPerTask} hrs</span>
          </div>
        </div>

        {/* KPI 4: Carga de Trabajo por Colaborador */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Carga de Trabajo
            </span>
            <div className="w-9 h-9 rounded-xl bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <Users2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900 dark:text-white">
              {collaborators.length}
            </span>
            <span className="text-sm font-semibold text-slate-500 dark:text-slate-400">
              colaboradores
            </span>
          </div>
          {/* Overload status badge */}
          <div className="mt-3">
            <div className="flex items-center justify-between text-xs mb-1">
              <span className="text-slate-600 dark:text-slate-400 font-medium">Equilibrio de Asignación</span>
              <span className={`font-bold ${kpis.overloadedMembersCount > 0 ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-600'}`}>
                {kpis.overloadedMembersCount > 0 ? `${kpis.overloadedMembersCount} en sobrecarga` : 'Balance óptimo'}
              </span>
            </div>
            <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className={`h-full rounded-full transition-all duration-500 ${
                  kpis.overloadedMembersCount > 0 ? 'bg-amber-500' : 'bg-emerald-500'
                }`}
                style={{ width: `${Math.min((collaborators.length - kpis.overloadedMembersCount) / (collaborators.length || 1) * 100, 100)}%` }}
              ></div>
            </div>
          </div>
          <div className="mt-3 text-xs text-slate-500 dark:text-slate-400">
            Capacidad total quincenal: <span className="font-semibold text-slate-800 dark:text-slate-200">470 hrs</span>
          </div>
        </div>
      </div>

      {/* Row 2: Deep Workload Distribution + Domain Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Workload by Collaborator (Detailed Data View) */}
        <div className="lg:col-span-2 bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <Users2 className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
                Carga de Trabajo y Horas por Colaborador
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Horas invertidas vs asignadas, capacidad utilizada y tareas en riesgo
              </p>
            </div>
            <span className="text-[11px] font-medium text-slate-400">
              Sprint quincenal
            </span>
          </div>

          <div className="space-y-3.5">
            {workload.map((w) => {
              const isOverloaded = w.utilizationPct > 100;
              const isHigh = w.utilizationPct >= 75 && w.utilizationPct <= 100;
              const memberTasks = tasks.filter((t) => t.collaboratorId === w.collaborator.id);
              const memberDomains = Array.from(new Set(memberTasks.map((t) => t.domain)));

              return (
                <div
                  key={w.collaborator.id}
                  onClick={() => onSelectCollaborator(w.collaborator.id)}
                  className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 bg-slate-50/50 dark:bg-slate-800/40 hover:bg-white dark:hover:bg-slate-800 cursor-pointer transition-all"
                >
                  <div className="flex items-center justify-between gap-3 mb-2">
                    <div className="flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center text-xs font-bold ring-2 ring-indigo-500/20">
                        {w.collaborator.initials}
                      </div>
                      <div>
                        <div className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                          {w.collaborator.name}
                          {isOverloaded && (
                            <span className="text-[10px] px-1.5 py-0.2 rounded-md bg-rose-100 dark:bg-rose-950 text-rose-700 dark:text-rose-300 font-semibold">
                              Sobrecarga
                            </span>
                          )}
                        </div>
                        <div className="text-[11px] text-slate-500 dark:text-slate-400">
                          {memberDomains.length > 0
                            ? `Dominio: ${memberDomains.join(', ')}`
                            : 'Sin dominio asignado'}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-4 text-right">
                      <div>
                        <div className="text-xs font-bold text-slate-900 dark:text-white">
                          {w.hoursInvested}h <span className="text-slate-400 font-normal">/ {w.hoursEstimated}h</span>
                        </div>
                        <div className="text-[10px] text-slate-500">
                          {w.totalTasks} tareas ({w.completedTasks} compl.)
                        </div>
                      </div>

                      <div className="min-w-[60px] text-right">
                        <span className={`text-xs font-extrabold ${
                          isOverloaded ? 'text-rose-600 dark:text-rose-400' : isHigh ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-600 dark:text-emerald-400'
                        }`}>
                          {w.utilizationPct}%
                        </span>
                        <div className="text-[10px] text-slate-400">capacidad</div>
                      </div>
                    </div>
                  </div>

                  {/* Visual Progress Bar */}
                  <div className="w-full h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${
                        isOverloaded
                          ? 'bg-rose-500'
                          : isHigh
                          ? 'bg-amber-500'
                          : 'bg-indigo-600'
                      }`}
                      style={{ width: `${Math.min(w.utilizationPct, 100)}%` }}
                    ></div>
                  </div>

                  {/* Sub-pills: Overdue or Critical indicators */}
                  {(w.delayedTasks > 0 || w.criticalTasks > 0) && (
                    <div className="flex items-center gap-2 mt-2 pt-1 border-t border-slate-200 dark:border-slate-700/60 text-[10px]">
                      {w.delayedTasks > 0 && (
                        <span className="flex items-center gap-1 text-rose-600 dark:text-rose-400 font-semibold">
                          <AlertTriangle className="w-3 h-3" />
                          {w.delayedTasks} {w.delayedTasks === 1 ? 'tarea con retraso' : 'tareas con retraso'}
                        </span>
                      )}
                      {w.criticalTasks > 0 && (
                        <span className="flex items-center gap-1 text-amber-600 dark:text-amber-400 font-medium">
                          <ShieldAlert className="w-3 h-3" />
                          {w.criticalTasks} {w.criticalTasks === 1 ? 'crítica pendiente' : 'críticas pendientes'}
                        </span>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column: Priority & Domain Breakdown */}
        <div className="space-y-6">
          {/* Priority Breakdown */}
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs">
            <h3 className="text-sm font-bold text-slate-900 dark:text-white mb-3 flex items-center justify-between">
              <span>Distribución por Prioridad</span>
              <span className="text-xs text-slate-400 font-normal">{tasks.length} total</span>
            </h3>

            <div className="grid grid-cols-2 gap-2.5">
              {priorityStats.map((p) => (
                <button
                  key={p.label}
                  onClick={() => onSelectPriority(p.label)}
                  className="p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 hover:border-indigo-400 text-left transition-all"
                >
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold text-slate-600 dark:text-slate-300">
                      {p.label}
                    </span>
                    <span className={`w-2 h-2 rounded-full ${p.color}`}></span>
                  </div>
                  <div className={`text-xl font-extrabold mt-1.5 ${p.text}`}>
                    {p.count}
                  </div>
                  <div className="text-[10px] text-slate-400">
                    {Math.round((p.count / (tasks.length || 1)) * 100)}% del total
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Domain Performance */}
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs">
            <h3 className="text-sm font-bold text-slate-900 dark:text-white mb-3">
              Rendimiento por Dominio
            </h3>
            <div className="space-y-2.5">
              {domainStats.map((d) => (
                <div
                  key={d.domain}
                  onClick={() => onSelectDomain(d.domain)}
                  className="group cursor-pointer"
                >
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="font-medium text-slate-700 dark:text-slate-300 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors truncate max-w-[200px]">
                      {d.domain}
                    </span>
                    <span className="font-bold text-slate-900 dark:text-white text-[11px]">
                      {d.completed}/{d.total} ({d.rate}%)
                    </span>
                  </div>
                  <div className="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-indigo-600 rounded-full group-hover:bg-indigo-500 transition-all"
                      style={{ width: `${d.rate}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Row 3: Actionable Urgent & Delayed Task Matrix Preview */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-lg bg-rose-100 dark:bg-rose-950 text-rose-600">
              <AlertOctagon className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-white">
                Atención Requerida: Tareas Vencidas o de Prioridad Crítica
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Acción directa e inmediata para regularizar SLAs operativos
              </p>
            </div>
          </div>

          <button
            onClick={onGoToMatrix}
            className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 flex items-center gap-1"
          >
            <span>Ver matriz completa</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="divide-y divide-slate-100 dark:divide-slate-800">
          {urgentTasks.length === 0 ? (
            <div className="py-6 text-center text-xs text-slate-400">
              {tasks.length === 0
                ? 'Base de datos limpia: No hay actividades registradas aún. Haz clic en "+ Nueva Tarea" para comenzar.'
                : 'No hay tareas urgentes o vencidas en este momento. ¡Excelente trabajo del equipo!'}
            </div>
          ) : (
            urgentTasks.map((t) => {
              const isOver = isTaskOverdue(t, cutoffDate);
              const collab = collaborators.find((c) => c.id === t.collaboratorId);

              return (
                <div key={t.id} className="py-3 flex flex-col md:flex-row md:items-center justify-between gap-3 hover:bg-slate-50/50 dark:hover:bg-slate-800/30 px-2 rounded-xl transition-all">
                  <div className="flex items-start gap-3">
                    <span className={`text-[10px] px-2 py-0.5 rounded-md font-bold mt-0.5 ${
                      t.priority === 'Crítica'
                        ? 'bg-rose-100 dark:bg-rose-950 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900'
                        : 'bg-amber-100 dark:bg-amber-950 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-900'
                    }`}>
                      {t.priority}
                    </span>
                    <div>
                      <div className="text-xs font-bold text-slate-900 dark:text-white">
                        {t.title}
                      </div>
                      <div className="text-[11px] text-slate-500 dark:text-slate-400 flex items-center gap-3 mt-0.5">
                        <span>Dominio: {t.domain}</span>
                        <span>•</span>
                        <span>Responsable: {collab?.name || 'Sin asignar'}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 self-end md:self-auto">
                    {/* Date badge */}
                    <div className={`flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-lg ${
                      isOver
                        ? 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900'
                        : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300'
                    }`}>
                      <Calendar className="w-3.5 h-3.5" />
                      <span>{t.nextFollowUpDate}</span>
                      {isOver && <span className="text-[10px] font-bold">⚠️ Vencida</span>}
                    </div>

                    {/* Fast Inline Status Selector */}
                    <select
                      value={t.status}
                      onChange={(e) => onUpdateTaskStatus(t.id, e.target.value as Task['status'])}
                      className={`text-xs font-semibold px-2.5 py-1 rounded-lg border focus:ring-1 focus:ring-indigo-500 focus:outline-hidden ${
                        t.status === 'Completado'
                          ? 'bg-emerald-50 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300 border-emerald-300 dark:border-emerald-800'
                          : t.status === 'En Proceso'
                          ? 'bg-blue-50 dark:bg-blue-950 text-blue-700 dark:text-blue-300 border-blue-300 dark:border-blue-800'
                          : 'bg-amber-50 dark:bg-amber-950 text-amber-700 dark:text-amber-300 border-amber-300 dark:border-amber-800'
                      }`}
                    >
                      <option value="Pendiente">Pendiente</option>
                      <option value="En Proceso">En Proceso</option>
                      <option value="En Revisión">En Revisión</option>
                      <option value="Completado">Completado</option>
                      <option value="Bloqueado">Bloqueado</option>
                    </select>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
