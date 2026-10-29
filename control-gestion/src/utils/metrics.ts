import { Collaborator, FilterState, KPIData, Task } from '../types';

export function isTaskOverdue(task: Task, cutoffDateStr?: string): boolean {
  if (task.status === 'Completado') return false;
  if (!task.nextFollowUpDate) return false;
  
  const todayStr = new Date().toISOString().split('T')[0];
  // An overdue task has reached or exceeded its deadline relative to today or the operational cutoff date
  const effectiveCutoff = cutoffDateStr && cutoffDateStr > todayStr ? cutoffDateStr : todayStr;
  
  return task.nextFollowUpDate <= effectiveCutoff;
}

export function isTaskThisWeek(task: Task, cutoffDateStr?: string): boolean {
  if (!task.nextFollowUpDate) return false;
  const todayStr = new Date().toISOString().split('T')[0];
  const ref = cutoffDateStr || todayStr;
  const cutoff = new Date(ref);
  const taskDate = new Date(task.nextFollowUpDate);
  const diffTime = taskDate.getTime() - cutoff.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays >= -2 && diffDays <= 7;
}

export function filterTasks(tasks: Task[], filters: FilterState, cutoffDateStr?: string): Task[] {
  const todayStr = new Date().toISOString().split('T')[0];
  const effectiveCutoff = cutoffDateStr || todayStr;

  return tasks.filter((task) => {
    // Quick filter: overdue
    if (filters.quickFilter === 'overdue' && !isTaskOverdue(task, effectiveCutoff)) {
      return false;
    }
    // Quick filter: this week
    if (filters.quickFilter === 'this_week' && !isTaskThisWeek(task, effectiveCutoff)) {
      return false;
    }
    // Quick filter: critical
    if (filters.quickFilter === 'critical' && task.priority !== 'Crítica') {
      return false;
    }

    // Collaborator
    if (filters.collaboratorId && filters.collaboratorId !== 'all' && task.collaboratorId !== filters.collaboratorId) {
      return false;
    }

    // Domain
    if (filters.domain && filters.domain !== 'all' && task.domain !== filters.domain) {
      return false;
    }

    // Priority
    if (filters.priority && filters.priority !== 'all' && task.priority !== filters.priority) {
      return false;
    }

    // Status
    if (filters.status && filters.status !== 'all' && task.status !== filters.status) {
      return false;
    }

    // Company Unit
    if (filters.companyUnit && filters.companyUnit !== 'all' && task.companyUnit !== filters.companyUnit) {
      return false;
    }

    // Date range
    if (filters.dateRangeStart && task.nextFollowUpDate < filters.dateRangeStart) {
      return false;
    }
    if (filters.dateRangeEnd && task.nextFollowUpDate > filters.dateRangeEnd) {
      return false;
    }

    // Search query (title, description, code, collaborator name, companyUnit)
    if (filters.searchQuery.trim()) {
      const q = filters.searchQuery.toLowerCase().trim();
      const matchTitle = task.title.toLowerCase().includes(q);
      const matchDesc = task.description?.toLowerCase().includes(q) || false;
      const matchCode = task.code?.toLowerCase().includes(q) || false;
      const matchUnit = task.companyUnit?.toLowerCase().includes(q) || false;
      const matchDomain = task.domain.toLowerCase().includes(q);
      if (!matchTitle && !matchDesc && !matchCode && !matchUnit && !matchDomain) {
        return false;
      }
    }

    return true;
  });
}

export function computeKPIData(tasks: Task[], cutoffDateStr: string = '2026-09-09', collaborators: Collaborator[]): KPIData {
  const totalTasks = tasks.length;
  const completedTasks = tasks.filter((t) => t.status === 'Completado').length;
  const inProgressTasks = tasks.filter((t) => t.status === 'En Proceso').length;
  const delayedTasks = tasks.filter((t) => isTaskOverdue(t, cutoffDateStr)).length;

  const completedRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
  const activeTasks = totalTasks - completedTasks;
  const delayRate = activeTasks > 0 ? Math.round((delayedTasks / activeTasks) * 100) : 0;

  const totalHoursInvested = tasks.reduce((sum, t) => sum + (t.hoursInvested || 0), 0);
  const totalHoursEstimated = tasks.reduce((sum, t) => sum + (t.hoursEstimated || 0), 0);
  const hoursUtilizationRate = totalHoursEstimated > 0 ? Math.round((totalHoursInvested / totalHoursEstimated) * 100) : 0;
  const averageHoursPerTask = totalTasks > 0 ? Math.round((totalHoursInvested / totalTasks) * 10) / 10 : 0;

  // Overloaded members
  const workloadByCollab = computeCollaboratorWorkload(tasks, collaborators);
  const overloadedMembersCount = workloadByCollab.filter((c) => c.utilizationPct > 100).length;

  return {
    totalTasks,
    completedTasks,
    completedRate,
    delayedTasks,
    delayRate,
    inProgressTasks,
    totalHoursInvested,
    totalHoursEstimated,
    hoursUtilizationRate,
    averageHoursPerTask,
    overloadedMembersCount,
  };
}

export interface CollaboratorWorkload {
  collaborator: Collaborator;
  totalTasks: number;
  completedTasks: number;
  activeTasks: number;
  delayedTasks: number;
  criticalTasks: number;
  hoursInvested: number;
  hoursEstimated: number;
  utilizationPct: number; // relative to monthly/assigned capacity
  statusLevel: 'normal' | 'optimal' | 'overloaded';
}

export function computeCollaboratorWorkload(tasks: Task[], collaborators: Collaborator[], cutoffDateStr: string = '2026-09-09'): CollaboratorWorkload[] {
  return collaborators.map((c) => {
    const memberTasks = tasks.filter((t) => t.collaboratorId === c.id);
    const completedTasks = memberTasks.filter((t) => t.status === 'Completado').length;
    const activeTasks = memberTasks.length - completedTasks;
    const delayedTasks = memberTasks.filter((t) => isTaskOverdue(t, cutoffDateStr)).length;
    const criticalTasks = memberTasks.filter((t) => t.priority === 'Crítica' && t.status !== 'Completado').length;
    
    const hoursInvested = memberTasks.reduce((sum, t) => sum + (t.hoursInvested || 0), 0);
    const hoursEstimated = memberTasks.reduce((sum, t) => sum + (t.hoursEstimated || 0), 0);
    
    // Capacity baseline: 40h per week or ~80h for the active two-week sprint
    const sprintCapacity = c.weeklyCapacityHours * 2; 
    const utilizationPct = Math.round((hoursInvested / sprintCapacity) * 100);

    let statusLevel: 'normal' | 'optimal' | 'overloaded' = 'normal';
    if (utilizationPct > 100) statusLevel = 'overloaded';
    else if (utilizationPct >= 75) statusLevel = 'optimal';

    return {
      collaborator: c,
      totalTasks: memberTasks.length,
      completedTasks,
      activeTasks,
      delayedTasks,
      criticalTasks,
      hoursInvested,
      hoursEstimated,
      utilizationPct,
      statusLevel,
    };
  });
}
