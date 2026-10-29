import React, { useState } from 'react';
import { 
  X, 
  Mail, 
  ExternalLink, 
  Send, 
  Copy, 
  Check, 
  ShieldCheck, 
  UserCheck, 
  AlertCircle,
  Building2,
  Calendar,
  Clock
} from 'lucide-react';
import { Collaborator, Task } from '../types';
import { 
  CORPORATE_SENDER_MAILBOX, 
  CORPORATE_MANDATORY_CC, 
  generateOverdueEmail,
  openGmailWeb,
  openMailClient
} from '../utils/automatedEmailNotifier';

interface EmailDispatchModalProps {
  isOpen: boolean;
  onClose: () => void;
  task: Task | null;
  collaborators: Collaborator[];
  currentInitials?: string;
  onMarkAsDispatched?: (taskId: string) => void;
}

export const EmailDispatchModal: React.FC<EmailDispatchModalProps> = ({
  isOpen,
  onClose,
  task,
  collaborators,
  currentInitials = 'JP',
  onMarkAsDispatched,
}) => {
  const [copied, setCopied] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  if (!isOpen || !task) return null;

  const collaborator = collaborators.find((c) => c.id === task.collaboratorId);
  const emailPayload = generateOverdueEmail(task, collaborator, currentInitials);

  const handleCopyEmail = () => {
    const fullText = `De: ${emailPayload.from}\nPara: ${emailPayload.to}\nCC: ${emailPayload.cc}\nAsunto: ${emailPayload.subject}\n\n${emailPayload.body}`;
    navigator.clipboard.writeText(fullText);
    setCopied(true);
    setStatusMessage('✅ Formato de correo copiado al portapapeles.');
    setTimeout(() => {
      setCopied(false);
      setStatusMessage(null);
    }, 3000);
  };

  const handleDispatchGmailWeb = () => {
    openGmailWeb(emailPayload.gmailWebUrl);
    if (onMarkAsDispatched) {
      onMarkAsDispatched(task.id);
    }
    setStatusMessage(`🚀 Ventana de redacción en Gmail abierta con remitente: ${CORPORATE_SENDER_MAILBOX}.`);
    setTimeout(() => setStatusMessage(null), 4000);
  };

  const handleDispatchLocalMail = () => {
    openMailClient(emailPayload.mailtoUrl);
    if (onMarkAsDispatched) {
      onMarkAsDispatched(task.id);
    }
    setStatusMessage('✉️ Redacción en cliente de correo local abierta.');
    setTimeout(() => setStatusMessage(null), 4000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto animate-in fade-in">
      <div className="bg-white dark:bg-slate-900 w-full max-w-2xl rounded-2xl border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden my-6">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 bg-slate-50/70 dark:bg-slate-800/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-600/10 dark:bg-blue-500/20 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Mail className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <span>Despacho Oficial de Correo por Vencimiento SLA</span>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-blue-100 text-blue-700 dark:bg-blue-950/80 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                  BANESCO
                </span>
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Aviso automático generado por vencimiento de Próx. Seguimiento ({task.nextFollowUpDate})
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

        {/* Content */}
        <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-xs">
          
          {/* Status Alert if triggered */}
          {statusMessage && (
            <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-300 font-semibold text-xs flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              <span>{statusMessage}</span>
            </div>
          )}

          {/* Delivery Clarification Callout */}
          <div className="p-3.5 rounded-xl bg-amber-50/90 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-900/60 text-amber-900 dark:text-amber-200 space-y-1">
            <div className="flex items-center gap-2 font-bold text-xs">
              <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />
              <span>Garantía de Recepción en Bandeja de Entrada:</span>
            </div>
            <p className="text-[11px] leading-relaxed">
              Para que el correo ingrese de forma efectiva en tu bandeja y en la del colaborador, haz clic en <strong>"Despachar en Gmail"</strong>. Esto abrirá la redacción oficial en Gmail con el buzón emisor <strong>{CORPORATE_SENDER_MAILBOX}</strong> y con copia fija a <strong>{CORPORATE_MANDATORY_CC}</strong> listo para presionar Enviar.
            </p>
          </div>

          {/* Email Headers Form */}
          <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800/50 border border-slate-200 dark:border-slate-700/80 space-y-3">
            {/* Buzón Emisor (De) */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 pb-2 border-b border-slate-200 dark:border-slate-700/60">
              <span className="font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <Building2 className="w-3.5 h-3.5 text-indigo-600" /> Buzón Emisor (De):
              </span>
              <span className="font-mono font-bold text-indigo-700 dark:text-indigo-300 bg-indigo-50 dark:bg-indigo-950/60 px-2 py-0.5 rounded-md border border-indigo-200 dark:border-indigo-800">
                {CORPORATE_SENDER_MAILBOX}
              </span>
            </div>

            {/* Con Copia (CC) */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 pb-2 border-b border-slate-200 dark:border-slate-700/60">
              <span className="font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <UserCheck className="w-3.5 h-3.5 text-indigo-600" /> Con Copia Fija (CC):
              </span>
              <span className="font-mono font-bold text-indigo-700 dark:text-indigo-300 bg-indigo-50 dark:bg-indigo-950/60 px-2 py-0.5 rounded-md border border-indigo-200 dark:border-indigo-800">
                {CORPORATE_MANDATORY_CC}
              </span>
            </div>

            {/* Para (To) */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 pb-2 border-b border-slate-200 dark:border-slate-700/60">
              <span className="font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-indigo-600" /> Destinatario (Para):
              </span>
              <span className="font-semibold text-slate-800 dark:text-slate-200">
                {collaborator?.name || 'Colaborador'} ({emailPayload.to})
              </span>
            </div>

            {/* Asunto */}
            <div className="space-y-1">
              <span className="font-bold text-slate-700 dark:text-slate-300">
                Asunto:
              </span>
              <div className="font-medium text-slate-900 dark:text-white bg-white dark:bg-slate-900 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700">
                {emailPayload.subject}
              </div>
            </div>
          </div>

          {/* Body Preview */}
          <div>
            <div className="flex items-center justify-between mb-1.5">
              <span className="font-bold text-slate-700 dark:text-slate-300">
                Cuerpo del Correo Formal (Horas laborales 8h lun-vie):
              </span>
              <button
                type="button"
                onClick={handleCopyEmail}
                className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 hover:underline flex items-center gap-1 cursor-pointer"
              >
                {copied ? <Check className="w-3 h-3 text-emerald-500" /> : <Copy className="w-3 h-3" />}
                <span>{copied ? '¡Copiado!' : 'Copiar Texto Completo'}</span>
              </button>
            </div>
            <textarea
              readOnly
              rows={9}
              value={emailPayload.body}
              className="w-full px-3 py-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/80 border border-slate-200 dark:border-slate-700 font-mono text-[11px] text-slate-700 dark:text-slate-300 leading-relaxed resize-none focus:outline-none"
            />
          </div>

        </div>

        {/* Action Footer */}
        <div className="flex flex-wrap items-center justify-between gap-3 px-6 py-4 border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/30">
          <button
            type="button"
            onClick={handleCopyEmail}
            className="px-3 py-2 rounded-xl bg-slate-200 hover:bg-slate-300 dark:bg-slate-700 dark:hover:bg-slate-600 text-slate-700 dark:text-slate-200 font-bold text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
            <span>Copiar Correo</span>
          </button>

          <div className="flex items-center gap-2 ml-auto">
            {/* Direct Gmail Web anchor button */}
            <a
              href={emailPayload.gmailWebUrl}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => {
                if (onMarkAsDispatched) onMarkAsDispatched(task.id);
              }}
              className="px-4 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white font-bold text-xs flex items-center gap-2 shadow-xs transition-colors cursor-pointer"
              title={`Despachar en Gmail con buzón ${CORPORATE_SENDER_MAILBOX}`}
            >
              <ExternalLink className="w-3.5 h-3.5" />
              <span>Despachar en Gmail ({CORPORATE_SENDER_MAILBOX})</span>
            </a>

            {/* Direct Desktop Client anchor button */}
            <a
              href={emailPayload.mailtoUrl}
              target="_blank"
              rel="noopener noreferrer"
              onClick={() => {
                if (onMarkAsDispatched) onMarkAsDispatched(task.id);
              }}
              className="px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <Send className="w-3.5 h-3.5" />
              <span>Cliente Local</span>
            </a>
          </div>
        </div>
      </div>
    </div>
  );
};
