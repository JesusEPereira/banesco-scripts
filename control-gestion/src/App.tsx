import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { Header } from './components/Header';
import { GlobalFilters } from './components/GlobalFilters';
import { DashboardView } from './components/DashboardView';
import { TaskMatrixView } from './components/TaskMatrixView';
import { KanbanView } from './components/KanbanView';
import { TeamProgressView } from './components/TeamProgressView';
import { MaintenanceView } from './components/MaintenanceView';
import { TaskModal } from './components/TaskModal';
import { ExportModal } from './components/ExportModal';
import { AutomatedNotificationDrawer } from './components/AutomatedNotificationDrawer';
import { EmailDispatchModal } from './components/EmailDispatchModal';
import { Collaborator, FilterState, Task, TaskStatus } from './types';
import { INITIAL_COLLABORATORS, INITIAL_TASKS, REFERENCE_CUTOFF_DATE } from './data/initialData';
import { computeCollaboratorWorkload, computeKPIData, filterTasks } from './utils/metrics';
import { getTaskInvestedHours, updateTaskStatusWithHours } from './utils/workingHours';
import { 
  runAutomatedSlaNotificationCheck, 
  CORPORATE_SENDER_MAILBOX, 
  CORPORATE_MANDATORY_CC 
} from './utils/automatedEmailNotifier';
import { 
  fetchSharedTasks, 
  saveSharedTask, 
  deleteSharedTask, 
  bulkSyncTasks, 
  resetSharedTasksOnServer 
} from './utils/api';
import { Bell, X, ExternalLink, Mail, Send } from 'lucide-react';

const LOCAL_STORAGE_TASKS_KEY = 'team_performance_dashboard_tasks_v3';
const LOCAL_STORAGE_CUTOFF_KEY = 'team_performance_dashboard_cutoff_v3';
const LOCAL_STORAGE_THEME_KEY = 'team_performance_dashboard_theme_v1';
const LOCAL_STORAGE_USER_KEY = 'active_permitted_user_id';

export default function App() {
  // Theme state
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem(LOCAL_STORAGE_THEME_KEY);
    if (saved !== null) {
      return saved === 'dark';
    }
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem(LOCAL_STORAGE_THEME_KEY, 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem(LOCAL_STORAGE_THEME_KEY, 'light');
    }
  }, [isDarkMode]);

  // Active Tab
  const [activeTab, setActiveTab] = useState<'dashboard' | 'kanban' | 'matrix' | 'team' | 'maintenance'>('matrix');

  // Collaborators & Permitted Users
  const [collaborators] = useState<Collaborator[]>(INITIAL_COLLABORATORS);
  
  // Active User / Operator with full permission to view & modify all tasks
  const [currentUserId, setCurrentUserId] = useState<string>(() => {
    return localStorage.getItem(LOCAL_STORAGE_USER_KEY) || 'collab-jp'; // Default to Jesus Pereira (JP)
  });

  const currentUser = useMemo(() => {
    return collaborators.find((c) => c.id === currentUserId) || collaborators[0];
  }, [collaborators, currentUserId]);

  const handleSelectUser = (user: Collaborator) => {
    setCurrentUserId(user.id);
    localStorage.setItem(LOCAL_STORAGE_USER_KEY, user.id);
  };

  // Cutoff date for SLA and delay calculation
  const [cutoffDate, setCutoffDate] = useState<string>(() => {
    const today = new Date().toISOString().split('T')[0];
    try {
      const saved = localStorage.getItem(LOCAL_STORAGE_CUTOFF_KEY);
      if (saved && saved >= today) {
        return saved;
      }
    } catch {
      // fallback
    }
    return today;
  });

  const handleUpdateCutoffDate = (newDate: string) => {
    setCutoffDate(newDate);
    localStorage.setItem(LOCAL_STORAGE_CUTOFF_KEY, newDate);
  };

  // Tasks state with persistence & automatic corporate mailbox and CC sanitization
  const [tasks, setTasks] = useState<Task[]>(() => {
    try {
      localStorage.removeItem('team_performance_dashboard_tasks_v1');
      localStorage.removeItem('team_performance_dashboard_tasks_v2');
      const saved = localStorage.getItem(LOCAL_STORAGE_TASKS_KEY);
      if (saved) {
        const parsed: Task[] = JSON.parse(saved);
        // Ensure all stored tasks enforce official Banesco sender and permanent CC
        return parsed.map((t) => ({
          ...t,
          notificationFrom: CORPORATE_SENDER_MAILBOX,
          notificationCc: CORPORATE_MANDATORY_CC,
        }));
      }
    } catch {
      // fallback
    }
    return INITIAL_TASKS;
  });

  // Local storage persistence
  useEffect(() => {
    try {
      localStorage.setItem(LOCAL_STORAGE_TASKS_KEY, JSON.stringify(tasks));
    } catch {
      // ignore storage error
    }
  }, [tasks]);

  // Shared Server Multi-user Synchronization
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [lastSyncTime, setLastSyncTime] = useState<string>('');
  const tasksRef = useRef<Task[]>(tasks);
  tasksRef.current = tasks;
  const isSyncingRef = useRef<boolean>(false);

  const syncWithSharedServer = useCallback(async () => {
    if (isSyncingRef.current) return;
    isSyncingRef.current = true;
    setIsSyncing(true);
    try {
      // 1. Recover any tasks that may exist in this browser's localStorage
      let storedTasks: Task[] = [];
      try {
        const saved = localStorage.getItem(LOCAL_STORAGE_TASKS_KEY);
        if (saved) storedTasks = JSON.parse(saved);
      } catch {
        // ignore
      }

      // Merge current in-memory tasks and local storage tasks to ensure nothing is lost
      const localMap = new Map<string, Task>();
      tasksRef.current.forEach((t) => localMap.set(t.id, t));
      storedTasks.forEach((t) => {
        if (!localMap.has(t.id)) {
          localMap.set(t.id, t);
        }
      });
      const localList = Array.from(localMap.values());

      // 2. Send local tasks to server and receive the unified superset of all tasks from all collaborators
      const synced = await bulkSyncTasks(localList);
      if (synced && Array.isArray(synced)) {
        const sanitized = synced.map((t) => ({
          ...t,
          notificationFrom: CORPORATE_SENDER_MAILBOX,
          notificationCc: CORPORATE_MANDATORY_CC,
        }));

        setTasks((prev) => {
          // Check if newly synced tasks arrived from another collaborator (e.g. "Prueba")
          if (sanitized.length > prev.length) {
            const newTasks = sanitized.filter((st) => !prev.some((pt) => pt.id === st.id));
            if (newTasks.length > 0) {
              const latest = newTasks[0];
              setAutoEmailToast({
                id: `sync-toast-${Date.now()}`,
                message: `Nueva actividad sincronizada en tiempo real: "${latest.title}"`,
                taskTitle: latest.title,
                count: newTasks.length,
                firstTask: latest,
              });
            }
          }

          if (JSON.stringify(prev) !== JSON.stringify(sanitized)) {
            return sanitized;
          }
          return prev;
        });

        setLastSyncTime(new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
      }
    } catch (err) {
      console.warn('Sync failed:', err);
    } finally {
      isSyncingRef.current = false;
      setIsSyncing(false);
    }
  }, []);

  // Initial sync on mount and periodic polling every 20 seconds
  useEffect(() => {
    syncWithSharedServer();
    const interval = setInterval(() => {
      syncWithSharedServer();
    }, 20000);
    return () => clearInterval(interval);
  }, [syncWithSharedServer]);

  // Global Filter state
  const [filters, setFilters] = useState<FilterState>({
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

  // Modals state
  const [isTaskModalOpen, setIsTaskModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);
  const [isNotificationDrawerOpen, setIsNotificationDrawerOpen] = useState(false);
  const [dispatchModalTask, setDispatchModalTask] = useState<Task | null>(null);
  const [lastCheckTimestamp, setLastCheckTimestamp] = useState<string>('');
  const [autoEmailToast, setAutoEmailToast] = useState<{
    id: string;
    message: string;
    taskTitle: string;
    count: number;
    firstTask?: Task;
    gmailWebUrl?: string;
    outlookWebUrl?: string;
    mailtoUrl?: string;
  } | null>(null);

  // Dynamically compute business working hours (8h/day Mon-Fri) for active tasks
  const tasksWithDynamicHours = useMemo(() => {
    return tasks.map((t) => {
      if (t.status === 'En Proceso') {
        const liveHours = getTaskInvestedHours(t);
        if (liveHours !== t.hoursInvested) {
          return { ...t, hoursInvested: liveHours };
        }
      }
      return t;
    });
  }, [tasks]);

  // Filtered tasks for views
  const filteredTasks = useMemo(() => {
    return filterTasks(tasksWithDynamicHours, filters, cutoffDate);
  }, [tasksWithDynamicHours, filters, cutoffDate]);

  // KPIs computed over filtered tasks
  const kpiData = useMemo(() => {
    return computeKPIData(filteredTasks, cutoffDate, collaborators);
  }, [filteredTasks, cutoffDate, collaborators]);

  // Collaborator workload
  const workload = useMemo(() => {
    return computeCollaboratorWorkload(tasksWithDynamicHours, collaborators, cutoffDate);
  }, [tasksWithDynamicHours, collaborators, cutoffDate]);

  // Active overdue count for notification badge based on nextFollowUpDate
  const activeOverdueCount = useMemo(() => {
    const today = new Date().toISOString().split('T')[0];
    return tasks.filter(
      (t) => t.status !== 'Completado' && t.nextFollowUpDate && (t.nextFollowUpDate <= cutoffDate || t.nextFollowUpDate <= today)
    ).length;
  }, [tasks, cutoffDate]);

  // Mark task as dispatched to Outlook
  const handleMarkTaskAsDispatched = (taskId: string) => {
    const nowFormatted = new Date().toLocaleString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
    setTasks((prev) =>
      prev.map((t) => {
        if (t.id !== taskId) return t;
        const updated = {
          ...t,
          lastNotificationSentAt: nowFormatted,
        };
        saveSharedTask(updated);
        return updated;
      })
    );
  };

  // Automated Email Notification Engine based on Próx. Seguimiento
  const isCheckingEmailRef = useRef(false);
  const runAutomatedEmailCheck = useCallback(() => {
    if (isCheckingEmailRef.current) return;
    isCheckingEmailRef.current = true;
    try {
      const nowTimeStr = new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      setLastCheckTimestamp(nowTimeStr);

      const { updatedTasks, newlyNotified } = runAutomatedSlaNotificationCheck(
        tasksRef.current,
        cutoffDate,
        collaborators,
        currentUser.initials
      );

      if (newlyNotified.length > 0) {
        setTasks(updatedTasks);
        // Persist to shared server
        bulkSyncTasks(updatedTasks);
        
        const first = newlyNotified[0];
        setAutoEmailToast({
          id: `toast-${Date.now()}`,
          message: `${newlyNotified.length} actividad(es) con SLA alcanzado: "${newlyNotified.map((n) => n.task.title).slice(0, 2).join('", "')}${newlyNotified.length > 2 ? '...' : ''}"`,
          taskTitle: first.task.title,
          count: newlyNotified.length,
          firstTask: first.task,
          gmailWebUrl: first.payload.gmailWebUrl,
          outlookWebUrl: first.payload.outlookWebUrl,
          mailtoUrl: first.payload.mailtoUrl,
        });
      }
    } finally {
      isCheckingEmailRef.current = false;
    }
  }, [cutoffDate, collaborators, currentUser.initials]);

  // Run automatically on load, when cutoffDate changes, and periodically every 60 seconds
  useEffect(() => {
    runAutomatedEmailCheck();
    const timer = setInterval(() => {
      runAutomatedEmailCheck();
    }, 60000);
    return () => clearInterval(timer);
  }, [runAutomatedEmailCheck]);

  // Handlers for task creation and modification (full permissions for all users)
  const handleOpenNewTaskModal = () => {
    setEditingTask(null);
    setIsTaskModalOpen(true);
  };

  const handleEditTask = (task: Task) => {
    setEditingTask(task);
    setIsTaskModalOpen(true);
  };

  const handleSaveTask = (savedTask: Task) => {
    const todayStr = new Date().toISOString().split('T')[0];
    const sanitizedTask: Task = {
      ...savedTask,
      lastModifiedBy: currentUser.initials,
      lastModifiedDate: todayStr,
      notificationFrom: CORPORATE_SENDER_MAILBOX,
      notificationCc: CORPORATE_MANDATORY_CC,
    };
    
    // 1. Optimistic local update
    setTasks((prev) => {
      const index = prev.findIndex((t) => t.id === sanitizedTask.id);
      if (index >= 0) {
        const updated = [...prev];
        updated[index] = sanitizedTask;
        return updated;
      } else {
        return [sanitizedTask, ...prev];
      }
    });

    // 2. Persist to shared server database for all permitted users
    saveSharedTask(sanitizedTask);
  };

  const handleDeleteTask = (taskId: string) => {
    if (window.confirm('¿Estás seguro de que deseas eliminar esta actividad?')) {
      setTasks((prev) => prev.filter((t) => t.id !== taskId));
      deleteSharedTask(taskId);
    }
  };

  const handleUpdateTaskStatus = (taskId: string, newStatus: TaskStatus) => {
    setTasks((prev) =>
      prev.map((t) => {
        if (t.id !== taskId) return t;
        const updated = updateTaskStatusWithHours(t, newStatus, currentUser.initials);
        saveSharedTask(updated);
        return updated;
      })
    );
  };

  const handleToggleSubtask = (taskId: string, subtaskId: string) => {
    const todayStr = new Date().toISOString().split('T')[0];
    setTasks((prev) =>
      prev.map((t) => {
        if (t.id !== taskId || !t.subtasks) return t;
        const updatedSubtasks = t.subtasks.map((st) =>
          st.id === subtaskId ? { ...st, completed: !st.completed } : st
        );
        const updatedTask = {
          ...t,
          subtasks: updatedSubtasks,
          lastModifiedDate: todayStr,
          lastModifiedBy: currentUser.initials,
        };
        saveSharedTask(updatedTask);
        return updatedTask;
      })
    );
  };

  const handleResetData = () => {
    if (window.confirm('¿Deseas restablecer las actividades del sistema? Esta acción limpiará la base compartida para todos los usuarios.')) {
      setTasks(INITIAL_TASKS);
      localStorage.removeItem(LOCAL_STORAGE_TASKS_KEY);
      resetSharedTasksOnServer();
    }
  };

  // Quick navigation handlers from Dashboard
  const handleSelectCollaboratorFromDashboard = (collaboratorId: string) => {
    setFilters((prev) => ({ ...prev, collaboratorId }));
    setActiveTab('matrix');
  };

  const handleSelectDomainFromDashboard = (domain: string) => {
    setFilters((prev) => ({ ...prev, domain }));
    setActiveTab('matrix');
  };

  const handleSelectPriorityFromDashboard = (priority: string) => {
    setFilters((prev) => ({ ...prev, priority }));
    setActiveTab('matrix');
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      {/* Top Header */}
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        totalTasksCount={tasks.length}
        cutoffDate={cutoffDate}
        isDarkMode={isDarkMode}
        setIsDarkMode={setIsDarkMode}
        currentUser={currentUser}
        collaborators={collaborators}
        onSelectUser={handleSelectUser}
        isSyncing={isSyncing}
        onManualSync={syncWithSharedServer}
        lastSyncTime={lastSyncTime}
        onOpenNewTaskModal={handleOpenNewTaskModal}
        onOpenExportModal={() => setIsExportModalOpen(true)}
        onResetData={handleResetData}
        onOpenNotificationDrawer={() => setIsNotificationDrawerOpen(true)}
        activeOverdueCount={activeOverdueCount}
      />

      {/* Automated Email Notice Action Banner */}
      {autoEmailToast && (
        <div className="bg-slate-900 border-b border-indigo-500/40 text-white px-4 py-2.5 text-xs flex flex-col md:flex-row md:items-center justify-between gap-3 shadow-lg animate-in slide-in-from-top duration-300">
          <div className="flex items-start sm:items-center gap-2.5">
            <span className="p-1.5 rounded-lg bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 shrink-0">
              <Bell className="w-4 h-4 text-amber-400 animate-bounce" />
            </span>
            <div className="space-y-0.5">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-bold text-white">
                  Aviso SLA por Próx. Seguimiento:
                </span>
                <span className="text-slate-300 font-medium">
                  {autoEmailToast.message}
                </span>
              </div>
              <div className="text-[11px] text-slate-400 flex flex-wrap items-center gap-2">
                <span>De: <strong className="text-indigo-300 font-mono">{CORPORATE_SENDER_MAILBOX}</strong></span>
                <span>•</span>
                <span>CC Permanente: <strong className="text-indigo-300 font-mono">{CORPORATE_MANDATORY_CC}</strong></span>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2 md:ml-auto shrink-0">
            {(autoEmailToast.gmailWebUrl || autoEmailToast.outlookWebUrl) && (
              <a
                href={autoEmailToast.gmailWebUrl || autoEmailToast.outlookWebUrl}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => {
                  if (autoEmailToast.firstTask) handleMarkTaskAsDispatched(autoEmailToast.firstTask.id);
                }}
                className="px-3 py-1.5 rounded-lg bg-red-600 hover:bg-red-500 text-white font-bold flex items-center gap-1.5 shadow-xs transition-colors cursor-pointer"
                title={`Despachar en Gmail desde ${CORPORATE_SENDER_MAILBOX} con CC a ${CORPORATE_MANDATORY_CC}`}
              >
                <ExternalLink className="w-3.5 h-3.5" />
                <span>Despachar en Gmail</span>
              </a>
            )}

            {autoEmailToast.mailtoUrl && (
              <a
                href={autoEmailToast.mailtoUrl}
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => {
                  if (autoEmailToast.firstTask) handleMarkTaskAsDispatched(autoEmailToast.firstTask.id);
                }}
                className="px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
                title="Abrir en cliente local (mailto)"
              >
                <Send className="w-3.5 h-3.5 text-indigo-400" />
                <span>Cliente Local</span>
              </a>
            )}

            {autoEmailToast.firstTask && (
              <button
                onClick={() => setDispatchModalTask(autoEmailToast.firstTask || null)}
                className="px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
              >
                <Mail className="w-3.5 h-3.5 text-indigo-400" />
                <span>Ver Formato</span>
              </button>
            )}

            <button
              onClick={() => setIsNotificationDrawerOpen(true)}
              className="px-2.5 py-1.5 rounded-lg bg-indigo-600/80 hover:bg-indigo-600 text-white font-semibold flex items-center gap-1 transition-colors cursor-pointer"
            >
              <span>Centro de Avisos</span>
            </button>

            <button
              onClick={() => setAutoEmailToast(null)}
              className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Global Filter Bar */}
      <GlobalFilters
        filters={filters}
        setFilters={setFilters}
        collaborators={collaborators}
        allTasks={tasksWithDynamicHours}
        filteredCount={filteredTasks.length}
        cutoffDate={cutoffDate}
      />

      {/* Main View Area */}
      <main className="flex-1 max-w-[1720px] w-full mx-auto p-4 sm:p-6 transition-all">
        {activeTab === 'dashboard' && (
          <DashboardView
            kpis={kpiData}
            workload={workload}
            tasks={filteredTasks}
            collaborators={collaborators}
            cutoffDate={cutoffDate}
            onSelectCollaborator={handleSelectCollaboratorFromDashboard}
            onSelectDomain={handleSelectDomainFromDashboard}
            onSelectPriority={handleSelectPriorityFromDashboard}
            onGoToMatrix={() => setActiveTab('matrix')}
            onUpdateTaskStatus={handleUpdateTaskStatus}
          />
        )}

        {activeTab === 'matrix' && (
          <TaskMatrixView
            tasks={filteredTasks}
            allTasksCount={tasks.length}
            collaborators={collaborators}
            cutoffDate={cutoffDate}
            onEditTask={handleEditTask}
            onDeleteTask={handleDeleteTask}
            onUpdateTaskStatus={handleUpdateTaskStatus}
            onOpenNewTaskModal={handleOpenNewTaskModal}
            onToggleSubtask={handleToggleSubtask}
            onOpenDispatchModal={(task) => setDispatchModalTask(task)}
            onMarkTaskAsDispatched={handleMarkTaskAsDispatched}
          />
        )}

        {activeTab === 'kanban' && (
          <KanbanView
            tasks={filteredTasks}
            collaborators={collaborators}
            cutoffDate={cutoffDate}
            onUpdateTaskStatus={handleUpdateTaskStatus}
            onEditTask={handleEditTask}
            onOpenNewTaskModal={handleOpenNewTaskModal}
          />
        )}

        {activeTab === 'team' && (
          <TeamProgressView
            workload={workload}
            tasks={tasksWithDynamicHours}
            collaborators={collaborators}
            cutoffDate={cutoffDate}
            onEditTask={handleEditTask}
            onUpdateTaskStatus={handleUpdateTaskStatus}
          />
        )}

        {activeTab === 'maintenance' && (
          <MaintenanceView
            tasks={tasksWithDynamicHours}
            cutoffDate={cutoffDate}
            setCutoffDate={handleUpdateCutoffDate}
            onResetData={handleResetData}
            onOpenExportModal={() => setIsExportModalOpen(true)}
          />
        )}
      </main>

      {/* Footer info bar */}
      <footer className="border-t border-slate-200 dark:border-slate-800/80 bg-white/70 dark:bg-slate-900/70 py-3 px-4 sm:px-6 text-xs text-slate-500 dark:text-slate-400 flex flex-col sm:flex-row items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <span className="font-semibold text-slate-700 dark:text-slate-300">Control de Gestión Gcia Administración Seguridad</span>
          <span>•</span>
          <span>Corte: {cutoffDate}</span>
          <span>•</span>
          <span>Buzón Emisor: {CORPORATE_SENDER_MAILBOX}</span>
        </div>
        <div className="flex items-center gap-4 text-[11px]">
          <span>{tasks.length} tareas en base compartida</span>
          <span>•</span>
          <span>Operador Activo: {currentUser.name} ({currentUser.initials})</span>
          <span>•</span>
          <span className="text-emerald-600 dark:text-emerald-400 font-semibold">Permiso Total Activo</span>
        </div>
      </footer>

      {/* Modals */}
      <TaskModal
        isOpen={isTaskModalOpen}
        onClose={() => {
          setIsTaskModalOpen(false);
          setEditingTask(null);
        }}
        onSave={handleSaveTask}
        initialTask={editingTask}
        collaborators={collaborators}
        currentInitials={currentUser.initials}
      />

      <ExportModal
        isOpen={isExportModalOpen}
        onClose={() => setIsExportModalOpen(false)}
        tasks={filteredTasks}
        collaborators={collaborators}
      />

      <AutomatedNotificationDrawer
        isOpen={isNotificationDrawerOpen}
        onClose={() => setIsNotificationDrawerOpen(false)}
        tasks={tasksWithDynamicHours}
        collaborators={collaborators}
        cutoffDate={cutoffDate}
        onTriggerManualCheck={runAutomatedEmailCheck}
        lastCheckTimestamp={lastCheckTimestamp}
        onOpenDispatchModal={(task) => setDispatchModalTask(task)}
        onMarkTaskAsDispatched={handleMarkTaskAsDispatched}
      />

      {/* Email Dispatch Modal */}
      <EmailDispatchModal
        isOpen={Boolean(dispatchModalTask)}
        onClose={() => setDispatchModalTask(null)}
        task={dispatchModalTask}
        collaborators={collaborators}
        currentInitials={currentUser.initials}
        onMarkAsDispatched={handleMarkTaskAsDispatched}
      />
    </div>
  );
}
