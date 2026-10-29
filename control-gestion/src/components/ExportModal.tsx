import React, { useState } from 'react';
import { X, Download, Copy, Check, FileSpreadsheet, FileCode } from 'lucide-react';
import { Collaborator, Task } from '../types';

interface ExportModalProps {
  isOpen: boolean;
  onClose: () => void;
  tasks: Task[];
  collaborators: Collaborator[];
}

export const ExportModal: React.FC<ExportModalProps> = ({
  isOpen,
  onClose,
  tasks,
  collaborators,
}) => {
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const getCollabName = (id: string) => {
    const c = collaborators.find((col) => col.id === id);
    return c ? c.name : id;
  };

  const handleDownloadCSV = () => {
    const headers = [
      'Código',
      'Tipo',
      'Actividad / Requerimiento',
      'Dominio',
      'Colaborador',
      'Prioridad',
      'Estado',
      'Próximo Seguimiento',
      'Horas Estimadas',
      'Horas Invertidas',
      'Empresa / Unidad',
      'Última Modificación',
    ];

    const rows = tasks.map((t) => [
      `"${t.code || ''}"`,
      `"${t.type}"`,
      `"${t.title.replace(/"/g, '""')}"`,
      `"${t.domain}"`,
      `"${getCollabName(t.collaboratorId)}"`,
      `"${t.priority}"`,
      `"${t.status}"`,
      `"${t.nextFollowUpDate}"`,
      t.hoursEstimated,
      t.hoursInvested,
      `"${t.companyUnit || ''}"`,
      `"${t.lastModifiedDate} (${t.lastModifiedBy})"`,
    ]);

    const csvContent = '\uFEFF' + [headers.join(';'), ...rows.map((r) => r.join(';'))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `matriz_control_gestion_${new Date().toISOString().split('T')[0]}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const handleDownloadJSON = () => {
    const dataStr = JSON.stringify(tasks, null, 2);
    const blob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `control_gestion_backup_${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const handleCopyClipboard = () => {
    const textLines = [
      'Código\tActividad\tDominio\tResponsable\tPrioridad\tEstado\tPróx. Seguimiento\tHoras Inv/Est',
      ...tasks.map(
        (t) =>
          `${t.code || ''}\t${t.title}\t${t.domain}\t${getCollabName(t.collaboratorId)}\t${t.priority}\t${t.status}\t${t.nextFollowUpDate}\t${t.hoursInvested}h/${t.hoursEstimated}h`
      ),
    ].join('\n');

    navigator.clipboard.writeText(textLines);
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white dark:bg-slate-900 w-full max-w-md rounded-2xl border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden p-6 space-y-4 text-xs">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white">
              Exportar Datos de Rendimiento
            </h3>
            <p className="text-slate-500 dark:text-slate-400 text-[11px]">
              Descarga o copia las {tasks.length} actividades registradas
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="space-y-3 pt-2">
          {/* CSV Option */}
          <button
            onClick={handleDownloadCSV}
            className="w-full flex items-center justify-between p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-emerald-400 dark:hover:border-emerald-600 bg-slate-50 dark:bg-slate-800/60 hover:bg-emerald-50/40 dark:hover:bg-emerald-950/30 transition-all text-left group"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-emerald-100 dark:bg-emerald-950 text-emerald-600">
                <FileSpreadsheet className="w-5 h-5" />
              </div>
              <div>
                <div className="font-bold text-slate-900 dark:text-white">
                  Exportar a Excel / CSV
                </div>
                <div className="text-[11px] text-slate-500">
                  Delimitado por punto y coma con codificación UTF-8 BOM
                </div>
              </div>
            </div>
            <Download className="w-4 h-4 text-slate-400 group-hover:text-emerald-600" />
          </button>

          {/* JSON Option */}
          <button
            onClick={handleDownloadJSON}
            className="w-full flex items-center justify-between p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-indigo-400 dark:hover:border-indigo-600 bg-slate-50 dark:bg-slate-800/60 hover:bg-indigo-50/40 dark:hover:bg-indigo-950/30 transition-all text-left group"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-indigo-100 dark:bg-indigo-950 text-indigo-600">
                <FileCode className="w-5 h-5" />
              </div>
              <div>
                <div className="font-bold text-slate-900 dark:text-white">
                  Exportar Estructura JSON
                </div>
                <div className="text-[11px] text-slate-500">
                  Objeto completo con subtareas, horas y notas
                </div>
              </div>
            </div>
            <Download className="w-4 h-4 text-slate-400 group-hover:text-indigo-600" />
          </button>

          {/* Copy to Clipboard */}
          <button
            onClick={handleCopyClipboard}
            className="w-full flex items-center justify-between p-3.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-slate-400 bg-slate-50 dark:bg-slate-800/60 transition-all text-left"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300">
                {copied ? <Check className="w-5 h-5 text-emerald-600" /> : <Copy className="w-5 h-5" />}
              </div>
              <div>
                <div className="font-bold text-slate-900 dark:text-white">
                  {copied ? '¡Copiado al Portapapeles!' : 'Copiar Tabla (TSV)'}
                </div>
                <div className="text-[11px] text-slate-500">
                  Listo para pegar directamente en Google Sheets o Excel
                </div>
              </div>
            </div>
          </button>
        </div>

        <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-1.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 font-semibold"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
};
