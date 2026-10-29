import React, { useState } from 'react';
import { 
  X, 
  Bell, 
  CheckCircle2, 
  Mail, 
  Send, 
  Clock, 
  AlertTriangle, 
  ExternalLink, 
  Copy, 
  Check, 
  RefreshCw,
  ShieldCheck,
  Building2,
  UserCheck,
  Info
} from 'lucide-react';
import { Collaborator, Task } from '../types';
import { 
  CORPORATE_SENDER_MAILBOX, 
  CORPORATE_MANDATORY_CC, 
  generateOverdueEmail 
} from '../utils/automatedEmailNotifier';

interface AutomatedNotificationDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  tasks: Task[];
  collaborators: Collaborator[];
  cutoffDate: string;
  onTriggerManualCheck: () => void;
  lastCheckTimestamp: string;
  onOpenDispatchModal?: (task: Task) => void;
  onMarkTaskAsDispatched?: (taskId: string) => void;
}

export const AutomatedNotificationDrawer: React.FC<AutomatedNotificationDrawerProps> = ({
  isOpen,
  onClose,
  tasks,
  collaborators,
  cutoffDate,
  onTriggerManualCheck,
  lastCheckTimestamp,
  onOpenDispatchModal,
  onMarkTaskAsDispatched,
}) => {
  const [copiedId, setCopiedId] = useState<string | null>(null);

  if (!isOpen) return null;

  const todayStr = new Date().toISOString().split('T')[0];

  // All logs across all tasks that were automatically dispatched
  const allAutoLogs = tasks.flatMap((t) =>
    (t.notificationLogs || []).map((l) => ({
      ...l,
      taskTitle: t.title,
      taskCode: t.code || `ACT-${t.id.slice(-4)}`,
      taskId: t.id,
      taskDomain: t.domain,
      taskStatus: t.status,
      nextFollowUpDate: t.nextFollowUpDate,
    }))
  ).sort((a, b) => b.sentAt.localeCompare(a.sentAt));

  // Tasks currently overdue based on nextFollowUpDate
  const overdueTasks = tasks.filter(
    (t) => t.status !== 'Completado' && t.nextFollowUpDate && (t.nextFollowUpDate <= cutoffDate || t.nextFollowUpDate <= todayStr)
  );

  const getCollab = (id: string) => collaborators.find((c) => c.id === id);

  const handleCopyLogText = (log: typeof allAutoLogs[0]) => {
    const text = `De: ${CORPORATE_SENDER_MAILBOX}\nPara: ${log.to}\nCC: ${CORPORATE_MANDATORY_CC}\nAsunto: ${log.subject}\nFecha de emisión: ${log.sentAt}\nDetalle: ${log.messageSnippet}`;
    navigator.clipboard.writeText(text);
    setCopiedId(log.id);
    setTimeout(() => setCopiedId(null), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto animate-in fade-in">
      <div className="bg-white dark:bg-slate-900 w-full max-w-3xl rounded-2xl border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden my-6">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600/10 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <Bell className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <span>Centro de Avisos Automáticos por Correo</span>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-100 text-emerald-700 dark:bg-emerald-950/80 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800 flex items-center gap-1">
                  <ShieldCheck className="w-3 h-3" /> ACTIVO
                </span>
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Monitoreo continuo basado en la fecha de <strong>Próx. Seguimiento</strong>
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
          
          {/* Official Mailbox Identification Banner */}
          <div className="p-4 rounded-xl bg-slate-900 text-white border border-slate-800 flex flex-col md:flex-row items-start md:items-center justify-between gap-3 shadow-sm">
            <div className="space-y-1.5">
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded bg-blue-500/20 text-blue-300 border border-blue-400/30 text-[10px] font-extrabold uppercase tracking-wider">
                  Configuración Banesco
                </span>
                <span className="text-xs font-bold text-slate-200">
                  Canal Oficial de Notificaciones SLA
                </span>
              </div>
              <div className="flex flex-wrap items-center gap-3 text-xs text-slate-300">
                <div className="flex items-center gap-1.5">
                  <Building2 className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Buzón Emisor (De):</span>
                  <strong className="text-white font-mono bg-slate-800 px-2 py-0.5 rounded border border-slate-700">
                    {CORPORATE_SENDER_MAILBOX}
                  </strong>
                </div>
                <div className="flex items-center gap-1.5">
                  <UserCheck className="w-3.5 h-3.5 text-indigo-400" />
                  <span>Copia Obligatoria (CC):</span>
                  <strong className="text-white font-mono bg-slate-800 px-2 py-0.5 rounded border border-slate-700">
                    {CORPORATE_MANDATORY_CC}
                  </strong>
                </div>
              </div>
            </div>

            <button
              onClick={onTriggerManualCheck}
              className="px-3.5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs flex items-center gap-1.5 shrink-0 shadow-xs cursor-pointer transition-all"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Verificar SLAs Ahora</span>
            </button>
          </div>

          {/* Delivery Clarification Note */}
          <div className="p-3.5 rounded-xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 text-amber-900 dark:text-amber-200 flex items-start gap-2.5">
            <Info className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
            <div className="space-y-0.5">
              <span className="font-bold block text-xs">
                Despacho Oficial por Gmail (Google Workspace):
              </span>
              <p className="text-[11px] leading-relaxed">
                Los correos oficiales se canalizan mediante <strong>Gmail (Google Workspace Banesco)</strong> utilizando el buzón corporativo <strong>{CORPORATE_SENDER_MAILBOX}</strong> y con copia permanente (CC) a <strong>{CORPORATE_MANDATORY_CC}</strong>. Al hacer clic en <strong>"Gmail"</strong>, se abre la redacción lista para enviar directamente a la bandeja del colaborador.
              </p>
            </div>
          </div>

          {/* Quick Metrics */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
              <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                Avisos Registrados
              </div>
              <div className="text-xl font-extrabold text-slate-900 dark:text-white mt-1">
                {allAutoLogs.length}
              </div>
              <div className="text-[10px] text-emerald-600 dark:text-emerald-400 font-medium mt-0.5">
                Bitácora de seguimiento
              </div>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
              <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                Tareas con SLA Vencido
              </div>
              <div className="text-xl font-extrabold text-rose-600 dark:text-rose-400 mt-1">
                {overdueTasks.length}
              </div>
              <div className="text-[10px] text-slate-500 font-medium mt-0.5">
                Próx. Seguimiento alcanzado
              </div>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/60">
              <div className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                Jornada Laboral Válida
              </div>
              <div className="text-xl font-extrabold text-indigo-600 dark:text-indigo-400 mt-1">
                8h / día
              </div>
              <div className="text-[10px] text-slate-500 font-medium mt-0.5">
                Lunes a Viernes en "En Proceso"
              </div>
            </div>
          </div>

          {/* Overdue Tasks Requiring Attention */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="font-bold text-slate-800 dark:text-slate-200 text-xs flex items-center gap-1.5">
                <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />
                <span>Tareas con Próx. Seguimiento Vencido o en Fecha Límite ({overdueTasks.length})</span>
              </span>
              <span className="text-[10px] text-slate-400">
                Corte: {cutoffDate}
              </span>
            </div>

            {overdueTasks.length === 0 ? (
              <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700 text-center text-slate-500 text-xs">
                🎉 No hay tareas con fecha de seguimiento vencida en este momento.
              </div>
            ) : (
              <div className="space-y-2.5 max-h-56 overflow-y-auto">
                {overdueTasks.map((t) => {
                  const collab = getCollab(t.collaboratorId);
                  const p = generateOverdueEmail(t, collab);

                  return (
                    <div
                      key={t.id}
                      className="p-3 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
                    >
                      <div className="space-y-0.5 truncate">
                        <div className="flex items-center gap-1.5">
                          <span className="font-bold text-slate-900 dark:text-white truncate">
                            {t.title}
                          </span>
                          <span className="px-1.5 py-0.2 rounded-md bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 text-[10px]">
                            {t.domain}
                          </span>
                        </div>
                        <div className="text-[11px] text-slate-500 dark:text-slate-400 flex flex-wrap items-center gap-2">
                          <span>Resp: <strong>{collab?.name || 'Sin asignar'}</strong></span>
                          <span>•</span>
                          <span className="text-rose-600 dark:text-rose-400 font-semibold">
                            Próx. Seguimiento: {t.nextFollowUpDate}
                          </span>
                          <span>•</span>
                          <span>{t.hoursInvested}h / {t.hoursEstimated}h</span>
                        </div>
                      </div>

                      <div className="flex flex-wrap items-center gap-1.5 shrink-0">
                        {/* Direct Gmail Web anchor */}
                        <a
                          href={p.gmailWebUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={() => {
                            if (onMarkTaskAsDispatched) onMarkTaskAsDispatched(t.id);
                          }}
                          className="px-2.5 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 text-white font-semibold flex items-center gap-1 text-[11px] shadow-2xs transition-colors cursor-pointer"
                          title={`Despachar desde ${CORPORATE_SENDER_MAILBOX} con CC a ${CORPORATE_MANDATORY_CC} vía Gmail`}
                        >
                          <ExternalLink className="w-3 h-3" />
                          <span>Gmail</span>
                        </a>

                        {/* Direct Desktop Client anchor */}
                        <a
                          href={p.mailtoUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={() => {
                            if (onMarkTaskAsDispatched) onMarkTaskAsDispatched(t.id);
                          }}
                          className="px-2 py-1.5 rounded-lg bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200 font-semibold flex items-center gap-1 text-[11px] transition-colors cursor-pointer"
                          title="Abrir en cliente local (mailto)"
                        >
                          <Send className="w-3 h-3" />
                          <span>Local</span>
                        </a>

                        {/* Open Dispatch modal */}
                        {onOpenDispatchModal && (
                          <button
                            onClick={() => onOpenDispatchModal(t)}
                            className="px-2 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 font-semibold text-[11px] cursor-pointer"
                            title="Ver formato completo y buzones"
                          >
                            Ver Correo
                          </button>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Log of automatically dispatched emails */}
          <div className="pt-2">
            <span className="font-bold text-slate-800 dark:text-slate-200 text-xs mb-2 block">
              Historial de Avisos por Correo Electrónico ({allAutoLogs.length})
            </span>

            {allAutoLogs.length === 0 ? (
              <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700 text-center text-slate-500 text-xs">
                Aún no se han emitido avisos automáticos. Cuando una tarea alcance la fecha de Próx. Seguimiento, aparecerá registrada aquí.
              </div>
            ) : (
              <div className="space-y-2 max-h-52 overflow-y-auto">
                {allAutoLogs.map((log) => (
                  <div
                    key={log.id}
                    className="p-3 rounded-xl bg-slate-50/80 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700/80 space-y-1.5 text-xs"
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2 truncate">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                        <span className="font-bold text-slate-900 dark:text-white truncate">
                          {log.subject}
                        </span>
                      </div>
                      <span className="text-[10px] text-slate-400 shrink-0">
                        {log.sentAt}
                      </span>
                    </div>

                    <div className="text-[11px] text-slate-600 dark:text-slate-300 flex flex-wrap items-center justify-between gap-2">
                      <div className="flex flex-wrap items-center gap-3">
                        <span><strong>De:</strong> <span className="font-mono text-indigo-600 dark:text-indigo-400">{log.from || CORPORATE_SENDER_MAILBOX}</span></span>
                        <span><strong>Para:</strong> {log.to}</span>
                        <span><strong>CC:</strong> <span className="font-mono text-indigo-600 dark:text-indigo-400">{log.cc || CORPORATE_MANDATORY_CC}</span></span>
                      </div>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => handleCopyLogText(log)}
                          className="text-slate-500 hover:text-indigo-600 flex items-center gap-1 text-[10px] font-semibold cursor-pointer"
                        >
                          {copiedId === log.id ? <Check className="w-3 h-3 text-emerald-500" /> : <Copy className="w-3 h-3" />}
                          <span>{copiedId === log.id ? 'Copiado' : 'Copiar'}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-6 py-3 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">
          <div className="text-[11px] text-slate-500 dark:text-slate-400 flex items-center gap-1">
            <Clock className="w-3.5 h-3.5" />
            <span>Última verificación del sistema: {lastCheckTimestamp || 'En vivo'}</span>
          </div>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 dark:bg-slate-700 dark:hover:bg-slate-600 text-white font-semibold text-xs transition-colors cursor-pointer"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
};
