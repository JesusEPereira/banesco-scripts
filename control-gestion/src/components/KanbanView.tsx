import React from 'react';
import { Plus, AlertTriangle, Building2, ChevronRight, ChevronLeft } from 'lucide-react';
import { Collaborator, Task, TaskStatus } from '../types';
import { isTaskOverdue } from '../utils/metrics';

interface KanbanViewProps {
  tasks: Task[];
  collaborators: Collaborator[];
  cutoffDate: string;
  onUpdateTaskStatus: (taskId: string, newStatus: TaskStatus) => void;
  onEditTask: (task: Task) => void;
  onOpenNewTaskModal: () => void;
}

const COLUMNS: { status: TaskStatus; label: string; color: string; border: string }[] = [
  { status: 'Pendiente', label: 'Pendiente', color: 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300', border: 'border-slate-300 dark:border-slate-700' },
  { status: 'En Proceso', label: 'En Proceso', color: 'bg-blue-50 dark:bg-blue-950/60 text-blue-700 dark:text-blue-300', border: 'border-blue-300 dark:border-blue-800' },
  { status: 'En Revisión', label: 'En Revisión', color: 'bg-purple-50 dark:bg-purple-950/60 text-purple-700 dark:text-purple-300', border: 'border-purple-300 dark:border-purple-800' },
  { status: 'Completado', label: 'Completado', color: 'bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300', border: 'border-emerald-300 dark:border-emerald-800' },
];

export const KanbanView: React.FC<KanbanViewProps> = ({
  tasks,
  collaborators,
  cutoffDate,
  onUpdateTaskStatus,
  onEditTask,
  onOpenNewTaskModal,
}) => {
  const getCollab = (id: string) => collaborators.find((c) => c.id === id);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-white">
            Tablero Kanban de Flujo Operativo
          </h2>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-0.5">
            Arrastra mentalmente y transiciona actividades entre estados en tiempo real
          </p>
        </div>

        <button
          onClick={onOpenNewTaskModal}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-xs"
        >
          <Plus className="w-4 h-4" />
          <span>Nueva Tarea</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-start">
        {COLUMNS.map((col) => {
          const colTasks = tasks.filter((t) => t.status === col.status);

          return (
            <div
              key={col.status}
              className="bg-slate-100/70 dark:bg-slate-900/60 rounded-2xl p-3 border border-slate-200 dark:border-slate-800 flex flex-col min-h-[550px]"
            >
              {/* Column Header */}
              <div className="flex items-center justify-between pb-3 px-1 mb-2 border-b border-slate-200 dark:border-slate-800">
                <div className="flex items-center gap-2">
                  <span className={`px-2.5 py-1 rounded-lg text-xs font-bold ${col.color}`}>
                    {col.label}
                  </span>
                  <span className="text-xs font-bold text-slate-500">
                    ({colTasks.length})
                  </span>
                </div>
              </div>

              {/* Tasks List */}
              <div className="space-y-3 flex-1 overflow-y-auto max-h-[750px] pr-1">
                {colTasks.length === 0 ? (
                  <div className="text-center py-10 text-xs text-slate-400">
                    No hay tareas en esta fase
                  </div>
                ) : (
                  colTasks.map((task) => {
                    const collab = getCollab(task.collaboratorId);
                    const isOverdue = isTaskOverdue(task, cutoffDate);

                    return (
                      <div
                        key={task.id}
                        className="bg-white dark:bg-slate-800 rounded-xl p-3.5 border border-slate-200 dark:border-slate-700/80 shadow-xs hover:shadow-md transition-all group"
                      >
                        {/* Tags */}
                        <div className="flex items-center justify-between gap-1 mb-2">
                          <div className="flex items-center gap-1.5">
                            <span className={`text-[10px] px-1.5 py-0.2 rounded-md font-semibold ${
                              task.type === 'Proyecto'
                                ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800'
                                : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                            }`}>
                              {task.type}
                            </span>
                            {task.companyUnit && (
                              <span className="text-[10px] px-1.5 py-0.2 rounded-md bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 flex items-center gap-0.5">
                                <Building2 className="w-2.5 h-2.5" />
                                {task.companyUnit}
                              </span>
                            )}
                          </div>

                          <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
                            task.priority === 'Crítica'
                              ? 'bg-rose-100 dark:bg-rose-950 text-rose-700 dark:text-rose-300'
                              : task.priority === 'Alta'
                              ? 'bg-amber-100 dark:bg-amber-950 text-amber-800 dark:text-amber-300'
                              : 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                          }`}>
                            {task.priority}
                          </span>
                        </div>

                        {/* Title */}
                        <h4
                          onClick={() => onEditTask(task)}
                          className="text-xs font-bold text-slate-900 dark:text-white hover:text-indigo-600 cursor-pointer line-clamp-2 mb-2 leading-snug"
                        >
                          {task.title}
                        </h4>

                        {/* Domain */}
                        <div className="text-[11px] text-slate-500 dark:text-slate-400 mb-3 truncate">
                          {task.domain}
                        </div>

                        {/* Due Date & Hours */}
                        <div className="flex items-center justify-between text-xs pt-2 border-t border-slate-100 dark:border-slate-700/60 mb-1.5">
                          <span className={`flex items-center gap-1 font-medium ${
                            isOverdue
                              ? 'text-rose-600 dark:text-rose-400 font-bold'
                              : 'text-slate-500 dark:text-slate-400'
                          }`}>
                            {isOverdue && <AlertTriangle className="w-3 h-3 text-rose-600" />}
                            {task.nextFollowUpDate}
                          </span>

                          <span className="text-slate-600 dark:text-slate-300 font-semibold text-[11px]">
                            {task.hoursInvested}h / {task.hoursEstimated}h
                          </span>
                        </div>

                        {/* Hours Progress Bar */}
                        <div className="w-full h-1.5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden mb-2">
                          <div
                            className={`h-full rounded-full transition-all duration-300 ${
                              task.status === 'Completado'
                                ? 'bg-emerald-500'
                                : task.status === 'En Proceso'
                                ? 'bg-blue-600'
                                : 'bg-indigo-500'
                            }`}
                            style={{ width: `${Math.min(100, Math.round((task.hoursInvested / (task.hoursEstimated || 1)) * 100))}%` }}
                          ></div>
                        </div>

                        {/* Footer: Assignee + Move Column Shortcuts */}
                        <div className="flex items-center justify-between pt-1">
                          <div className="flex items-center gap-1.5">
                            <div className="w-5 h-5 rounded-full bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center text-[9px] font-bold">
                              {collab?.initials || '??'}
                            </div>
                            <span className="text-[11px] text-slate-600 dark:text-slate-400 font-medium truncate max-w-[100px]">
                              {collab?.name || 'Sin asignar'}
                            </span>
                          </div>

                          {/* Quick transition arrows */}
                          <div className="flex items-center gap-1">
                            {col.status !== 'Pendiente' && (
                              <button
                                onClick={() => {
                                  const prevStatus: Record<TaskStatus, TaskStatus> = {
                                    'Completado': 'En Revisión',
                                    'En Revisión': 'En Proceso',
                                    'En Proceso': 'Pendiente',
                                    'Bloqueado': 'Pendiente',
                                    'Pendiente': 'Pendiente',
                                  };
                                  onUpdateTaskStatus(task.id, prevStatus[task.status]);
                                }}
                                className="p-1 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-400 hover:text-slate-700"
                                title="Mover a etapa anterior"
                              >
                                <ChevronLeft className="w-3.5 h-3.5" />
                              </button>
                            )}

                            {col.status !== 'Completado' && (
                              <button
                                onClick={() => {
                                  const nextStatus: Record<TaskStatus, TaskStatus> = {
                                    'Pendiente': 'En Proceso',
                                    'En Proceso': 'En Revisión',
                                    'En Revisión': 'Completado',
                                    'Bloqueado': 'En Proceso',
                                    'Completado': 'Completado',
                                  };
                                  onUpdateTaskStatus(task.id, nextStatus[task.status]);
                                }}
                                className="p-1 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-400 hover:text-slate-700"
                                title="Mover a siguiente etapa"
                              >
                                <ChevronRight className="w-3.5 h-3.5" />
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
