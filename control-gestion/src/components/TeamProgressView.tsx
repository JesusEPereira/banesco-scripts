import React from 'react';
import { 
  Users, 
  CheckCircle2, 
  AlertTriangle, 
  Clock, 
  ShieldAlert, 
  Briefcase, 
  ChevronRight,
  TrendingUp,
  Activity
} from 'lucide-react';
import { Collaborator, Task, TaskStatus } from '../types';
import { CollaboratorWorkload, isTaskOverdue } from '../utils/metrics';

interface TeamProgressViewProps {
  workload: CollaboratorWorkload[];
  tasks: Task[];
  collaborators: Collaborator[];
  cutoffDate: string;
  onEditTask: (task: Task) => void;
  onUpdateTaskStatus: (taskId: string, newStatus: TaskStatus) => void;
}

export const TeamProgressView: React.FC<TeamProgressViewProps> = ({
  workload,
  tasks,
  cutoffDate,
  onEditTask,
  onUpdateTaskStatus,
}) => {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-white">
          Análisis de Rendimiento y Carga de Trabajo por Colaborador
        </h2>
        <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-0.5">
          Balance de esfuerzo humano, cumplimiento de SLAs y prevención de sobrecarga operativa
        </p>
      </div>

      {/* Team Capacity Health Metric Banner */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-indigo-50 dark:bg-indigo-950 text-indigo-600 flex items-center justify-center shrink-0">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">Colaboradores Activos</div>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">{workload.length} especialistas</div>
            <div className="text-[11px] text-indigo-600 font-medium mt-0.5">100% asignados a proyectos y actividades</div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-50 dark:bg-emerald-950 text-emerald-600 flex items-center justify-center shrink-0">
            <Activity className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">Capacidad Promedio del Equipo</div>
            <div className="text-2xl font-bold text-emerald-600">
              {Math.round(workload.reduce((acc, w) => acc + w.utilizationPct, 0) / (workload.length || 1))}%
            </div>
            <div className="text-[11px] text-slate-500 mt-0.5">Rango saludable establecido: 70% - 95%</div>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-4 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-50 dark:bg-amber-950 text-amber-600 flex items-center justify-center shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div>
            <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">Alertas de Capacidad & Retraso</div>
            <div className="text-2xl font-bold text-amber-600">
              {workload.reduce((acc, w) => acc + w.delayedTasks, 0)} tareas
            </div>
            <div className="text-[11px] text-amber-700 dark:text-amber-400 font-medium mt-0.5">
              Requieren seguimiento en comités de control
            </div>
          </div>
        </div>
      </div>

      {/* Collaborators Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {workload.map((w) => {
          const isOverloaded = w.utilizationPct > 100;
          const memberTasks = tasks.filter((t) => t.collaboratorId === w.collaborator.id);
          const activeMemberTasks = memberTasks.filter((t) => t.status !== 'Completado');

          return (
            <div
              key={w.collaborator.id}
              className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-5 shadow-xs flex flex-col justify-between"
            >
              <div>
                {/* Header */}
                <div className="flex items-start justify-between gap-3 mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center font-bold text-sm ring-2 ring-indigo-500/20">
                      {w.collaborator.initials}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 dark:text-white text-sm">
                        {w.collaborator.name}
                      </h3>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400">
                        {Array.from(new Set(memberTasks.map((t) => t.domain))).length > 0
                          ? `Dominio: ${Array.from(new Set(memberTasks.map((t) => t.domain))).join(', ')}`
                          : 'Sin dominio asignado'}
                      </p>
                    </div>
                  </div>

                  <span className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                    isOverloaded
                      ? 'bg-rose-100 dark:bg-rose-950 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-900'
                      : w.utilizationPct >= 75
                      ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800'
                      : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'
                  }`}>
                    {isOverloaded ? 'Sobrecargado' : `${w.utilizationPct}% Cap.`}
                  </span>
                </div>

                {/* KPI Metrics Mini-Grid */}
                <div className="grid grid-cols-3 gap-2 py-3 border-y border-slate-100 dark:border-slate-800 text-center">
                  <div>
                    <div className="text-[10px] text-slate-500 dark:text-slate-400">Total Tareas</div>
                    <div className="text-base font-bold text-slate-900 dark:text-white">
                      {w.totalTasks}
                    </div>
                    <div className="text-[9px] text-emerald-600 font-medium">
                      {w.completedTasks} completadas
                    </div>
                  </div>

                  <div>
                    <div className="text-[10px] text-slate-500 dark:text-slate-400">Horas Reales</div>
                    <div className="text-base font-bold text-slate-900 dark:text-white">
                      {w.hoursInvested}h
                    </div>
                    <div className="text-[9px] text-slate-400">
                      de {w.hoursEstimated}h est.
                    </div>
                  </div>

                  <div>
                    <div className="text-[10px] text-slate-500 dark:text-slate-400">Tasa Retraso</div>
                    <div className={`text-base font-bold ${w.delayedTasks > 0 ? 'text-rose-600 dark:text-rose-400' : 'text-slate-900 dark:text-white'}`}>
                      {w.activeTasks > 0 ? Math.round((w.delayedTasks / w.activeTasks) * 100) : 0}%
                    </div>
                    <div className="text-[9px] text-slate-400">
                      {w.delayedTasks} {w.delayedTasks === 1 ? 'vencida' : 'vencidas'}
                    </div>
                  </div>
                </div>

                {/* Capacity Progress Bar */}
                <div className="py-3">
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-500 dark:text-slate-400">Uso de Capacidad Quincenal</span>
                    <span className="font-bold text-slate-800 dark:text-slate-200">{w.hoursInvested} / {w.collaborator.weeklyCapacityHours * 2} hrs</span>
                  </div>
                  <div className="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${
                        isOverloaded ? 'bg-rose-500' : w.utilizationPct >= 75 ? 'bg-amber-500' : 'bg-indigo-600'
                      }`}
                      style={{ width: `${Math.min(w.utilizationPct, 100)}%` }}
                    ></div>
                  </div>
                </div>

                {/* Active Tasks Assigned */}
                <div className="pt-1">
                  <span className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-2">
                    Actividades Asignadas Activas ({activeMemberTasks.length})
                  </span>

                  <div className="space-y-2">
                    {activeMemberTasks.slice(0, 3).map((task) => {
                      const isOver = isTaskOverdue(task, cutoffDate);

                      return (
                        <div
                          key={task.id}
                          className="p-2.5 rounded-xl border border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40 hover:bg-slate-100 dark:hover:bg-slate-800 transition-all text-xs"
                        >
                          <div className="flex items-start justify-between gap-2">
                            <span
                              onClick={() => onEditTask(task)}
                              className="font-medium text-slate-900 dark:text-white hover:text-indigo-600 cursor-pointer line-clamp-1"
                            >
                              {task.title}
                            </span>
                            <span className={`text-[10px] px-1.5 py-0.2 rounded-md font-bold shrink-0 ${
                              task.priority === 'Crítica'
                                ? 'bg-rose-100 text-rose-700'
                                : 'bg-slate-200 text-slate-700'
                            }`}>
                              {task.priority}
                            </span>
                          </div>

                          <div className="flex items-center justify-between mt-1.5 text-[10px] text-slate-500">
                            <span className={isOver ? 'text-rose-600 font-bold' : ''}>
                              {isOver ? '⚠️ ' : ''}{task.nextFollowUpDate}
                            </span>

                            <select
                              value={task.status}
                              onChange={(e) => onUpdateTaskStatus(task.id, e.target.value as TaskStatus)}
                              className="bg-transparent font-semibold text-indigo-600 dark:text-indigo-400 hover:underline cursor-pointer focus:outline-hidden"
                            >
                              <option value="Pendiente">Pendiente</option>
                              <option value="En Proceso">En Proceso</option>
                              <option value="En Revisión">En Revisión</option>
                              <option value="Completado">Completado</option>
                            </select>
                          </div>
                        </div>
                      );
                    })}

                    {activeMemberTasks.length > 3 && (
                      <div className="text-[11px] text-center text-slate-400 pt-1">
                        + {activeMemberTasks.length - 3} actividades más
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
