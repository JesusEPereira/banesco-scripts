import React, { useState, useMemo } from 'react';
import { 
  ChevronDown, 
  ChevronRight, 
  AlertTriangle, 
  Plus, 
  Pencil, 
  Trash2, 
  RotateCcw, 
  Search, 
  Filter, 
  ArrowUpDown, 
  CheckSquare, 
  Square, 
  Building2, 
  CheckCircle2, 
  Clock, 
  X,
  FileText,
  FolderPlus,
  Mail,
  ExternalLink,
  Send
} from 'lucide-react';
import { Collaborator, Domain, Priority, Task, TaskStatus } from '../types';
import { isTaskOverdue } from '../utils/metrics';
import { CORPORATE_SENDER_MAILBOX, CORPORATE_MANDATORY_CC, generateOverdueEmail } from '../utils/automatedEmailNotifier';

interface TaskMatrixViewProps {
  tasks: Task[];
  allTasksCount: number;
  collaborators: Collaborator[];
  cutoffDate: string;
  onEditTask: (task: Task) => void;
  onDeleteTask: (taskId: string) => void;
  onUpdateTaskStatus: (taskId: string, newStatus: TaskStatus) => void;
  onOpenNewTaskModal: () => void;
  onToggleSubtask?: (taskId: string, subtaskId: string) => void;
  onOpenDispatchModal?: (task: Task) => void;
  onMarkTaskAsDispatched?: (taskId: string) => void;
}

type SortField = 'title' | 'domain' | 'collaborator' | 'priority' | 'status' | 'nextFollowUpDate' | 'lastModified';
type SortOrder = 'asc' | 'desc';

export const TaskMatrixView: React.FC<TaskMatrixViewProps> = ({
  tasks,
  allTasksCount,
  collaborators,
  cutoffDate,
  onEditTask,
  onDeleteTask,
  onUpdateTaskStatus,
  onOpenNewTaskModal,
  onToggleSubtask,
  onOpenDispatchModal,
  onMarkTaskAsDispatched,
}) => {
  // Inline filters inside the Matrix (as shown in the reference image)
  const [matrixSearch, setMatrixSearch] = useState('');
  const [selectedDomain, setSelectedDomain] = useState<string>('all');
  const [selectedCollab, setSelectedCollab] = useState<string>('all');
  const [selectedPriority, setSelectedPriority] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedFollowUp, setSelectedFollowUp] = useState<string>('all');

  // Sorting state
  const [sortField, setSortField] = useState<SortField>('nextFollowUpDate');
  const [sortOrder, setSortOrder] = useState<SortOrder>('asc');

  // Pagination state
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;

  // Expanded rows state
  const [expandedRowIds, setExpandedRowIds] = useState<Record<string, boolean>>({});

  const toggleRowExpand = (id: string) => {
    setExpandedRowIds((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder((prev) => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortField(field);
      setSortOrder('asc');
    }
  };

  const clearMatrixFilters = () => {
    setMatrixSearch('');
    setSelectedDomain('all');
    setSelectedCollab('all');
    setSelectedPriority('all');
    setSelectedStatus('all');
    setSelectedFollowUp('all');
    setCurrentPage(1);
  };

  // Count active matrix filters
  const activeMatrixFiltersList: { key: string; label: string; clear: () => void }[] = [];
  if (selectedDomain !== 'all') {
    activeMatrixFiltersList.push({
      key: 'domain',
      label: `Dominio: ${selectedDomain}`,
      clear: () => setSelectedDomain('all'),
    });
  }
  if (selectedCollab !== 'all') {
    const c = collaborators.find((col) => col.id === selectedCollab);
    activeMatrixFiltersList.push({
      key: 'collab',
      label: `Responsable: ${c ? c.name : selectedCollab}`,
      clear: () => setSelectedCollab('all'),
    });
  }
  if (selectedPriority !== 'all') {
    activeMatrixFiltersList.push({
      key: 'priority',
      label: `Prioridad: ${selectedPriority}`,
      clear: () => setSelectedPriority('all'),
    });
  }
  if (selectedStatus !== 'all') {
    activeMatrixFiltersList.push({
      key: 'status',
      label: `Estado: ${selectedStatus}`,
      clear: () => setSelectedStatus('all'),
    });
  }
  if (matrixSearch.trim() !== '') {
    activeMatrixFiltersList.push({
      key: 'search',
      label: `Búsqueda: "${matrixSearch}"`,
      clear: () => setMatrixSearch(''),
    });
  }

  // Filter tasks based on inline matrix filters
  const filteredTasks = useMemo(() => {
    return tasks.filter((task) => {
      if (selectedDomain !== 'all' && task.domain !== selectedDomain) return false;
      if (selectedCollab !== 'all' && task.collaboratorId !== selectedCollab) return false;
      if (selectedPriority !== 'all' && task.priority !== selectedPriority) return false;
      if (selectedStatus !== 'all' && task.status !== selectedStatus) return false;
      if (selectedFollowUp === 'overdue' && !isTaskOverdue(task, cutoffDate)) return false;
      if (selectedFollowUp === 'upcoming' && isTaskOverdue(task, cutoffDate)) return false;

      if (matrixSearch.trim()) {
        const q = matrixSearch.toLowerCase().trim();
        const matchTitle = task.title.toLowerCase().includes(q);
        const matchDesc = task.description?.toLowerCase().includes(q);
        const matchDomain = task.domain.toLowerCase().includes(q);
        const matchCode = task.code?.toLowerCase().includes(q);
        if (!matchTitle && !matchDesc && !matchDomain && !matchCode) return false;
      }
      return true;
    });
  }, [tasks, selectedDomain, selectedCollab, selectedPriority, selectedStatus, selectedFollowUp, matrixSearch, cutoffDate]);

  // Sort tasks
  const sortedTasks = useMemo(() => {
    const list = [...filteredTasks];
    list.sort((a, b) => {
      let valA: string | number = '';
      let valB: string | number = '';

      if (sortField === 'title') {
        valA = a.title.toLowerCase();
        valB = b.title.toLowerCase();
      } else if (sortField === 'domain') {
        valA = a.domain.toLowerCase();
        valB = b.domain.toLowerCase();
      } else if (sortField === 'collaborator') {
        const ca = collaborators.find((c) => c.id === a.collaboratorId)?.name || '';
        const cb = collaborators.find((c) => c.id === b.collaboratorId)?.name || '';
        valA = ca.toLowerCase();
        valB = cb.toLowerCase();
      } else if (sortField === 'priority') {
        const priorityOrder: Record<Priority, number> = { Crítica: 4, Alta: 3, Media: 2, Baja: 1 };
        valA = priorityOrder[a.priority];
        valB = priorityOrder[b.priority];
      } else if (sortField === 'status') {
        valA = a.status;
        valB = b.status;
      } else if (sortField === 'nextFollowUpDate') {
        valA = a.nextFollowUpDate;
        valB = b.nextFollowUpDate;
      } else if (sortField === 'lastModified') {
        valA = a.lastModifiedDate || a.creationDate;
        valB = b.lastModifiedDate || b.creationDate;
      }

      if (valA < valB) return sortOrder === 'asc' ? -1 : 1;
      if (valA > valB) return sortOrder === 'asc' ? 1 : -1;
      return 0;
    });
    return list;
  }, [filteredTasks, sortField, sortOrder, collaborators]);

  // Pagination calculation
  const totalPages = Math.max(1, Math.ceil(sortedTasks.length / pageSize));
  const paginatedTasks = sortedTasks.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  // Helper for collaborator lookup
  const getCollab = (id: string) => collaborators.find((c) => c.id === id);

  return (
    <div className="space-y-4">
      {/* Title & Subtitle header matching the reference image */}
      <div>
        <h2 className="text-xl font-bold tracking-tight text-slate-900 dark:text-white">
          Matriz Completa de Seguimiento de Actividades
        </h2>
        <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-0.5">
          Visualiza, ordena por fecha o criticidad y actualiza estados de forma masiva
        </p>
      </div>

      {/* Inline Filters Card (Filtros de la Matriz de Tareas) */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 p-4 sm:p-5 shadow-xs space-y-3.5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-lg bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 border border-indigo-200 dark:border-indigo-800">
              <Filter className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xs sm:text-sm font-bold text-slate-900 dark:text-white">
                  Filtros de la Matriz de Tareas
                </span>
                {activeMatrixFiltersList.length > 0 && (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300">
                    {activeMatrixFiltersList.length} {activeMatrixFiltersList.length === 1 ? 'filtro activo' : 'filtros activos'}
                  </span>
                )}
              </div>
              <p className="text-[11px] text-slate-500 dark:text-slate-400">
                Filtra simultáneamente por Dominio, Responsable, Prioridad, Estado y Próximo Seguimiento
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={clearMatrixFilters}
              disabled={activeMatrixFiltersList.length === 0}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${
                activeMatrixFiltersList.length > 0
                  ? 'border-indigo-200 dark:border-indigo-800 bg-indigo-50 dark:bg-indigo-950/50 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100 cursor-pointer'
                  : 'border-slate-200 dark:border-slate-800 text-slate-400 bg-slate-50 dark:bg-slate-800/40 cursor-not-allowed'
              }`}
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Limpiar Filtros</span>
            </button>

            {/* Quick search input */}
            <div className="relative min-w-[200px] sm:min-w-[240px]">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={matrixSearch}
                onChange={(e) => {
                  setMatrixSearch(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder="Buscar en actividad..."
                className="w-full pl-8.5 pr-7 py-1.5 rounded-xl text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden focus:ring-1 focus:ring-indigo-500"
              />
              {matrixSearch && (
                <button
                  onClick={() => setMatrixSearch('')}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Matrix Filter Selectors Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3 pt-2">
          {/* Dominio */}
          <div>
            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
              Dominio
            </label>
            <select
              value={selectedDomain}
              onChange={(e) => {
                setSelectedDomain(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 truncate"
            >
              <option value="all">Todos los Dominios</option>
              <option value="Windows">Windows</option>
              <option value="IBMi">IBMi</option>
              <option value="Documentación">Documentación</option>
              <option value="PCI">PCI</option>
              <option value="Auditoria Interna">Auditoria Interna</option>
              <option value="Auditoria Externa">Auditoria Externa</option>
            </select>
          </div>

          {/* Responsable */}
          <div>
            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
              Responsable
            </label>
            <select
              value={selectedCollab}
              onChange={(e) => {
                setSelectedCollab(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 truncate"
            >
              <option value="all">Todos los Responsables</option>
              {collaborators.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} ({c.initials})
                </option>
              ))}
            </select>
          </div>

          {/* Prioridad */}
          <div>
            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
              Prioridad
            </label>
            <select
              value={selectedPriority}
              onChange={(e) => {
                setSelectedPriority(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 truncate"
            >
              <option value="all">Todas las Prioridades</option>
              <option value="Crítica">Crítica</option>
              <option value="Alta">Alta</option>
              <option value="Media">Media</option>
              <option value="Baja">Baja</option>
            </select>
          </div>

          {/* Estado */}
          <div>
            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
              Estado
            </label>
            <select
              value={selectedStatus}
              onChange={(e) => {
                setSelectedStatus(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 truncate"
            >
              <option value="all">Todos los Estados</option>
              <option value="Pendiente">Pendiente</option>
              <option value="En Proceso">En Proceso</option>
              <option value="En Revisión">En Revisión</option>
              <option value="Completado">Completado</option>
              <option value="Bloqueado">Bloqueado</option>
            </select>
          </div>

          {/* Próx. Seguimiento */}
          <div>
            <label className="block text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1">
              Próx. Seguimiento
            </label>
            <select
              value={selectedFollowUp}
              onChange={(e) => {
                setSelectedFollowUp(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full text-xs py-1.5 px-2.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 focus:ring-1 focus:ring-indigo-500 truncate"
            >
              <option value="all">Todas las fechas</option>
              <option value="overdue">⚠️ Solo vencidas / fuera de SLA</option>
              <option value="upcoming">Vigentes / en plazo</option>
            </select>
          </div>
        </div>

        {/* Active Filter Badges */}
        {activeMatrixFiltersList.length > 0 && (
          <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-slate-100 dark:border-slate-800/80 text-xs">
            <span className="text-slate-500 dark:text-slate-400 font-medium">
              Filtros activos ({activeMatrixFiltersList.length}):
            </span>
            {activeMatrixFiltersList.map((f) => (
              <span
                key={f.key}
                className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg text-xs font-medium bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800"
              >
                <span>{f.label}</span>
                <button
                  onClick={f.clear}
                  className="hover:text-indigo-900 dark:hover:text-white"
                >
                  <X className="w-3 h-3" />
                </button>
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Counter + Pagination Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-1 text-xs">
        <div className="text-slate-600 dark:text-slate-400 font-medium">
          Mostrando <span className="font-bold text-slate-900 dark:text-white">{sortedTasks.length}</span> de <span className="font-bold text-slate-900 dark:text-white">{allTasksCount}</span> actividades{' '}
          <span className="text-indigo-600 dark:text-indigo-400">(Filtradas en la matriz)</span>
        </div>

        {/* Pagination Controls */}
        <div className="flex items-center gap-2 self-end sm:self-auto">
          <span className="text-slate-500 dark:text-slate-400">
            Página {currentPage} de {totalPages}
          </span>
          <button
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            className={`px-3 py-1 rounded-lg border text-xs font-semibold transition-all ${
              currentPage === 1
                ? 'border-slate-200 dark:border-slate-800 text-slate-400 bg-slate-50 dark:bg-slate-800/40 cursor-not-allowed'
                : 'border-slate-300 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200'
            }`}
          >
            Anterior
          </button>
          <button
            onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            className={`px-3 py-1 rounded-lg border text-xs font-semibold transition-all ${
              currentPage === totalPages
                ? 'border-slate-200 dark:border-slate-800 text-slate-400 bg-slate-50 dark:bg-slate-800/40 cursor-not-allowed'
                : 'border-slate-300 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-200'
            }`}
          >
            Siguiente
          </button>
        </div>
      </div>

      {/* Main Table Container matching the reference image layout */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50/80 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-800 text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider">
                <th className="py-3 px-3 w-8"></th>
                
                {/* Actividad / Requerimiento */}
                <th
                  onClick={() => handleSort('title')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Actividad / Requerimiento</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Dominio */}
                <th
                  onClick={() => handleSort('domain')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Dominio</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                    {selectedDomain !== 'all' && (
                      <span className="px-1.5 py-0.2 rounded-md bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 text-[10px]">
                        (1)
                      </span>
                    )}
                  </div>
                </th>

                {/* Responsable */}
                <th
                  onClick={() => handleSort('collaborator')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Responsable</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Prioridad */}
                <th
                  onClick={() => handleSort('priority')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Prioridad</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Estado */}
                <th
                  onClick={() => handleSort('status')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Estado</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Próx. Seguimiento */}
                <th
                  onClick={() => handleSort('nextFollowUpDate')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors"
                >
                  <div className="flex items-center gap-1.5">
                    <span>Próx. Seguimiento</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Horas (Inv / Est) */}
                <th className="py-3 px-3 text-center">
                  <span>Horas (Inv / Est)</span>
                </th>

                {/* Últ. Modif. */}
                <th
                  onClick={() => handleSort('lastModified')}
                  className="py-3 px-3 cursor-pointer hover:text-indigo-600 transition-colors text-center"
                >
                  <div className="flex items-center justify-center gap-1">
                    <span>Últ. Modif.</span>
                    <ArrowUpDown className="w-3 h-3 text-slate-400" />
                  </div>
                </th>

                {/* Acciones */}
                <th className="py-3 px-3 text-right">
                  <span>Acciones</span>
                </th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100 dark:divide-slate-800 text-xs">
              {paginatedTasks.length === 0 ? (
                <tr>
                  <td colSpan={10} className="py-16 text-center">
                    <div className="flex flex-col items-center justify-center gap-3">
                      <div className="w-12 h-12 rounded-2xl bg-indigo-50 dark:bg-indigo-950/60 border border-indigo-200 dark:border-indigo-800 flex items-center justify-center text-indigo-600">
                        <FolderPlus className="w-6 h-6" />
                      </div>
                      <p className="text-sm font-bold text-slate-800 dark:text-slate-200">
                        {allTasksCount === 0
                          ? 'Dashboard nuevo: No hay actividades registradas todavía'
                          : 'No se encontraron actividades con los filtros actuales'}
                      </p>
                      <p className="text-xs text-slate-500 max-w-sm">
                        {allTasksCount === 0
                          ? 'La base de datos se ha inicializado desde cero. Haz clic en el botón para registrar actividades y asignar dominios.'
                          : 'Prueba ajustando los términos de búsqueda o limpiando los filtros seleccionados.'}
                      </p>
                      {allTasksCount === 0 ? (
                        <button
                          onClick={onOpenNewTaskModal}
                          className="mt-1 flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-xs transition-all cursor-pointer"
                        >
                          <Plus className="w-4 h-4" />
                          <span>Registrar Primera Actividad</span>
                        </button>
                      ) : (
                        <button
                          onClick={clearMatrixFilters}
                          className="text-xs text-indigo-600 dark:text-indigo-400 font-semibold hover:underline cursor-pointer"
                        >
                          Restablecer filtros
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                paginatedTasks.map((task) => {
                  const isExpanded = !!expandedRowIds[task.id];
                  const collab = getCollab(task.collaboratorId);
                  const isOverdue = isTaskOverdue(task, cutoffDate);

                  return (
                    <React.Fragment key={task.id}>
                      <tr className="hover:bg-slate-50/70 dark:hover:bg-slate-800/40 transition-colors group">
                        {/* Expand Toggle */}
                        <td className="py-3 px-3 text-slate-400">
                          <button
                            onClick={() => toggleRowExpand(task.id)}
                            className="p-1 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
                            title="Expandir detalles"
                          >
                            {isExpanded ? (
                              <ChevronDown className="w-4 h-4 text-indigo-600" />
                            ) : (
                              <ChevronRight className="w-4 h-4" />
                            )}
                          </button>
                        </td>

                        {/* Actividad / Requerimiento */}
                        <td className="py-3 px-3 max-w-sm">
                          <div className="flex items-center gap-1.5 mb-1">
                            <span className={`text-[10px] px-1.5 py-0.2 rounded-md font-semibold ${
                              task.type === 'Proyecto'
                                ? 'bg-indigo-50 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800'
                                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700'
                            }`}>
                              {task.type}
                            </span>
                            {task.companyUnit && (
                              <span className="text-[10px] px-1.5 py-0.2 rounded-md font-semibold bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 flex items-center gap-0.5">
                                <Building2 className="w-2.5 h-2.5" />
                                {task.companyUnit}
                              </span>
                            )}
                            {task.code && (
                              <span className="text-[10px] text-slate-400 font-mono">
                                #{task.code}
                              </span>
                            )}
                          </div>
                          <div
                            onClick={() => toggleRowExpand(task.id)}
                            className="font-bold text-slate-900 dark:text-white hover:text-indigo-600 dark:hover:text-indigo-400 cursor-pointer leading-snug line-clamp-2"
                          >
                            {task.title}
                          </div>
                        </td>

                        {/* Dominio */}
                        <td className="py-3 px-3 text-slate-600 dark:text-slate-300 font-medium">
                          {task.domain}
                        </td>

                        {/* Responsable */}
                        <td className="py-3 px-3 whitespace-nowrap">
                          {collab ? (
                            <div className="flex items-center gap-2">
                              <div className="w-6 h-6 rounded-full bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center text-[10px] font-bold">
                                {collab.initials}
                              </div>
                              <span className="font-semibold text-slate-800 dark:text-slate-200">
                                {collab.name}
                              </span>
                            </div>
                          ) : (
                            <span className="text-slate-400 italic">Sin asignar</span>
                          )}
                        </td>

                        {/* Prioridad */}
                        <td className="py-3 px-3 whitespace-nowrap">
                          {task.priority === 'Crítica' && (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-900">
                              <AlertTriangle className="w-3 h-3 text-rose-500" />
                              <span>Crítica</span>
                            </span>
                          )}
                          {task.priority === 'Alta' && (
                            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-900">
                              Alta
                            </span>
                          )}
                          {task.priority === 'Media' && (
                            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-sky-100 dark:bg-sky-950/60 text-sky-800 dark:text-sky-300 border border-sky-200 dark:border-sky-900">
                              Media
                            </span>
                          )}
                          {task.priority === 'Baja' && (
                            <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 dark:bg-emerald-950/60 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-900">
                              Baja
                            </span>
                          )}
                        </td>

                        {/* Estado: Interactive in-row selector matching the reference image */}
                        <td className="py-3 px-3 whitespace-nowrap">
                          <select
                            value={task.status}
                            onChange={(e) => onUpdateTaskStatus(task.id, e.target.value as TaskStatus)}
                            className={`text-xs font-semibold px-2.5 py-1 rounded-full border cursor-pointer focus:outline-hidden focus:ring-2 focus:ring-indigo-500 transition-all ${
                              task.status === 'Completado'
                                ? 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-300 border-emerald-300 dark:border-emerald-800'
                                : task.status === 'En Proceso'
                                ? 'bg-blue-50 dark:bg-blue-950/50 text-blue-700 dark:text-blue-300 border-blue-300 dark:border-blue-800'
                                : task.status === 'En Revisión'
                                ? 'bg-purple-50 dark:bg-purple-950/50 text-purple-700 dark:text-purple-300 border-purple-300 dark:border-purple-800'
                                : task.status === 'Bloqueado'
                                ? 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-300 border-rose-300 dark:border-rose-800'
                                : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border-slate-300 dark:border-slate-700'
                            }`}
                          >
                            <option value="Pendiente">Pendiente</option>
                            <option value="En Proceso">En Proceso</option>
                            <option value="En Revisión">En Revisión</option>
                            <option value="Completado">Completado</option>
                            <option value="Bloqueado">Bloqueado</option>
                          </select>
                        </td>

                        {/* Próx. Seguimiento with warning if overdue */}
                        <td className="py-3 px-3 whitespace-nowrap">
                          <div className="flex flex-col">
                            <div className={`flex items-center gap-1.5 font-medium ${
                              isOverdue
                                ? 'text-rose-600 dark:text-rose-400 font-bold'
                                : 'text-slate-600 dark:text-slate-400'
                            }`}>
                              {isOverdue && <AlertTriangle className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400 shrink-0" />}
                              <span>{task.nextFollowUpDate}</span>
                            </div>

                            {/* Despacho Directo en Gmail con buzón emisor y CC permanente */}
                            {isOverdue && (
                                <div className="flex items-center gap-1 mt-1">
                                  <a
                                    href={generateOverdueEmail(task, collaborators.find(c => c.id === task.collaboratorId)).gmailWebUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      if (onMarkTaskAsDispatched) onMarkTaskAsDispatched(task.id);
                                    }}
                                    className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-red-50 dark:bg-red-950/60 hover:bg-red-100 dark:hover:bg-red-900/60 text-red-700 dark:text-red-300 text-[10px] font-bold border border-red-200 dark:border-red-800 transition-colors"
                                    title={`Despachar en Gmail. De: ${CORPORATE_SENDER_MAILBOX} | CC: ${CORPORATE_MANDATORY_CC}`}
                                  >
                                    <ExternalLink className="w-2.5 h-2.5" />
                                    <span>Despachar Gmail</span>
                                  </a>
                                </div>
                            )}

                            {task.lastNotificationSentAt && !isOverdue && (
                              <div className="flex items-center gap-1 text-[10px] text-slate-500 dark:text-slate-400 mt-0.5" title={`Aviso emitido: ${task.lastNotificationSentAt}`}>
                                <CheckCircle2 className="w-3 h-3 text-emerald-500 shrink-0" />
                                <span className="truncate max-w-[110px]">Aviso Registrado</span>
                              </div>
                            )}
                          </div>
                        </td>

                        {/* Horas (Inv / Est) */}
                        <td className="py-3 px-3 whitespace-nowrap text-center">
                          <div className="flex flex-col items-center">
                            <div>
                              <span className="font-bold text-slate-800 dark:text-slate-200">{task.hoursInvested}h</span>
                              <span className="text-slate-400 text-[11px]"> / {task.hoursEstimated}h</span>
                            </div>
                            <div className="w-16 h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden mt-1">
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
                            <span className="text-[9px] text-slate-400 mt-0.5">
                              {Math.min(100, Math.round((task.hoursInvested / (task.hoursEstimated || 1)) * 100))}%
                              {task.status === 'En Proceso' && ' (8h/d)'}
                            </span>
                          </div>
                        </td>

                        {/* Últ. Modif. */}
                        <td className="py-3 px-3 whitespace-nowrap text-center">
                          {task.lastModifiedBy ? (
                            <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-slate-900 dark:bg-slate-700 text-white text-[10px] font-bold" title={`Modificado por ${task.lastModifiedBy}`}>
                              {task.lastModifiedBy}
                            </span>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>

                        {/* Acciones */}
                        <td className="py-3 px-3 whitespace-nowrap text-right">
                          <div className="flex items-center justify-end gap-1 text-slate-400">
                            {/* Expand / Details */}
                            <button
                              onClick={() => toggleRowExpand(task.id)}
                              className="p-1 hover:text-indigo-600 dark:hover:text-indigo-400 rounded-md transition-colors"
                              title="Ver bitácora y subtareas"
                            >
                              <Plus className="w-4 h-4" />
                            </button>

                            {/* Edit */}
                            <button
                              onClick={() => onEditTask(task)}
                              className="p-1 hover:text-slate-700 dark:hover:text-white rounded-md transition-colors"
                              title="Modificar tarea"
                            >
                              <Pencil className="w-4 h-4" />
                            </button>

                            {/* Delete */}
                            <button
                              onClick={() => onDeleteTask(task.id)}
                              className="p-1 hover:text-rose-600 rounded-md transition-colors"
                              title="Eliminar tarea"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>

                      {/* Expandable row content */}
                      {isExpanded && (
                        <tr className="bg-slate-50/90 dark:bg-slate-800/60 border-y border-slate-200 dark:border-slate-700">
                          <td colSpan={10} className="p-4 sm:p-5">
                            <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
                              {/* Left: Description & Details */}
                              <div className="lg:col-span-2 space-y-3">
                                <div>
                                  <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                                    Descripción del Requerimiento / Alcance
                                  </span>
                                  <p className="text-xs text-slate-700 dark:text-slate-300 mt-1 leading-relaxed">
                                    {task.description || 'Sin descripción detallada.'}
                                  </p>
                                </div>

                                {task.notes && (
                                  <div className="p-2.5 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 text-xs text-amber-800 dark:text-amber-300 flex items-start gap-2">
                                    <FileText className="w-3.5 h-3.5 shrink-0 mt-0.5 text-amber-600" />
                                    <span><strong>Nota de seguimiento:</strong> {task.notes}</span>
                                  </div>
                                )}

                                {/* Subtasks interactive checklist */}
                                {task.subtasks && task.subtasks.length > 0 && (
                                  <div className="pt-2">
                                    <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-1.5 block">
                                      Hitos y Subtareas ({task.subtasks.filter(s => s.completed).length}/{task.subtasks.length})
                                    </span>
                                    <div className="space-y-1.5">
                                      {task.subtasks.map((st) => (
                                        <div
                                          key={st.id}
                                          onClick={() => onToggleSubtask && onToggleSubtask(task.id, st.id)}
                                          className="flex items-center gap-2 text-xs text-slate-700 dark:text-slate-300 hover:text-indigo-600 cursor-pointer select-none"
                                        >
                                          {st.completed ? (
                                            <CheckSquare className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                                          ) : (
                                            <Square className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                          )}
                                          <span className={st.completed ? 'line-through text-slate-400' : ''}>
                                            {st.title}
                                          </span>
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                )}
                              </div>

                              {/* Right: Technical Metadata & Quick Actions */}
                              <div className="space-y-2.5 bg-white dark:bg-slate-900 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 text-xs">
                                <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400 border-b border-slate-100 dark:border-slate-800 pb-1">
                                  Trazabilidad y SLAs
                                </div>
                                <div className="flex justify-between">
                                  <span className="text-slate-500">Fecha de Creación:</span>
                                  <span className="font-semibold text-slate-800 dark:text-slate-200">{task.creationDate}</span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="text-slate-500">Última Modificación:</span>
                                  <span className="font-semibold text-slate-800 dark:text-slate-200">
                                    {task.lastModifiedDate} ({task.lastModifiedBy})
                                  </span>
                                </div>
                                <div className="flex justify-between">
                                  <span className="text-slate-500">Progreso de Horas (8h/d lun-vie):</span>
                                  <span className="font-semibold text-indigo-600 dark:text-indigo-400">
                                    {task.hoursInvested}h / {task.hoursEstimated}h ({Math.min(100, Math.round((task.hoursInvested / (task.hoursEstimated || 1)) * 100))}%)
                                  </span>
                                </div>
                                <div className="flex justify-between items-center pt-2 border-t border-slate-100 dark:border-slate-800">
                                  <span className="text-slate-500 flex items-center gap-1">
                                    <Mail className="w-3 h-3 text-indigo-500" /> Notificación SLA (Banesco):
                                  </span>
                                  <span className={`font-semibold ${
                                    isOverdue 
                                      ? 'text-rose-600 dark:text-rose-400 font-bold' 
                                      : 'text-emerald-600 dark:text-emerald-400'
                                  }`}>
                                    {isOverdue ? 'Vencido - Requiere Envío' : 'Al día'}
                                  </span>
                                </div>

                                <div className="p-2.5 rounded-lg bg-slate-100 dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-[11px] space-y-1">
                                  <div className="flex justify-between">
                                    <span className="text-slate-500">Buzón Emisor (De):</span>
                                    <span className="font-mono font-bold text-indigo-700 dark:text-indigo-300">{CORPORATE_SENDER_MAILBOX}</span>
                                  </div>
                                  <div className="flex justify-between">
                                    <span className="text-slate-500">Copia Fija (CC):</span>
                                    <span className="font-mono font-bold text-indigo-700 dark:text-indigo-300">{CORPORATE_MANDATORY_CC}</span>
                                  </div>
                                  {task.lastNotificationSentAt && (
                                    <div className="flex justify-between pt-1 border-t border-slate-200 dark:border-slate-800 text-[10px]">
                                      <span className="text-slate-500">Última emisión registrada:</span>
                                      <span className="text-emerald-600 dark:text-emerald-400 font-semibold">{task.lastNotificationSentAt}</span>
                                    </div>
                                  )}
                                </div>

                                <div className="pt-2 flex flex-wrap items-center gap-2">
                                  <a
                                    href={generateOverdueEmail(task, collaborators.find(c => c.id === task.collaboratorId)).gmailWebUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    onClick={() => {
                                      if (onMarkTaskAsDispatched) onMarkTaskAsDispatched(task.id);
                                    }}
                                    className="flex-1 py-1.5 px-2 bg-red-600 hover:bg-red-700 text-white font-bold rounded-lg text-center flex items-center justify-center gap-1.5 transition-colors text-xs"
                                    title={`Despachar en Gmail desde ${CORPORATE_SENDER_MAILBOX} con copia obligatoria a ${CORPORATE_MANDATORY_CC}`}
                                  >
                                    <ExternalLink className="w-3.5 h-3.5" />
                                    <span>Despachar en Gmail</span>
                                  </a>

                                  {onOpenDispatchModal && (
                                    <button
                                      type="button"
                                      onClick={() => onOpenDispatchModal(task)}
                                      className="py-1.5 px-2.5 bg-slate-200 hover:bg-slate-300 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-800 dark:text-slate-200 font-semibold rounded-lg text-center flex items-center justify-center gap-1 transition-colors text-xs cursor-pointer"
                                      title="Ver formato oficial y opciones de copiado"
                                    >
                                      <span>Ver Correo</span>
                                    </button>
                                  )}

                                  <button
                                    type="button"
                                    onClick={() => onEditTask(task)}
                                    className="py-1.5 px-2.5 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 font-semibold rounded-lg text-center flex items-center justify-center gap-1 transition-colors text-xs cursor-pointer"
                                  >
                                    <Pencil className="w-3.5 h-3.5" />
                                    <span>Editar</span>
                                  </button>
                                </div>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
