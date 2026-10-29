import React, { useState, useEffect } from 'react';
import { 
  X, 
  Plus, 
  Trash2, 
  CheckSquare, 
  Mail, 
  Send, 
  Bell, 
  AlertTriangle, 
  CheckCircle2, 
  Eye, 
  EyeOff, 
  Clock, 
  UserCheck, 
  Check,
  RefreshCw,
  Zap,
  ExternalLink,
  Maximize2,
  Minimize2
} from 'lucide-react';
import { Collaborator, Domain, Priority, Task, TaskStatus, TaskType, EmailNotificationLog } from '../types';
import { calculateWorkingHoursBetween, getTaskInvestedHours } from '../utils/workingHours';
import { CORPORATE_SENDER_MAILBOX, CORPORATE_MANDATORY_CC, buildGmailComposeUrl, openGmailWeb, openMailClient } from '../utils/automatedEmailNotifier';

interface TaskModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (task: Task) => void;
  initialTask?: Task | null;
  collaborators: Collaborator[];
  currentInitials: string;
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

const STATUSES: TaskStatus[] = ['Pendiente', 'En Proceso', 'En Revisión', 'Completado', 'Bloqueado'];

export const TaskModal: React.FC<TaskModalProps> = ({
  isOpen,
  onClose,
  onSave,
  initialTask,
  collaborators,
  currentInitials,
}) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [type, setType] = useState<TaskType>('Actividad');
  const [domain, setDomain] = useState<Domain>('Windows');
  const [collaboratorId, setCollaboratorId] = useState('');
  const [priority, setPriority] = useState<Priority>('Alta');
  const [status, setStatus] = useState<TaskStatus>('En Proceso');
  const [nextFollowUpDate, setNextFollowUpDate] = useState('');
  const [hoursEstimated, setHoursEstimated] = useState<number>(20);
  const [hoursInvested, setHoursInvested] = useState<number>(0);
  const [companyUnit, setCompanyUnit] = useState('Banesco');
  const [notes, setNotes] = useState('');
  const [newSubtaskTitle, setNewSubtaskTitle] = useState('');
  const [subtasks, setSubtasks] = useState<{ id: string; title: string; completed: boolean }[]>([]);

  // Modal Full Screen State (always opens in full screen for all collaborators)
  const [isFullScreen, setIsFullScreen] = useState<boolean>(true);

  // Email Notification States
  const [notifyOnOverdue, setNotifyOnOverdue] = useState<boolean>(true);
  const [notificationEmail, setNotificationEmail] = useState('');
  const [notificationCc, setNotificationCc] = useState(CORPORATE_MANDATORY_CC);
  const [customNotificationMessage, setCustomNotificationMessage] = useState('');
  const [notificationLogs, setNotificationLogs] = useState<EmailNotificationLog[]>([]);
  const [lastNotificationSentAt, setLastNotificationSentAt] = useState<string | undefined>(undefined);
  const [showEmailPreview, setShowEmailPreview] = useState(false);
  const [dispatchFeedback, setDispatchFeedback] = useState<string | null>(null);
  const [copiedPreview, setCopiedPreview] = useState(false);

  // Working Hours Tracking States (8h/día Lun-Vie en estado "En Proceso")
  const [inProgressStartedAt, setInProgressStartedAt] = useState<string | undefined>(undefined);
  const [accumulatedWorkHours, setAccumulatedWorkHours] = useState<number>(0);

  // Helper to find collaborator's default email
  const getCollaboratorEmail = (collabId: string): string => {
    const c = collaborators.find((item) => item.id === collabId);
    if (!c) return '';
    if (c.email) return c.email;
    const cleanName = c.name.toLowerCase().replace(/\s+/g, '.');
    return `${cleanName}@banesco.com`;
  };

  useEffect(() => {
    if (initialTask) {
      setTitle(initialTask.title);
      setDescription(initialTask.description || '');
      setType(initialTask.type);
      setDomain(initialTask.domain);
      setCollaboratorId(initialTask.collaboratorId);
      setPriority(initialTask.priority);
      setStatus(initialTask.status);
      setNextFollowUpDate(initialTask.nextFollowUpDate);
      setHoursEstimated(initialTask.hoursEstimated || 0);
      setCompanyUnit(initialTask.companyUnit || 'Banesco');
      setNotes(initialTask.notes || '');
      setSubtasks(initialTask.subtasks || []);

      // Working hours tracking
      setInProgressStartedAt(initialTask.inProgressStartedAt);
      setAccumulatedWorkHours(initialTask.accumulatedWorkHours || 0);

      // Si está en proceso, calcular horas actuales de jornada laboral (8h/día Lun-Vie)
      if (initialTask.status === 'En Proceso') {
        const liveHours = getTaskInvestedHours(initialTask);
        setHoursInvested(liveHours);
      } else {
        setHoursInvested(initialTask.hoursInvested || 0);
      }

      // Load email notification settings
      setNotifyOnOverdue(initialTask.notifyOnOverdue ?? true);
      setNotificationEmail(initialTask.notificationEmail || getCollaboratorEmail(initialTask.collaboratorId));
      setNotificationCc(CORPORATE_MANDATORY_CC);
      setCustomNotificationMessage(initialTask.customNotificationMessage || '');
      setNotificationLogs(initialTask.notificationLogs || []);
      setLastNotificationSentAt(initialTask.lastNotificationSentAt);
    } else {
      // Defaults for new task
      const defaultCollabId = collaborators[0]?.id || '';
      setTitle('');
      setDescription('');
      setType('Actividad');
      setDomain('Windows');
      setCollaboratorId(defaultCollabId);
      setPriority('Alta');
      setStatus('Pendiente');
      setNextFollowUpDate(new Date().toISOString().split('T')[0]);
      setHoursEstimated(25);
      setHoursInvested(0);
      setInProgressStartedAt(undefined);
      setAccumulatedWorkHours(0);
      setCompanyUnit('Banesco');
      setNotes('');
      setSubtasks([]);

      // Email defaults
      setNotifyOnOverdue(true);
      setNotificationEmail(getCollaboratorEmail(defaultCollabId));
      setNotificationCc(CORPORATE_MANDATORY_CC);
      setCustomNotificationMessage('');
      setNotificationLogs([]);
      setLastNotificationSentAt(undefined);
    }
    setDispatchFeedback(null);
    setShowEmailPreview(false);
    if (isOpen) {
      setIsFullScreen(true);
    }
  }, [initialTask, isOpen, collaborators]);

  if (!isOpen) return null;

  const handleCollaboratorChange = (newCollabId: string) => {
    setCollaboratorId(newCollabId);
    // Auto-update email to match new collaborator
    setNotificationEmail(getCollaboratorEmail(newCollabId));
  };

  const handleStatusChange = (newStatus: TaskStatus) => {
    const now = new Date();
    const nowIso = now.toISOString();

    if (status !== 'En Proceso' && newStatus === 'En Proceso') {
      // Pasando a "En Proceso": iniciar conteo de horas laborales
      const started = inProgressStartedAt || nowIso;
      setInProgressStartedAt(started);
      const elapsed = calculateWorkingHoursBetween(started, now);
      const total = Math.round((accumulatedWorkHours + elapsed) * 10) / 10;
      setHoursInvested(total);
    } else if (status === 'En Proceso' && newStatus !== 'En Proceso') {
      // Saliendo de "En Proceso": congelar las horas de jornada laboral
      if (inProgressStartedAt) {
        const elapsed = calculateWorkingHoursBetween(inProgressStartedAt, now);
        const total = Math.round((accumulatedWorkHours + elapsed) * 10) / 10;
        setAccumulatedWorkHours(total);
        setHoursInvested(total);
      }
    }
    setStatus(newStatus);
  };

  const handleRecalculateHours = () => {
    const now = new Date();
    const started = inProgressStartedAt || now.toISOString();
    if (!inProgressStartedAt) setInProgressStartedAt(started);
    const elapsed = calculateWorkingHoursBetween(started, now);
    const total = Math.round((accumulatedWorkHours + elapsed) * 10) / 10;
    setHoursInvested(total);
  };

  const handleAddSubtask = () => {
    if (!newSubtaskTitle.trim()) return;
    setSubtasks((prev) => [
      ...prev,
      { id: `st-${Date.now()}`, title: newSubtaskTitle.trim(), completed: false },
    ]);
    setNewSubtaskTitle('');
  };

  const handleRemoveSubtask = (id: string) => {
    setSubtasks((prev) => prev.filter((s) => s.id !== id));
  };

  const handleToggleSubtask = (id: string) => {
    setSubtasks((prev) =>
      prev.map((s) => (s.id === id ? { ...s, completed: !s.completed } : s))
    );
  };

  // Determine if task is overdue relative to today
  const todayStr = new Date().toISOString().split('T')[0];
  const isOverdue = Boolean(
    nextFollowUpDate &&
    status !== 'Completado' &&
    nextFollowUpDate < todayStr
  );

  // Generate formal notification subject & body
  const selectedCollaborator = collaborators.find((c) => c.id === collaboratorId);
  const collaboratorName = selectedCollaborator?.name || 'Colaborador';
  const taskCode = initialTask?.code || (type === 'Proyecto' ? 'PRJ-NEW' : 'ACT-NEW');

  const emailSubject = `[AVISO VENCIMIENTO SLA] ${type}: ${title || 'Actividad Sin Título'} - SLA: ${nextFollowUpDate || 'Por definir'}`;
  
  const diaEnvio = new Date().toLocaleDateString('es-ES');

  const emailBody = `Estimado(a) ${collaboratorName},

Se le notifica formalmente que la siguiente asignación bajo su responsabilidad en la Gerencia de Administración de Seguridad ha alcanzado o superado su fecha de seguimiento / vencimiento de SLA:

==================================================
DETALLES DE LA ACTIVIDAD:
• Requerimiento: ${title || 'Sin Título'}
• Tipo: ${type}
• Dominio: ${domain}
• Prioridad: ${priority}
• Estado Actual: ${status}
• Fecha Próx. Seguimiento (SLA): ${nextFollowUpDate}
• Horas Invertidas (8h lun-vie): ${hoursInvested}h / ${hoursEstimated}h est.
• Empresa / Unidad: ${companyUnit || 'Banesco'}
==================================================

${customNotificationMessage.trim() ? `INSTRUCCIÓN DEL LÍDER / CONTROL DE GESTIÓN:\n"${customNotificationMessage.trim()}"\n\n` : ''}ACCIÓN REQUERIDA:
Por favor ingresar al Dashboard de Control de Gestión para actualizar el estatus de la asignación y reportar causas de desviación.

Atentamente,
Control de Gestión - Gcia Administración Seguridad
Buzón Emisor Oficial: administracion_de_informacion_ve@banesco.com
Supervisión CC Permanente: aguevara@banesco.com
Fecha de Emisión: ${diaEnvio}`;

  const targetEmailAddress = notificationEmail.trim() || getCollaboratorEmail(collaboratorId);
  const mailtoUrl = `mailto:${encodeURIComponent(targetEmailAddress)}?cc=${encodeURIComponent(CORPORATE_MANDATORY_CC)}&subject=${encodeURIComponent(emailSubject)}&body=${encodeURIComponent(emailBody)}`;
  const gmailWebUrl = buildGmailComposeUrl(targetEmailAddress, CORPORATE_MANDATORY_CC, emailSubject, emailBody, CORPORATE_SENDER_MAILBOX);

  // Direct trigger function for email notice
  const handleTriggerEmailAlert = (method: 'gmail' | 'mailto' = 'gmail') => {
    const targetEmail = targetEmailAddress;
    if (!targetEmail) {
      setDispatchFeedback('⚠️ Por favor ingresa una dirección de correo válida para el colaborador.');
      return;
    }

    const timestamp = new Date().toLocaleString('es-ES', { 
      day: '2-digit', 
      month: '2-digit', 
      year: 'numeric', 
      hour: '2-digit', 
      minute: '2-digit', 
      second: '2-digit' 
    });

    // 1. Open client according to selected method
    if (method === 'gmail') {
      openGmailWeb(gmailWebUrl);
    } else {
      openMailClient(mailtoUrl);
    }

    // 2. Register dispatch log
    const newLog: EmailNotificationLog = {
      id: `log-${Date.now()}`,
      sentAt: timestamp,
      from: CORPORATE_SENDER_MAILBOX,
      to: targetEmail,
      cc: CORPORATE_MANDATORY_CC,
      subject: emailSubject,
      triggeredBy: currentInitials,
      messageSnippet: `Aviso oficial preparado desde ${CORPORATE_SENDER_MAILBOX} con CC a ${CORPORATE_MANDATORY_CC} (${method === 'gmail' ? 'Gmail Web' : 'Cliente Local'})`,
      status: 'sent',
    };

    setNotificationLogs((prev) => [newLog, ...prev]);
    setLastNotificationSentAt(timestamp);
    setDispatchFeedback(`✅ Redacción en Gmail (Google Workspace) abierta con remitente: ${CORPORATE_SENDER_MAILBOX} y CC: ${CORPORATE_MANDATORY_CC}. Presiona Enviar.`);

    // Hide feedback after 8 seconds
    setTimeout(() => {
      setDispatchFeedback(null);
    }, 8000);
  };

  const handleCopyEmailText = () => {
    const textToCopy = `De: ${CORPORATE_SENDER_MAILBOX}\nPara: ${notificationEmail}\nCC: ${CORPORATE_MANDATORY_CC}\nAsunto: ${emailSubject}\n\n${emailBody}`;
    navigator.clipboard.writeText(textToCopy);
    setCopiedPreview(true);
    setTimeout(() => setCopiedPreview(false), 2500);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    const finalInvested = Number(hoursInvested) || 0;
    const taskToSave: Task = {
      id: initialTask?.id || `task-${Date.now()}`,
      code: initialTask?.code || (type === 'Proyecto' ? `PRJ-${Math.floor(100 + Math.random() * 900)}` : `ACT-${Math.floor(100 + Math.random() * 900)}`),
      title: title.trim(),
      description: description.trim(),
      type,
      domain,
      collaboratorId,
      priority,
      status,
      nextFollowUpDate,
      creationDate: initialTask?.creationDate || todayStr,
      lastModifiedBy: currentInitials,
      lastModifiedDate: todayStr,
      hoursEstimated: Number(hoursEstimated) || 0,
      hoursInvested: finalInvested,
      companyUnit,
      notes: notes.trim(),
      subtasks,
      // Working hours fields (8h/día lun-vie en 'En Proceso')
      inProgressStartedAt: status === 'En Proceso' ? (inProgressStartedAt || new Date().toISOString()) : undefined,
      accumulatedWorkHours: status === 'En Proceso' ? accumulatedWorkHours : finalInvested,
      // Persist email notification configuration with mandatory corporate mailbox and CC
      notifyOnOverdue,
      notificationFrom: CORPORATE_SENDER_MAILBOX,
      notificationEmail: notificationEmail.trim(),
      notificationCc: CORPORATE_MANDATORY_CC,
      customNotificationMessage: customNotificationMessage.trim(),
      lastNotificationSentAt,
      notificationLogs,
    };

    onSave(taskToSave);
    onClose();
  };

  return (
    <div className={`fixed inset-0 z-50 flex items-center justify-center bg-slate-900/70 backdrop-blur-xs ${isFullScreen ? 'p-0 sm:p-2' : 'p-3 sm:p-4 overflow-y-auto'}`}>
      <div className={`bg-white dark:bg-slate-900 w-full border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden flex flex-col transition-all duration-200 ${
        isFullScreen 
          ? 'h-full sm:h-[98vh] max-w-full sm:max-w-[98vw] rounded-none sm:rounded-2xl' 
          : 'max-w-4xl rounded-2xl max-h-[90vh] my-6'
      }`}>
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-3.5 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600/10 dark:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold shrink-0">
              <Mail className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <span>{initialTask ? 'Modificar Actividad / Requerimiento' : 'Nueva Actividad o Proyecto'}</span>
                {Boolean(initialTask) && isOverdue && (
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-rose-100 text-rose-700 dark:bg-rose-950/80 dark:text-rose-400 border border-rose-200 dark:border-rose-800 flex items-center gap-1">
                    <AlertTriangle className="w-3 h-3" /> VENCIDA
                  </span>
                )}
                {isFullScreen && (
                  <span className="px-2 py-0.5 rounded-md text-[10px] font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800/60 hidden sm:inline-block">
                    Pantalla Completa
                  </span>
                )}
              </h3>
              <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                <span>Control de Gestión Gcia Administración Seguridad</span>
                <span>•</span>
                <span className="text-slate-700 dark:text-slate-300 font-medium">Operador: <strong className="text-indigo-600 dark:text-indigo-400">{currentInitials}</strong></span>
                <span>•</span>
                <span className="text-emerald-600 dark:text-emerald-400 font-semibold">Permiso Total Activo</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            <button
              type="button"
              onClick={() => setIsFullScreen((prev) => !prev)}
              className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
              title={isFullScreen ? 'Reducir tamaño' : 'Pantalla completa'}
            >
              {isFullScreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
              title="Cerrar modal (Esc)"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-4 sm:p-6 overflow-y-auto flex-1 flex flex-col justify-between text-xs space-y-4">
          
          {/* Overdue alert banner if applicable (solo visible en actividades existentes vencidas) */}
          {Boolean(initialTask) && isOverdue && (
            <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/60 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-rose-800 dark:text-rose-300">
              <div className="flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
                <span>
                  <strong>Atención:</strong> Esta tarea tiene fecha de vencimiento superada (<strong>{nextFollowUpDate}</strong>). Puedes disparar un aviso por correo electrónico de inmediato.
                </span>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <button
                  type="button"
                  onClick={() => handleTriggerEmailAlert('gmail')}
                  className="px-3 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 text-white font-bold flex items-center gap-1.5 text-[11px] shadow-xs cursor-pointer"
                  title="Enviar aviso vía Gmail con buzón administracion_de_informacion_ve@banesco.com"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  <span>Enviar vía Gmail</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleTriggerEmailAlert('mailto')}
                  className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-white font-bold flex items-center gap-1.5 text-[11px] shadow-xs cursor-pointer"
                  title="Abrir en cliente local (mailto)"
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>Cliente Local</span>
                </button>
              </div>
            </div>
          )}

          {/* Feedback banner after triggering email */}
          {dispatchFeedback && (
            <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-300 flex items-center gap-2 animate-in fade-in">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
              <span className="font-semibold">{dispatchFeedback}</span>
            </div>
          )}

          {/* Responsive Layout: Dos columnas al Modificar; Columna completa limpia al crear Nueva Actividad */}
          <div className={Boolean(initialTask) && isFullScreen ? 'grid grid-cols-1 lg:grid-cols-12 gap-6 items-start' : 'space-y-4 max-w-4xl mx-auto w-full'}>
            {/* Left Column: Task Technical Specifications */}
            <div className={Boolean(initialTask) && isFullScreen ? 'lg:col-span-7 space-y-4' : 'space-y-4'}>
              {/* Title */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Actividad / Requerimiento *
                </label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Ej: MFA del AS400 debe tener una contingencia en el CSO..."
              className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-hidden"
            />
          </div>

          {/* Description */}
          <div>
            <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
              Descripción / Alcance Técnico
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Detalla los entregables, hallazgos o justificación técnica..."
              className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-hidden"
            />
          </div>

          {/* Row: Tipo + Dominio + Empresa */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Tipo
              </label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as TaskType)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              >
                <option value="Actividad">Actividad</option>
                <option value="Proyecto">Proyecto</option>
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Dominio
              </label>
              <select
                value={domain}
                onChange={(e) => setDomain(e.target.value as Domain)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 truncate"
              >
                {DOMAINS.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Empresa / Unidad
              </label>
              <select
                value={companyUnit}
                onChange={(e) => setCompanyUnit(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              >
                <option value="Banesco">Banesco</option>
                <option value="BBU">BBU</option>
                <option value="CSO">CSO</option>
                <option value="Global">Global</option>
              </select>
            </div>
          </div>

          {/* Row: Responsable + Prioridad + Estado */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Responsable / Colaborador *
              </label>
              <select
                value={collaboratorId}
                onChange={(e) => handleCollaboratorChange(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              >
                {collaborators.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} ({c.initials})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Prioridad
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value as Priority)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              >
                {PRIORITIES.map((p) => (
                  <option key={p} value={p}>
                    {p}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Estado
              </label>
              <select
                value={status}
                onChange={(e) => handleStatusChange(e.target.value as TaskStatus)}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              >
                {STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Row: Próximo Seguimiento + Horas Estimadas + Horas Invertidas */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1 flex items-center justify-between">
                <span>Próx. Seguimiento / SLA *</span>
                {isOverdue && (
                  <span className="text-[10px] text-rose-500 font-bold">VENCIDO</span>
                )}
              </label>
              <input
                type="date"
                required
                value={nextFollowUpDate}
                onChange={(e) => setNextFollowUpDate(e.target.value)}
                className={`w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border ${
                  isOverdue ? 'border-rose-400 dark:border-rose-600 focus:ring-rose-500' : 'border-slate-200 dark:border-slate-700 focus:ring-indigo-500'
                } text-slate-800 dark:text-slate-200`}
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                Horas Estimadas (Total)
              </label>
              <input
                type="number"
                min="0"
                value={hoursEstimated}
                onChange={(e) => setHoursEstimated(Number(e.target.value))}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200"
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1 flex items-center justify-between">
                <span>Horas Invertidas (Reales)</span>
                {status === 'En Proceso' && (
                  <button
                    type="button"
                    onClick={handleRecalculateHours}
                    className="text-[10px] text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-1 font-semibold cursor-pointer"
                    title="Recalcular horas laborales en jornada 8h/día Lun-Vie"
                  >
                    <RefreshCw className="w-2.5 h-2.5" />
                    <span>Recalcular 8h/día</span>
                  </button>
                )}
              </label>
              <input
                type="number"
                step="0.5"
                min="0"
                value={hoursInvested}
                onChange={(e) => setHoursInvested(Number(e.target.value))}
                className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 font-semibold"
              />
            </div>
          </div>

          {/* Validation Banner: Working hours (8h/day Mon-Fri) in 'En Proceso' */}
          {status === 'En Proceso' && (
            <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-900/60 text-blue-900 dark:text-blue-200 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-blue-600 dark:text-blue-400 shrink-0" />
                <span>
                  <strong>Cálculo Automático de Jornada Laboral:</strong> Contabilizando <strong>8 horas diarias (lunes a viernes)</strong> desde que el estado pasó a <em>"En Proceso"</em>.
                </span>
              </div>
              <span className="font-extrabold bg-blue-100 dark:bg-blue-900/60 px-2.5 py-1 rounded-lg text-[11px] text-blue-800 dark:text-blue-300 shrink-0">
                {hoursInvested}h acumuladas ({Math.min(100, Math.round((hoursInvested / (hoursEstimated || 1)) * 100))}% progreso)
              </span>
            </div>
          )}

              {/* Subtasks / Checklist */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Subtareas y Puntos de Control
                </label>
                <div className="flex items-center gap-2 mb-2">
                  <input
                    type="text"
                    value={newSubtaskTitle}
                    onChange={(e) => setNewSubtaskTitle(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        handleAddSubtask();
                      }
                    }}
                    placeholder="Añadir hito o entregable específico..."
                    className="flex-1 px-3 py-1.5 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white"
                  />
                  <button
                    type="button"
                    onClick={handleAddSubtask}
                    className="px-3 py-1.5 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 font-semibold rounded-lg flex items-center gap-1 cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Agregar</span>
                  </button>
                </div>

                {subtasks.length > 0 && (
                  <div className="space-y-1.5 p-2 bg-slate-50 dark:bg-slate-800/40 rounded-xl border border-slate-200 dark:border-slate-700/60 max-h-36 overflow-y-auto">
                    {subtasks.map((st) => (
                      <div key={st.id} className="flex items-center justify-between gap-2 text-xs">
                        <div
                          onClick={() => handleToggleSubtask(st.id)}
                          className="flex items-center gap-2 cursor-pointer flex-1 select-none"
                        >
                          <CheckSquare className={`w-3.5 h-3.5 ${st.completed ? 'text-emerald-500' : 'text-slate-400'}`} />
                          <span className={st.completed ? 'line-through text-slate-400' : 'text-slate-700 dark:text-slate-300'}>
                            {st.title}
                          </span>
                        </div>
                        <button
                          type="button"
                          onClick={() => handleRemoveSubtask(st.id)}
                          className="text-slate-400 hover:text-rose-500 p-0.5 cursor-pointer"
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Notes */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Notas de Seguimiento / Bitácora
                </label>
                <input
                  type="text"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  placeholder="Ej: Aprobado por el comité de seguridad el 17 de agosto..."
                  className="w-full px-3 py-2 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white"
                />
              </div>
            </div>

            {/* Right Column: SLA Email, Notifications & Corporate Governance (Solo visible al Modificar Actividad existente) */}
            {Boolean(initialTask) && (
              <div className={isFullScreen ? 'lg:col-span-5 space-y-4' : 'space-y-4'}>
                {/* ========================================================= */}
                {/* SECTION: AVISO POR CORREO ELECTRÓNICO AL VENCIMIENTO     */}
                {/* ========================================================= */}
                <div className="p-4 rounded-xl border border-indigo-200 dark:border-indigo-900/60 bg-indigo-50/40 dark:bg-indigo-950/20 space-y-3">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-indigo-100 dark:border-indigo-900/40 pb-2.5">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-indigo-600 text-white">
                  <Bell className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-bold text-indigo-950 dark:text-indigo-200 text-xs sm:text-sm flex items-center gap-1.5">
                    <span>Aviso Automático por Correo al Vencimiento</span>
                    <span className="px-2 py-0.2 rounded-full text-[10px] font-bold bg-indigo-100 dark:bg-indigo-900/80 text-indigo-700 dark:text-indigo-300">
                      Próx. Seguimiento
                    </span>
                  </h4>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400">
                    Envío 100% automático al cumplirse la fecha de Próx. Seguimiento, con opción de disparo manual anticipado
                  </p>
                </div>
              </div>

              {/* Toggle Enable */}
              <label className="inline-flex items-center gap-2 cursor-pointer self-start sm:self-auto select-none">
                <input
                  type="checkbox"
                  checked={notifyOnOverdue}
                  onChange={(e) => setNotifyOnOverdue(e.target.checked)}
                  className="w-4 h-4 text-indigo-600 rounded-sm border-slate-300 focus:ring-indigo-500"
                />
                <span className="font-semibold text-slate-700 dark:text-slate-300 text-xs">
                  Habilitar avisos automáticos
                </span>
              </label>
            </div>

            {/* Automation Info Callout */}
            <div className="p-2.5 rounded-xl bg-indigo-100/60 dark:bg-indigo-900/30 border border-indigo-200 dark:border-indigo-800 text-[11px] text-indigo-950 dark:text-indigo-200 flex items-center gap-2">
              <Zap className="w-4 h-4 text-indigo-600 dark:text-indigo-400 shrink-0" />
              <span>
                <strong>Regla de Envío Automático:</strong> El sistema evalúa diariamente la fecha <strong>{nextFollowUpDate || '(por definir)'}</strong> (Próx. Seguimiento). Al vencerse, dispara automáticamente la notificación formal al colaborador.
              </span>
            </div>

            {notifyOnOverdue && (
              <div className="space-y-3 pt-1">
                {/* Senders & Recipients Row */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1 flex items-center justify-between">
                      <span className="flex items-center gap-1">
                        <Send className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" /> Buzón Emisor (De) *
                      </span>
                      <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-semibold">Oficial</span>
                    </label>
                    <input
                      type="text"
                      readOnly
                      value={CORPORATE_SENDER_MAILBOX}
                      className="w-full px-3 py-2 rounded-xl bg-slate-100 dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 font-mono text-[11px] font-semibold cursor-not-allowed"
                    />
                    <span className="text-[10px] text-slate-400 mt-0.5 block">Buzón corporativo de seguridad</span>
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1 flex items-center justify-between">
                      <span className="flex items-center gap-1">
                        <Mail className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" /> Destinatario (Para) *
                      </span>
                      {selectedCollaborator && (
                        <span className="text-[10px] text-slate-400 font-normal">
                          {selectedCollaborator.name}
                        </span>
                      )}
                    </label>
                    <input
                      type="email"
                      required={notifyOnOverdue}
                      value={notificationEmail}
                      onChange={(e) => setNotificationEmail(e.target.value)}
                      placeholder="nombre.apellido@banesco.com"
                      className="w-full px-3 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white"
                    />
                    <span className="text-[10px] text-slate-400 mt-0.5 block">Correo del colaborador responsable</span>
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1 flex items-center justify-between">
                      <span className="flex items-center gap-1">
                        <UserCheck className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" /> Con Copia (CC Fijo) *
                      </span>
                      <span className="text-[10px] text-indigo-600 dark:text-indigo-400 font-semibold">Obligatorio</span>
                    </label>
                    <input
                      type="text"
                      readOnly
                      value={CORPORATE_MANDATORY_CC}
                      className="w-full px-3 py-2 rounded-xl bg-slate-100 dark:bg-slate-800/90 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-200 font-mono text-[11px] font-semibold cursor-not-allowed"
                    />
                    <span className="text-[10px] text-slate-400 mt-0.5 block">Supervisión fija requerida</span>
                  </div>
                </div>

                {/* Delivery Guarantee Explanation Callout */}
                <div className="p-3 rounded-xl bg-amber-50/80 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/60 text-[11px] text-amber-900 dark:text-amber-200 flex items-start gap-2.5">
                  <Mail className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                  <div>
                    <strong className="block font-bold">Despacho Oficial por Gmail (Google Workspace):</strong>
                    Para que el correo ingrese a la bandeja de <strong>{notificationEmail || 'destinatario'}</strong>, haz clic en <strong>"Enviar vía Gmail"</strong>. Se abrirá la redacción oficial en Gmail con el remitente corporativo <em>{CORPORATE_SENDER_MAILBOX}</em> y copia permanente a <em>{CORPORATE_MANDATORY_CC}</em> listo para enviar.
                  </div>
                </div>

                {/* Custom note to collaborator */}
                <div>
                  <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
                    Instrucciones u Observaciones para el Aviso (Opcional)
                  </label>
                  <input
                    type="text"
                    value={customNotificationMessage}
                    onChange={(e) => setCustomNotificationMessage(e.target.value)}
                    placeholder="Ej: Favor coordinar con el equipo de infraestructura antes del cierre semanal..."
                    className="w-full px-3 py-2 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-900 dark:text-white"
                  />
                </div>

                {/* Action Bar: Gmail Web + Desktop + Preview */}
                <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-indigo-100 dark:border-indigo-900/40">
                  <div className="flex flex-wrap items-center gap-2">
                    <a
                      href={gmailWebUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={() => handleTriggerEmailAlert('gmail')}
                      className="px-3.5 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold flex items-center gap-2 shadow-xs transition-all cursor-pointer"
                      title="Abrir redacción en Gmail (Google Workspace) con buzón administracion_de_informacion_ve@banesco.com"
                    >
                      <ExternalLink className="w-4 h-4" />
                      <span>Enviar vía Gmail ({CORPORATE_SENDER_MAILBOX})</span>
                    </a>

                    <a
                      href={mailtoUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={() => handleTriggerEmailAlert('mailto')}
                      className="px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold flex items-center gap-2 shadow-xs transition-all cursor-pointer"
                      title="Abrir en cliente de correo local"
                    >
                      <Send className="w-4 h-4" />
                      <span>Abrir en Cliente Local</span>
                    </a>

                    <button
                      type="button"
                      onClick={() => setShowEmailPreview((prev) => !prev)}
                      className="px-3 py-2 rounded-xl border border-indigo-200 dark:border-indigo-800 text-indigo-700 dark:text-indigo-300 hover:bg-indigo-100/50 dark:hover:bg-indigo-900/40 font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
                    >
                      {showEmailPreview ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                      <span>{showEmailPreview ? 'Ocultar Formato' : 'Ver Plantilla'}</span>
                    </button>
                  </div>

                  {lastNotificationSentAt && (
                    <div className="text-[11px] text-emerald-700 dark:text-emerald-400 flex items-center gap-1 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-1 rounded-lg border border-emerald-200 dark:border-emerald-900/50">
                      <Clock className="w-3.5 h-3.5" />
                      <span>Último aviso: {lastNotificationSentAt}</span>
                    </div>
                  )}
                </div>

                {/* Email Preview Card */}
                {showEmailPreview && (
                  <div className="mt-3 p-3.5 rounded-xl bg-white dark:bg-slate-800 border border-indigo-200 dark:border-indigo-800/80 shadow-inner space-y-2 text-[11px]">
                    <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-700 pb-1.5 text-slate-500 dark:text-slate-400">
                      <span>Vista Previa del Correo Electrónico Corporativo</span>
                      <button
                        type="button"
                        onClick={handleCopyEmailText}
                        className="text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-1 font-semibold"
                      >
                        {copiedPreview ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Eye className="w-3.5 h-3.5" />}
                        <span>{copiedPreview ? 'Copiado al portapapeles' : 'Copiar Texto'}</span>
                      </button>
                    </div>
                    <div className="space-y-1 text-slate-700 dark:text-slate-300 font-mono text-[11px]">
                      <div><strong>Para:</strong> {notificationEmail || '(Sin asignar)'}</div>
                      <div><strong>CC:</strong> {notificationCc || '(Ninguno)'}</div>
                      <div><strong>Asunto:</strong> {emailSubject}</div>
                    </div>
                    <div className="mt-2 p-2.5 rounded-lg bg-slate-50 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800 text-slate-800 dark:text-slate-200 whitespace-pre-wrap font-sans leading-relaxed">
                      {emailBody}
                    </div>
                  </div>
                )}

                {/* Audit Trail / Notification Logs */}
                {notificationLogs.length > 0 && (
                  <div className="pt-2 border-t border-indigo-100 dark:border-indigo-900/40">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block mb-1">
                      Bitácora de Avisos Disparados ({notificationLogs.length})
                    </span>
                    <div className="space-y-1 max-h-24 overflow-y-auto">
                      {notificationLogs.map((log) => (
                        <div
                          key={log.id}
                          className="flex items-center justify-between text-[11px] p-1.5 rounded-md bg-white dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300"
                        >
                          <div className="flex items-center gap-1.5 truncate">
                            <CheckCircle2 className="w-3 h-3 text-emerald-500 shrink-0" />
                            <span className="font-semibold text-slate-900 dark:text-white">Para: {log.to}</span>
                            <span className="text-slate-400 truncate">• {log.subject}</span>
                          </div>
                          <span className="text-[10px] text-slate-400 shrink-0 ml-2">{log.sentAt}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>

          {/* Footer Actions */}
          <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-slate-100 dark:border-slate-800">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 font-semibold"
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-semibold shadow-xs"
            >
              {initialTask ? 'Guardar Cambios' : 'Crear Actividad'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
