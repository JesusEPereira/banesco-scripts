import React, { useState, useRef, useEffect } from 'react';
import { 
  ShieldCheck, 
  Database, 
  LayoutDashboard, 
  Kanban, 
  TableProperties, 
  Users, 
  Wrench, 
  Download, 
  RotateCcw, 
  Plus, 
  Sun, 
  Moon, 
  ChevronDown,
  Bell,
  RefreshCw,
  Check,
  UserCheck,
  Maximize,
  Minimize
} from 'lucide-react';
import { Collaborator } from '../types';

interface HeaderProps {
  activeTab: 'dashboard' | 'kanban' | 'matrix' | 'team' | 'maintenance';
  setActiveTab: (tab: 'dashboard' | 'kanban' | 'matrix' | 'team' | 'maintenance') => void;
  totalTasksCount: number;
  cutoffDate: string;
  isDarkMode: boolean;
  setIsDarkMode: (val: boolean | ((prev: boolean) => boolean)) => void;
  currentUser: Collaborator;
  onOpenNewTaskModal: () => void;
  onOpenExportModal: () => void;
  onResetData: () => void;
  onOpenNotificationDrawer?: () => void;
  activeOverdueCount?: number;
  collaborators?: Collaborator[];
  onSelectUser?: (user: Collaborator) => void;
  isSyncing?: boolean;
  onManualSync?: () => void;
  lastSyncTime?: string;
}

export const Header: React.FC<HeaderProps> = ({
  activeTab,
  setActiveTab,
  totalTasksCount,
  cutoffDate,
  isDarkMode,
  setIsDarkMode,
  currentUser,
  onOpenNewTaskModal,
  onOpenExportModal,
  onResetData,
  onOpenNotificationDrawer,
  activeOverdueCount = 0,
  collaborators = [],
  onSelectUser,
  isSyncing = false,
  onManualSync,
  lastSyncTime,
}) => {
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const userMenuRef = useRef<HTMLDivElement>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Monitor fullscreen change events
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(Boolean(document.fullscreenElement));
    };
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
  }, []);

  const handleToggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {});
      }
    }
  };

  // Close menu when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setIsUserMenuOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <header className="bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 sticky top-0 z-30 transition-colors shadow-xs">
      <div className="max-w-[1720px] w-full mx-auto px-4 sm:px-6 py-2.5 flex flex-wrap items-center justify-between gap-3">
        {/* Brand & Area Title */}
        <div className="flex items-center gap-3 order-1">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-700 via-indigo-600 to-blue-500 text-white flex items-center justify-center shadow-md shadow-indigo-500/20">
            <ShieldCheck className="w-6 h-6 stroke-[2.2]" />
          </div>

          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-sm sm:text-base tracking-tight text-slate-900 dark:text-white">
                Control de Gestión
              </span>
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 dark:bg-indigo-950/80 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
                Gcia Administración Seguridad
              </span>
              <span className="hidden xl:inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800" title="Todas las tareas están sincronizadas en tiempo real en la base de datos compartida para todos los colaboradores permisados">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <span>Base Compartida Multi-Usuario</span>
              </span>
            </div>
            
            <div className="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              <div className="flex items-center gap-1.5">
                <span className="font-medium text-slate-700 dark:text-slate-300">Monitoreo de Rendimiento</span>
                <span>•</span>
                <span className="text-[11px] text-slate-400">Corte: <strong className="text-slate-700 dark:text-slate-300">{cutoffDate}</strong></span>
              </div>
              <div className="hidden sm:flex items-center gap-1 text-[11px] text-slate-400">
                <Database className="w-3 h-3 text-indigo-500" />
                <span>Banesco Banco Universal</span>
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav className="flex items-center bg-slate-100 dark:bg-slate-800/80 p-1 rounded-xl border border-slate-200 dark:border-slate-700/60 order-3 md:order-2 overflow-x-auto">
          <button
            onClick={() => setActiveTab('dashboard')}
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap cursor-pointer ${
              activeTab === 'dashboard'
                ? 'bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-400 shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <LayoutDashboard className="w-4 h-4" />
            <span>Dashboard</span>
          </button>

          <button
            onClick={() => setActiveTab('kanban')}
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap cursor-pointer ${
              activeTab === 'kanban'
                ? 'bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-400 shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Kanban className="w-4 h-4" />
            <span>Tablero Kanban</span>
          </button>

          <button
            onClick={() => setActiveTab('matrix')}
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap cursor-pointer ${
              activeTab === 'matrix'
                ? 'bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-400 shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <TableProperties className="w-4 h-4" />
            <span>Matriz de Tareas</span>
            <span className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
              activeTab === 'matrix'
                ? 'bg-indigo-100 dark:bg-indigo-950/80 text-indigo-700 dark:text-indigo-300'
                : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300'
            }`}>
              {totalTasksCount}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('team')}
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap cursor-pointer ${
              activeTab === 'team'
                ? 'bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-400 shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Users className="w-4 h-4" />
            <span>Progreso Equipo</span>
          </button>

          <button
            onClick={() => setActiveTab('maintenance')}
            className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap cursor-pointer ${
              activeTab === 'maintenance'
                ? 'bg-white dark:bg-slate-900 text-indigo-700 dark:text-indigo-400 shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Wrench className="w-4 h-4" />
            <span>Módulo de Mantenimiento</span>
          </button>
        </nav>

        {/* User & Global Actions */}
        <div className="flex items-center gap-2.5 order-2 md:order-3">
          
          {/* Real-time shared sync trigger */}
          {onManualSync && (
            <button
              onClick={onManualSync}
              className={`p-2 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors shadow-xs cursor-pointer ${
                isSyncing ? 'text-indigo-600 dark:text-indigo-400' : ''
              }`}
              title={lastSyncTime ? `Base sincronizada: ${lastSyncTime}. Clic para actualizar.` : 'Sincronizar tareas compartidas'}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
            </button>
          )}

          {/* Interactive User Switcher & Permissions Dropdown */}
          <div className="relative" ref={userMenuRef}>
            <button
              onClick={() => setIsUserMenuOpen((prev) => !prev)}
              className="flex items-center gap-2 px-2.5 py-1.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/60 hover:border-indigo-400 dark:hover:border-indigo-600 transition-all cursor-pointer"
              title="Cambiar usuario activo o ver permisología de edición"
            >
              <div className="w-7 h-7 rounded-full bg-slate-900 dark:bg-slate-700 text-white flex items-center justify-center text-xs font-bold ring-2 ring-indigo-500/30">
                {currentUser.initials}
              </div>
              <div className="hidden sm:block text-left">
                <div className="text-xs font-semibold text-slate-800 dark:text-slate-200 leading-tight flex items-center gap-1.5">
                  <span>{currentUser.name}</span>
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" title="Permiso de edición total activo"></span>
                </div>
                <div className="text-[10px] text-slate-500 dark:text-slate-400">
                  {currentUser.role} ({currentUser.initials})
                </div>
              </div>
              <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform ${isUserMenuOpen ? 'rotate-180' : ''}`} />
            </button>

            {/* Dropdown Menu */}
            {isUserMenuOpen && (
              <div className="absolute right-0 mt-2 w-72 sm:w-80 rounded-2xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-2xl p-3 z-50 text-xs animate-in fade-in slide-in-from-top-2">
                <div className="px-2 py-1.5 border-b border-slate-100 dark:border-slate-800 mb-2">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-slate-900 dark:text-white flex items-center gap-1.5">
                      <UserCheck className="w-3.5 h-3.5 text-indigo-600" />
                      <span>Colaboradores Permisados</span>
                    </span>
                    <span className="px-1.5 py-0.5 rounded text-[9px] font-extrabold bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300">
                      Acceso Total
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 leading-snug">
                    Todos los colaboradores permisados pueden <strong>ver el 100% de las tareas</strong> cargadas en el servidor compartido y <strong>modificarlas</strong> directamente.
                  </p>
                </div>

                <div className="max-h-64 overflow-y-auto space-y-1">
                  {collaborators.map((c) => {
                    const isSelected = c.id === currentUser.id;
                    return (
                      <button
                        key={c.id}
                        onClick={() => {
                          if (onSelectUser) onSelectUser(c);
                          setIsUserMenuOpen(false);
                        }}
                        className={`w-full flex items-center justify-between p-2 rounded-xl text-left transition-colors cursor-pointer ${
                          isSelected
                            ? 'bg-indigo-50 dark:bg-indigo-950/60 text-indigo-900 dark:text-indigo-200 font-semibold'
                            : 'hover:bg-slate-100 dark:hover:bg-slate-800/80 text-slate-700 dark:text-slate-300'
                        }`}
                      >
                        <div className="flex items-center gap-2.5 truncate">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold text-white shrink-0 ${c.avatarColor || 'bg-slate-700'}`}>
                            {c.initials}
                          </div>
                          <div className="truncate">
                            <div className="text-xs truncate font-medium">{c.name}</div>
                            <div className="text-[10px] text-slate-400 truncate">{c.email || `${c.initials}@banesco.com`}</div>
                          </div>
                        </div>

                        {isSelected && (
                          <Check className="w-4 h-4 text-indigo-600 dark:text-indigo-400 shrink-0" />
                        )}
                      </button>
                    );
                  })}
                </div>

                <div className="pt-2 mt-2 border-t border-slate-100 dark:border-slate-800 text-[10px] text-slate-400 flex items-center justify-between">
                  <span>Modo: Operador Activo</span>
                  <span className="font-semibold text-emerald-600 dark:text-emerald-400">Edición habilitada</span>
                </div>
              </div>
            )}
          </div>

          {/* Automated SLA Email Notification Monitor Button */}
          {onOpenNotificationDrawer && (
            <button
              onClick={onOpenNotificationDrawer}
              className="relative p-2 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-indigo-50 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 hover:text-indigo-600 dark:text-indigo-400 transition-colors shadow-xs cursor-pointer"
              title="Centro de Avisos Automáticos por Correo (Monitoreo por Próx. Seguimiento)"
            >
              <Bell className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
              {activeOverdueCount > 0 && (
                <span className="absolute -top-1 -right-1 min-w-[16px] h-4 px-1 rounded-full bg-rose-500 text-white font-extrabold text-[9px] flex items-center justify-center animate-pulse shadow-xs">
                  {activeOverdueCount}
                </span>
              )}
            </button>
          )}

          {/* Export Button */}
          <button
            onClick={onOpenExportModal}
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-medium border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300 transition-colors shadow-xs cursor-pointer"
            title="Exportar datos a CSV o JSON"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Exportar</span>
          </button>

          {/* Reset / Reload Button */}
          <button
            onClick={onResetData}
            className="p-2 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors shadow-xs cursor-pointer"
            title="Restablecer datos originales"
          >
            <RotateCcw className="w-3.5 h-3.5" />
          </button>

          {/* Full Screen Mode Toggle for all collaborators */}
          <button
            onClick={handleToggleFullscreen}
            className={`p-2 rounded-xl border transition-colors shadow-xs cursor-pointer ${
              isFullscreen 
                ? 'bg-indigo-50 dark:bg-indigo-950/60 border-indigo-300 dark:border-indigo-700 text-indigo-600 dark:text-indigo-400' 
                : 'border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400'
            }`}
            title={isFullscreen ? 'Salir de pantalla completa' : 'Activar pantalla completa para colaboradores'}
          >
            {isFullscreen ? <Minimize className="w-3.5 h-3.5" /> : <Maximize className="w-3.5 h-3.5" />}
          </button>

          {/* Dark / Light Mode Toggle */}
          <button
            onClick={() => setIsDarkMode((prev) => !prev)}
            className="p-2 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 transition-colors shadow-xs cursor-pointer"
            title={isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro'}
          >
            {isDarkMode ? <Sun className="w-3.5 h-3.5 text-amber-400" /> : <Moon className="w-3.5 h-3.5 text-slate-700" />}
          </button>

          {/* Primary CTA: + Nueva Tarea */}
          <button
            onClick={onOpenNewTaskModal}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 text-white transition-all shadow-sm shadow-indigo-600/25 cursor-pointer"
          >
            <Plus className="w-4 h-4 stroke-[2.5]" />
            <span>Nueva Tarea</span>
          </button>
        </div>
      </div>
    </header>
  );
};
