/**
 * Automated SLA Overdue Email Notification Engine
 * Control de Gestión - Gcia Administración Seguridad
 * 
 * Reglas de negocio solicitadas:
 * 1. Buzón emisor oficial de envío (De): administracion_de_informacion_ve@banesco.com
 * 2. Con Copia (CC) obligatoria siempre: aguevara@banesco.com
 * 3. Envío automático / Despacho basado en la fecha de "Próx. Seguimiento".
 * 4. Integración para Outlook Web (Office 365 Banesco) y Outlook de escritorio local.
 */

import { Collaborator, EmailNotificationLog, Task } from '../types';

export const CORPORATE_SENDER_MAILBOX = 'administracion_de_informacion_ve@banesco.com';
export const CORPORATE_MANDATORY_CC = 'aguevara@banesco.com';

export interface EmailNoticePayload {
  from: string;
  to: string;
  cc: string;
  subject: string;
  body: string;
  mailtoUrl: string;
  gmailWebUrl: string;
  outlookWebUrl: string; // compatibility alias
}

/**
 * Genera el enlace directo a Gmail en Google Workspace con buzón corporativo
 */
export function buildGmailComposeUrl(
  to: string,
  cc: string,
  subject: string,
  body: string,
  fromMailbox: string = CORPORATE_SENDER_MAILBOX
): string {
  const params = new URLSearchParams({
    view: 'cm',
    fs: '1',
    tf: '1',
    to,
    cc,
    su: subject,
    body,
    authuser: fromMailbox,
  });
  return `https://mail.google.com/mail/?${params.toString()}`;
}

/**
 * Obtiene el correo del colaborador
 */
export function getCollaboratorEmailAddress(collaborator?: Collaborator): string {
  if (!collaborator) return '';
  if (collaborator.email) return collaborator.email;
  const clean = collaborator.name.toLowerCase().replace(/\s+/g, '.');
  return `${clean}@banesco.com`;
}

/**
 * Genera el asunto, cuerpo y enlaces de apertura en Outlook / mailto
 */
export function generateOverdueEmail(
  task: Task,
  collaborator?: Collaborator,
  currentInitials: string = 'JP'
): EmailNoticePayload {
  const collabName = collaborator?.name || 'Colaborador';
  const targetEmail = task.notificationEmail?.trim() || getCollaboratorEmailAddress(collaborator);
  // Regla estricta: siempre aguevara@banesco.com
  const targetCc = CORPORATE_MANDATORY_CC;
  const fromMailbox = CORPORATE_SENDER_MAILBOX;
  const taskCode = task.code || `ACT-${task.id.slice(-4)}`;

  const subject = `[AVISO VENCIMIENTO SLA] ${task.type}: ${task.title || 'Actividad Sin Título'} - SLA: ${task.nextFollowUpDate}`;

  const diaEnvio = new Date().toLocaleDateString('es-ES');

  const body = `Estimado(a) ${collabName},

Se le notifica formalmente que la siguiente asignación bajo su responsabilidad en la Gerencia de Administración de Seguridad ha alcanzado o superado su fecha de seguimiento / vencimiento de SLA:

==================================================
DETALLES DE LA ACTIVIDAD:
• Requerimiento: ${task.title}
• Tipo: ${task.type}
• Dominio: ${task.domain}
• Prioridad: ${task.priority}
• Estado Actual: ${task.status}
• Fecha Próx. Seguimiento (SLA): ${task.nextFollowUpDate}
• Horas Invertidas (8h lun-vie): ${task.hoursInvested}h / ${task.hoursEstimated}h est.
• Empresa / Unidad: ${task.companyUnit || 'Banesco'}
==================================================

${task.customNotificationMessage ? `INSTRUCCIÓN DEL LÍDER / CONTROL DE GESTIÓN:\n"${task.customNotificationMessage}"\n\n` : ''}ACCIÓN REQUERIDA:
Por favor ingresar al Dashboard de Control de Gestión para actualizar el estatus de la asignación y reportar causas de desviación.

Atentamente,
Control de Gestión - Gcia Administración Seguridad
Buzón Emisor Oficial: administracion_de_informacion_ve@banesco.com
Supervisión CC Permanente: aguevara@banesco.com
Fecha de Emisión: ${diaEnvio}`;

  // Enlace para cliente local (mailto)
  const mailtoUrl = `mailto:${encodeURIComponent(targetEmail)}?cc=${encodeURIComponent(targetCc)}&subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

  // Enlace directo oficial para Gmail en Google Workspace con buzón corporativo
  const gmailWebUrl = buildGmailComposeUrl(targetEmail, targetCc, subject, body, fromMailbox);
  const outlookWebUrl = gmailWebUrl; // Compatible con llamadas previas

  return {
    from: fromMailbox,
    to: targetEmail,
    cc: targetCc,
    subject,
    body,
    mailtoUrl,
    gmailWebUrl,
    outlookWebUrl,
  };
}

/**
 * Valida si una tarea es candidata para el disparo automático de correo por vencimiento
 */
export function isTaskEligibleForAutoNotification(
  task: Task,
  referenceDateStr: string,
  todayStr: string = new Date().toISOString().split('T')[0]
): boolean {
  // Solo tareas activas (no completadas)
  if (task.status === 'Completado') return false;

  // Notificaciones deshabilitadas explícitamente por el usuario
  if (task.notifyOnOverdue === false) return false;

  // Fecha de próximo seguimiento obligatoria
  if (!task.nextFollowUpDate) return false;

  // Se activa si la fecha de Próx. Seguimiento ya llegó o venció
  const isDue = task.nextFollowUpDate <= referenceDateStr || task.nextFollowUpDate <= todayStr;
  if (!isDue) return false;

  // Control anti-spam: Si ya se emitió una notificación hoy, no volver a disparar
  if (task.lastNotificationSentAt && task.lastNotificationSentAt.includes(todayStr)) {
    return false;
  }

  return true;
}

export interface AutoNotificationResult {
  task: Task;
  log: EmailNotificationLog;
  payload: EmailNoticePayload;
}

/**
 * Motor de procesamiento automático de avisos de vencimiento por Próx. Seguimiento
 */
export function runAutomatedSlaNotificationCheck(
  tasks: Task[],
  referenceDateStr: string,
  collaborators: Collaborator[],
  currentInitials: string = 'JP'
): { updatedTasks: Task[]; newlyNotified: AutoNotificationResult[] } {
  const todayStr = new Date().toISOString().split('T')[0];
  const nowFormatted = new Date().toLocaleString('es-ES', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });

  const newlyNotified: AutoNotificationResult[] = [];

  const updatedTasks = tasks.map((task) => {
    if (!isTaskEligibleForAutoNotification(task, referenceDateStr, todayStr)) {
      return task;
    }

    const collaborator = collaborators.find((c) => c.id === task.collaboratorId);
    const payload = generateOverdueEmail(task, collaborator, currentInitials);

    const log: EmailNotificationLog = {
      id: `auto-log-${task.id}-${Date.now()}`,
      sentAt: `${todayStr} ${nowFormatted}`,
      from: CORPORATE_SENDER_MAILBOX,
      to: payload.to,
      cc: CORPORATE_MANDATORY_CC,
      subject: payload.subject,
      triggeredBy: 'Sistema Automático SLA (Próx. Seguimiento)',
      messageSnippet: `Aviso oficial preparado desde ${CORPORATE_SENDER_MAILBOX} con copia obligatoria a ${CORPORATE_MANDATORY_CC}`,
      status: 'scheduled',
      autoDispatched: true,
    };

    const updatedTask: Task = {
      ...task,
      notificationFrom: CORPORATE_SENDER_MAILBOX,
      notificationCc: CORPORATE_MANDATORY_CC,
      lastNotificationSentAt: `${todayStr} ${nowFormatted}`,
      notificationLogs: [log, ...(task.notificationLogs || [])],
    };

    newlyNotified.push({
      task: updatedTask,
      log,
      payload,
    });

    return updatedTask;
  });

  return { updatedTasks, newlyNotified };
}

/**
 * Abre la redacción directa en Gmail de Google Workspace (Banesco) con el buzón corporativo
 */
export function openGmailWeb(gmailWebUrl: string): void {
  try {
    const link = document.createElement('a');
    link.href = gmailWebUrl;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } catch (err) {
    console.error('Error al abrir Gmail Web:', err);
  }
}

/**
 * Alias de compatibilidad
 */
export const openOutlookWeb = openGmailWeb;

/**
 * Despacha petición al cliente de correo local (Outlook de escritorio)
 */
export function openMailClient(mailtoUrl: string): void {
  try {
    const link = document.createElement('a');
    link.href = mailtoUrl;
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } catch (err) {
    console.error('Error al abrir cliente de correo local:', err);
  }
}
