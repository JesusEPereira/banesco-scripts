export type Priority = 'Crítica' | 'Alta' | 'Media' | 'Baja';

export type TaskStatus = 'Pendiente' | 'En Proceso' | 'En Revisión' | 'Completado' | 'Bloqueado';

export type TaskType = 'Actividad' | 'Proyecto';

export type Domain = 
  | 'Windows'
  | 'IBMi'
  | 'Documentación'
  | 'PCI'
  | 'Auditoria Interna'
  | 'Auditoria Externa';

export interface Collaborator {
  id: string;
  name: string;
  initials: string;
  role: string;
  avatarColor: string;
  weeklyCapacityHours: number;
  email?: string;
}

export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
}

export interface EmailNotificationLog {
  id: string;
  sentAt: string;
  from?: string;
  to: string;
  cc?: string;
  subject: string;
  triggeredBy: string;
  messageSnippet?: string;
  status: 'sent' | 'scheduled';
  autoDispatched?: boolean;
}

export interface Task {
  id: string;
  code?: string; // e.g. ACT-104, PRJ-202
  type: TaskType;
  title: string;
  description: string;
  domain: Domain;
  collaboratorId: string;
  priority: Priority;
  status: TaskStatus;
  nextFollowUpDate: string; // YYYY-MM-DD
  creationDate: string; // YYYY-MM-DD
  lastModifiedBy: string; // Initials or name
  lastModifiedDate: string;
  hoursEstimated: number;
  hoursInvested: number;
  companyUnit?: string; // e.g. "BBU", "Banesco", "CSO"
  subtasks?: Subtask[];
  notes?: string;
  notifyOnOverdue?: boolean;
  notificationFrom?: string;
  notificationEmail?: string;
  notificationCc?: string;
  customNotificationMessage?: string;
  lastNotificationSentAt?: string;
  notificationLogs?: EmailNotificationLog[];
  // Campos para cálculo automático de jornada laboral (8h/día Lun-Vie)
  inProgressStartedAt?: string; // ISO timestamp de inicio en estado "En Proceso"
  accumulatedWorkHours?: number; // Horas laborales consolidadas de sesiones previas
}

export interface FilterState {
  searchQuery: string;
  collaboratorId: string;
  domain: string;
  priority: string;
  status: string;
  companyUnit: string;
  quickFilter: 'all' | 'overdue' | 'this_week' | 'critical';
  dateRangeStart: string;
  dateRangeEnd: string;
}

export interface KPIData {
  totalTasks: number;
  completedTasks: number;
  completedRate: number;
  delayedTasks: number;
  delayRate: number;
  inProgressTasks: number;
  totalHoursInvested: number;
  totalHoursEstimated: number;
  hoursUtilizationRate: number;
  averageHoursPerTask: number;
  overloadedMembersCount: number;
}
